#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Installs the WindowsTerminalSkill PowerShell module to the local copilot skills directory
.DESCRIPTION
    This script copies the WindowsTerminalSkill module files to the user's copilot skills directory
    and optionally updates the PowerShell profile to import the module automatically
.PARAMETER UpdateProfile
    If specified, updates the PowerShell profile to automatically import the module
.EXAMPLE
    .\install.ps1
    .\install.ps1 -UpdateProfile
#>

param(
    [switch]$UpdateProfile
)

# Set error action preference
$ErrorActionPreference = 'Stop'

# Define paths
$ScriptDir = $PSScriptRoot
$TargetDir = "$env:USERPROFILE\.copilot\skills\windows-terminal-copilot-skill"
$ModuleFiles = @(
    'WindowsTerminalSkill.psm1',
    'WindowsTerminalSkill.psd1'
)
$ProfilePath = "$env:USERPROFILE\OneDrive - Microsoft\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
$ImportStatement = 'Import-module "$env:USERPROFILE\.copilot\skills\windows-terminal-copilot-skill\WindowsTerminalSkill.psd1"'

Write-Host "=== WindowsTerminalSkill Module Installer ===" -ForegroundColor Cyan
Write-Host "Source: $ScriptDir" -ForegroundColor Gray
Write-Host "Target: $TargetDir" -ForegroundColor Gray
Write-Host

# Check if source files exist
foreach ($file in $ModuleFiles) {
    $sourcePath = Join-Path $ScriptDir $file
    if (-not (Test-Path $sourcePath)) {
        Write-Error "Source file not found: $sourcePath"
        exit 1
    }
}

# Check if target directory exists and handle existing installation
if (Test-Path $TargetDir) {
    Write-Host "Removing existing installation..." -ForegroundColor Yellow
    Remove-Item $TargetDir -Recurse -Force
}

# Create target directory
Write-Host "Creating target directory..." -ForegroundColor Green
New-Item -Path $TargetDir -ItemType Directory -Force | Out-Null

# Copy module files
Write-Host "Copying module files..." -ForegroundColor Green
foreach ($file in $ModuleFiles) {
    $sourcePath = Join-Path $ScriptDir $file
    $targetPath = Join-Path $TargetDir $file
    Copy-Item $sourcePath $targetPath
    Write-Host "  Copied: $file" -ForegroundColor Gray
}

# Copy additional files if they exist
$OptionalFiles = @('README.md', 'SKILL.md')
foreach ($file in $OptionalFiles) {
    $sourcePath = Join-Path $ScriptDir $file
    if (Test-Path $sourcePath) {
        $targetPath = Join-Path $TargetDir $file
        Copy-Item $sourcePath $targetPath
        Write-Host "  Copied: $file" -ForegroundColor Gray
    }
}

Write-Host "Module files installed successfully!" -ForegroundColor Green

# Handle PowerShell profile update
if ($UpdateProfile) {
    Write-Host
    Write-Host "Updating PowerShell profile..." -ForegroundColor Green
    
    # Check if profile exists
    if (-not (Test-Path $ProfilePath)) {
        Write-Host "Creating PowerShell profile at: $ProfilePath" -ForegroundColor Yellow
        $ProfileDir = Split-Path $ProfilePath -Parent
        if (-not (Test-Path $ProfileDir)) {
            New-Item -Path $ProfileDir -ItemType Directory -Force | Out-Null
        }
        New-Item -Path $ProfilePath -ItemType File -Force | Out-Null
    }
    
    # Check if import statement already exists
    $profileContent = Get-Content $ProfilePath -ErrorAction SilentlyContinue
    if ($profileContent -match [regex]::Escape($ImportStatement)) {
        Write-Host "  Module import already exists in profile" -ForegroundColor Gray
    } else {
        # Add import statement
        Add-Content -Path $ProfilePath -Value $ImportStatement
        Write-Host "  Added module import to profile" -ForegroundColor Gray
    }
}

# Test installation
Write-Host
Write-Host "Testing installation..." -ForegroundColor Green
try {
    Import-Module "$TargetDir\WindowsTerminalSkill.psd1" -Force
    
    # Test basic functionality
    if (Get-Command tab -ErrorAction SilentlyContinue) {
        Write-Host "  Module loaded successfully!" -ForegroundColor Green
        Write-Host "  Available commands: tab, Reset-TabTitle, Get-TabInfo" -ForegroundColor Gray
    } else {
        Write-Warning "Module loaded but 'tab' command not available"
    }
} catch {
    Write-Error "Failed to load module: $_"
    exit 1
}

Write-Host
Write-Host "=== Installation Complete ===" -ForegroundColor Cyan
Write-Host "The WindowsTerminalSkill module has been installed successfully!" -ForegroundColor Green

if ($UpdateProfile) {
    Write-Host "Restart PowerShell or run 'Import-Module WindowsTerminalSkill.psd1' to use the module." -ForegroundColor Yellow
} else {
    Write-Host "To use the module, run:" -ForegroundColor Yellow
    Write-Host "  Import-Module `"$TargetDir\WindowsTerminalSkill.psd1`"" -ForegroundColor White
    Write-Host
    Write-Host "To auto-load on startup, add this to your PowerShell profile:" -ForegroundColor Yellow
    Write-Host "  $ImportStatement" -ForegroundColor White
}

Write-Host
Write-Host "Usage examples:" -ForegroundColor Yellow
Write-Host "  tab `"Working on Feature`"     # Set custom title" -ForegroundColor White
Write-Host "  tab `"Bug Fix`" red           # Set title with color" -ForegroundColor White
Write-Host "  tab --reset                  # Reset to spawn title" -ForegroundColor White
Write-Host "  Get-TabInfo                  # Show tab information" -ForegroundColor White