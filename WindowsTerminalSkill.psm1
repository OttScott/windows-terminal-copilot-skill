# WindowsTerminalSkill - Control terminal tab title/color from child processes

$script:Colors = @{
    red = "E74C3C"; green = "2ECC71"; blue = "3498DB"; purple = "9B59B6"
    orange = "E67E22"; yellow = "F1C40F"; pink = "E91E63"; cyan = "00BCD4"
    bug = "E74C3C"; feature = "2ECC71"; research = "3498DB"; refactor = "9B59B6"
    devops = "E67E22"; test = "F1C40F";default = "20206D"
}

# Store the original spawn title when module is loaded
$script:OriginalSpawnTitle = $null

function Get-SpawnTitle {
    if (-not $script:OriginalSpawnTitle) {
        # Try to get the profile name from Windows Terminal settings
        $profileName = Get-WindowsTerminalProfileName
        if ($profileName) {
            $script:OriginalSpawnTitle = $profileName
        } else {
            # Fallback to current window title (likely the executable path)
            $script:OriginalSpawnTitle = $Host.UI.RawUI.WindowTitle
        }
    }
    return $script:OriginalSpawnTitle
}

function Get-WindowsTerminalProfileName {
    try {
        if ($env:WT_PROFILE_ID) {
            $settingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
            if (Test-Path $settingsPath) {
                $settings = Get-Content $settingsPath | ConvertFrom-Json
                $profile = $settings.profiles.list | Where-Object { $_.guid -eq $env:WT_PROFILE_ID }
                if ($profile -and $profile.name) {
                    return $profile.name
                }
            }
        }
    } catch {
        # Silently continue if we can't read settings
    }
    return $null
}

function Set-TerminalDirect {
    param(
        [Parameter(Mandatory)][string]$Title,
        [string]$Color = "6C3BAA"
    )
    $Color = $Color -replace '^#', ''
    if ($script:Colors.ContainsKey($Color.ToLower())) {
        $Color = $script:Colors[$Color.ToLower()]
    }
    $r = $Color.Substring(0,2); $g = $Color.Substring(2,2); $b = $Color.Substring(4,2)
    $Host.UI.RawUI.WindowTitle = $Title
    Write-Host ([char]27 + "]4;264;rgb:$r/$g/$b" + [char]7) -NoNewline
}

function Set-Tab {
    param([Parameter(Mandatory)][string]$TitleAndColor)
    if ($TitleAndColor -match '^(.+)\|(\w+)$') {
        Set-TerminalDirect -Title $Matches[1] -Color $Matches[2]
    } else {
        Set-TerminalDirect -Title $TitleAndColor
    }
}

function tab {
    param(
        [Parameter(Position=0)][string]$Title,
        [Parameter(Position=1)][string]$Color = "default"
    )
    if ($Title -eq "--reset") {
        # Reset to spawn title
        $spawnTitle = Get-SpawnTitle
        Set-TerminalDirect -Title $spawnTitle -Color $Color
        Write-Host ""  # newline after the escape sequence
        Write-Host "Tab reset to spawn title: $spawnTitle" -ForegroundColor DarkGray
    } elseif ($Title) {
        # Set the specified title
        Set-TerminalDirect -Title $Title -Color $Color
        Write-Host ""  # newline after the escape sequence
        Write-Host "Tab: $Title" -ForegroundColor DarkGray
    } else {
        # Show usage when no title provided
        Write-Host "Usage: tab <title> [color]" -ForegroundColor Yellow
        Write-Host "       tab --reset [color]" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Examples:" -ForegroundColor Cyan
        Write-Host "  tab 'My Project'" -ForegroundColor Gray
        Write-Host "  tab 'Build Process' red" -ForegroundColor Gray
        Write-Host "  tab --reset" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Available colors: $($script:Colors.Keys -join ', ')" -ForegroundColor DarkGray
    }
}

function Reset-TabTitle {
    <#
    .SYNOPSIS
        Resets the terminal tab title to the original spawn title
    .DESCRIPTION
        Sets the tab title back to what it was when the Windows Terminal tab was first created (profile name or executable)
    .PARAMETER Color
        Optional color for the tab (defaults to "default")
    #>
    param([string]$Color = "default")
    
    $spawnTitle = Get-SpawnTitle
    Set-TerminalDirect -Title $spawnTitle -Color $Color
    Write-Host ""  # newline after the escape sequence
    Write-Host "Tab title reset to spawn title: $spawnTitle" -ForegroundColor Green
}

function Get-TabInfo {
    <#
    .SYNOPSIS
        Gets information about the current terminal tab
    .DESCRIPTION
        Returns current title, original spawn title, and Windows Terminal session information
    #>
    $info = @{
        CurrentTitle = $Host.UI.RawUI.WindowTitle
        SpawnTitle = Get-SpawnTitle
        ProfileId = $env:WT_PROFILE_ID
        SessionId = $env:WT_SESSION
        ProfileName = Get-WindowsTerminalProfileName
    }
    
    Write-Host "Terminal Tab Information:" -ForegroundColor Cyan
    Write-Host "  Current Title: $($info.CurrentTitle)" -ForegroundColor White
    Write-Host "  Spawn Title: $($info.SpawnTitle)" -ForegroundColor Yellow
    Write-Host "  Profile Name: $($info.ProfileName)" -ForegroundColor Magenta
    Write-Host "  Profile ID: $($info.ProfileId)" -ForegroundColor Gray
    Write-Host "  Session ID: $($info.SessionId)" -ForegroundColor Gray
    
    return $info
}

function Start-TerminalListener { }

# Initialize the spawn title when module loads
$script:OriginalSpawnTitle = Get-SpawnTitle

Export-ModuleMember -Function Set-TerminalDirect, Set-Tab, Start-TerminalListener, tab, Reset-TabTitle, Get-TabInfo
