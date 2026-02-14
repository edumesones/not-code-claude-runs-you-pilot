###############################################################################
# Feature Development Methodology - Smart Installer (PowerShell)
# Supports both global and project-level installation with intelligent merge
###############################################################################

#Requires -Version 5.1

$ErrorActionPreference = "Stop"

Write-Host @"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║               FEATURE DEVELOPMENT METHODOLOGY                         ║
║            Smart Installer for Claude Code                   ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

Write-Host ""
Write-Host "This installer supports:" -ForegroundColor Blue
Write-Host "  • Global installation - Available in ALL projects" -ForegroundColor Green
Write-Host "  • Project-level installation - Only in current project" -ForegroundColor Green
Write-Host "  • Intelligent merge - Preserves existing configuration" -ForegroundColor Green
Write-Host ""

# Function to ask yes/no
function Ask-YesNo {
    param(
        [string]$Prompt,
        [string]$Default = "N"
    )

    $choices = if ($Default -eq "Y") { "[Y/n]" } else { "[y/N]" }
    $response = Read-Host "$Prompt $choices"

    if ([string]::IsNullOrWhiteSpace($response)) {
        $response = $Default
    }

    return $response -match '^[Yy]$'
}

# Function to merge file
function Merge-File {
    param(
        [string]$Source,
        [string]$Destination
    )

    $name = Split-Path $Destination -Leaf

    if (Test-Path $Destination) {
        Write-Host "  ⚠ $name already exists" -ForegroundColor Yellow
        Write-Host "    Current: $Destination" -ForegroundColor Blue

        if (Ask-YesNo "    Replace with Feature Development Methodology version?" "N") {
            Copy-Item $Source $Destination -Force
            Write-Host "    ✓ Replaced" -ForegroundColor Green
        } else {
            $backup = "$Destination.backup"
            Copy-Item $Source $backup -Force
            Write-Host "    ✓ Feature Development Methodology version saved as: $(Split-Path $backup -Leaf)" -ForegroundColor Green
            Write-Host "    ℹ You can manually merge later" -ForegroundColor Yellow
        }
    } else {
        Copy-Item $Source $Destination -Force
        Write-Host "  ✓ Installed $name" -ForegroundColor Green
    }
}

# Function to merge directory
function Merge-Directory {
    param(
        [string]$SourceDir,
        [string]$DestDir,
        [string]$Label
    )

    New-Item -ItemType Directory -Path $DestDir -Force | Out-Null

    $fileCount = 0
    $newCount = 0
    $skipCount = 0

    Get-ChildItem -Path $SourceDir -File | ForEach-Object {
        $fileCount++
        $destFile = Join-Path $DestDir $_.Name

        if (Test-Path $destFile) {
            # Check if different
            $sourceHash = (Get-FileHash $_.FullName).Hash
            $destHash = (Get-FileHash $destFile).Hash

            if ($sourceHash -ne $destHash) {
                Write-Host "  ⚠ $Label/$($_.Name) already exists and is different" -ForegroundColor Yellow

                if (Ask-YesNo "    Replace with Feature Development Methodology version?" "N") {
                    Copy-Item $_.FullName $destFile -Force
                    Write-Host "    ✓ Replaced" -ForegroundColor Green
                    $newCount++
                } else {
                    Copy-Item $_.FullName "$destFile.backup" -Force
                    Write-Host "    ✓ Saved as $($_.Name).backup" -ForegroundColor Green
                    $skipCount++
                }
            } else {
                Write-Host "  ℹ $Label/$($_.Name) (identical, skipped)" -ForegroundColor Blue
                $skipCount++
            }
        } else {
            Copy-Item $_.FullName $destFile -Force
            Write-Host "  ✓ Added $Label/$($_.Name)" -ForegroundColor Green
            $newCount++
        }
    }

    Write-Host "  Summary: $newCount added, $skipCount skipped" -ForegroundColor Cyan
}

# Check prerequisites
Write-Host "[1/7] Checking prerequisites..." -ForegroundColor Yellow

$hasGit = Get-Command git -ErrorAction SilentlyContinue
$hasGh = Get-Command gh -ErrorAction SilentlyContinue
$hasClaude = Get-Command claude -ErrorAction SilentlyContinue
$hasNode = Get-Command node -ErrorAction SilentlyContinue

if (-not $hasGit) {
    Write-Host "❌ Git required" -ForegroundColor Red
    exit 1
}
Write-Host "  ✓ Git" -ForegroundColor Green

if ($hasGh) {
    Write-Host "  ✓ GitHub CLI" -ForegroundColor Green
} else {
    Write-Host "  ⚠ GitHub CLI (optional)" -ForegroundColor Yellow
}

if ($hasClaude) {
    Write-Host "  ✓ Claude CLI" -ForegroundColor Green
} else {
    Write-Host "  ⚠ Claude CLI (recommended)" -ForegroundColor Yellow
}

if ($hasNode) {
    Write-Host "  ✓ Node.js" -ForegroundColor Green
} else {
    Write-Host "  ⚠ Node.js (for Memory-MCP)" -ForegroundColor Yellow
}

# Ask installation type
Write-Host ""
Write-Host "[2/7] Choose installation type" -ForegroundColor Yellow
Write-Host ""
Write-Host "1) Global Installation" -ForegroundColor Magenta
Write-Host "   • Installs to ~/.claude/" -ForegroundColor White
Write-Host "   • Available in ALL projects" -ForegroundColor Green
Write-Host ""
Write-Host "2) Project-Level Installation" -ForegroundColor Magenta
Write-Host "   • Installs to ./.claude/ (current directory)" -ForegroundColor White
Write-Host "   • Only in this project" -ForegroundColor Green
Write-Host ""
Write-Host "3) Both (Recommended)" -ForegroundColor Magenta
Write-Host "   • Global: Core methodology" -ForegroundColor White
Write-Host "   • Project: Project-specific overrides" -ForegroundColor Green
Write-Host ""

$installType = Read-Host "Choose [1/2/3]"

$installGlobal = $false
$installProject = $false

switch ($installType) {
    "1" {
        $installGlobal = $true
        Write-Host "✓ Global installation selected" -ForegroundColor Green
    }
    "2" {
        $installProject = $true
        Write-Host "✓ Project-level installation selected" -ForegroundColor Green
    }
    "3" {
        $installGlobal = $true
        $installProject = $true
        Write-Host "✓ Both installations selected" -ForegroundColor Green
    }
    default {
        Write-Host "Invalid choice" -ForegroundColor Red
        exit 1
    }
}

# Global installation
if ($installGlobal) {
    Write-Host ""
    Write-Host "[3/7] Installing globally to ~/.claude/" -ForegroundColor Yellow

    $claudeHome = Join-Path $env:USERPROFILE ".claude"
    New-Item -ItemType Directory -Path $claudeHome -Force | Out-Null
    New-Item -ItemType Directory -Path "$claudeHome\commands" -Force | Out-Null
    New-Item -ItemType Directory -Path "$claudeHome\skills" -Force | Out-Null

    # Backup existing CLAUDE.md
    $claudeMd = Join-Path $claudeHome "CLAUDE.md"
    if (Test-Path $claudeMd) {
        $backup = "$claudeMd.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Copy-Item $claudeMd $backup -Force
        Write-Host "  ✓ Backed up existing CLAUDE.md" -ForegroundColor Green
    }

    # Install global CLAUDE.md
    Merge-File "CLAUDE.md" $claudeMd

    # Merge commands
    if (Test-Path ".claude\commands") {
        Write-Host ""
        Write-Host "  Installing commands..." -ForegroundColor Blue
        Merge-Directory ".claude\commands" "$claudeHome\commands" "commands"
    }

    # Merge skills
    if (Test-Path ".claude\skills") {
        Write-Host ""
        Write-Host "  Installing skills..." -ForegroundColor Blue
        Merge-Directory ".claude\skills" "$claudeHome\skills" "skills"
    }

    # Copy scripts
    Write-Host ""
    Write-Host "  Installing scripts..." -ForegroundColor Blue
    if (Test-Path ".memory-system") {
        Copy-Item ".memory-system" "$claudeHome\" -Recurse -Force
    }

    if (Test-Path "docs") {
        Copy-Item "docs" "$claudeHome\" -Recurse -Force
    }

    Write-Host "  ✓ Scripts installed" -ForegroundColor Green
    Write-Host "✅ Global installation complete" -ForegroundColor Green
}

# Project installation
if ($installProject) {
    Write-Host ""
    Write-Host "[4/7] Installing to current project (./.claude/)" -ForegroundColor Yellow

    $projectClaude = ".\.claude"
    New-Item -ItemType Directory -Path $projectClaude -Force | Out-Null
    New-Item -ItemType Directory -Path "$projectClaude\commands" -Force | Out-Null
    New-Item -ItemType Directory -Path "$projectClaude\skills" -Force | Out-Null

    # Check for existing configuration
    if (Test-Path "$projectClaude\CLAUDE.md") {
        Write-Host "  ℹ Existing project configuration detected" -ForegroundColor Blue
    }

    # Install project CLAUDE.md
    $projectClaudeMd = "$projectClaude\CLAUDE.md"
    if (Test-Path "CLAUDE.md") {
        if (Test-Path $projectClaudeMd) {
            Write-Host "  ⚠ Project already has CLAUDE.md" -ForegroundColor Yellow
            if (Ask-YesNo "    Add methodology instructions to it?" "Y") {
                Add-Content $projectClaudeMd @"

# Feature Development Methodology

9-phase feature development system available. See docs/feature_cycle.md for documentation.

Quick commands:
- /interview FEAT-XXX - Interview phase
- /think-critically FEAT-XXX - Critical analysis
- /plan FEAT-XXX - Planning phase

"@
                Write-Host "    ✓ Appended methodology instructions" -ForegroundColor Green
            }
        } else {
            Copy-Item "CLAUDE.md" $projectClaudeMd -Force
            Write-Host "  ✓ Installed CLAUDE.md" -ForegroundColor Green
        }
    }

    # Merge commands
    if (Test-Path ".claude\commands") {
        Write-Host ""
        Write-Host "  Installing commands..." -ForegroundColor Blue
        Merge-Directory ".claude\commands" "$projectClaude\commands" "commands"
    }

    # Merge skills
    if (Test-Path ".claude\skills") {
        Write-Host ""
        Write-Host "  Installing skills..." -ForegroundColor Blue
        Merge-Directory ".claude\skills" "$projectClaude\skills" "skills"
    }

    # Copy scripts
    Write-Host ""
    Write-Host "  Installing scripts..." -ForegroundColor Blue
    # Copy .memory-system if not exists
    if (-not (Test-Path ".memory-system")) {
        Copy-Item ".memory-system" ".\" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  ✓ Installed .memory-system" -ForegroundColor Green
    } else {
        Write-Host "  ℹ .memory-system already exists (preserved)" -ForegroundColor Blue
    }

    # Copy docs if not exists
    if (-not (Test-Path "docs\features")) {
        New-Item -ItemType Directory -Path "docs\features" -Force | Out-Null
        Copy-Item "docs\features\_template" "docs\features\" -Recurse -Force -ErrorAction SilentlyContinue
        Copy-Item "docs\feature_cycle.md" "docs\" -Force -ErrorAction SilentlyContinue
        Write-Host "  ✓ Installed docs/features/_template" -ForegroundColor Green
    } else {
        Write-Host "  ℹ docs/features already exists (preserved)" -ForegroundColor Blue
    }

    Write-Host "✅ Project-level installation complete" -ForegroundColor Green
}

# Setup PATH
Write-Host ""
Write-Host "[5/7] Setting up PATH..." -ForegroundColor Yellow

if ($installGlobal) {
    Write-Host "  ℹ No PATH changes needed" -ForegroundColor Blue
}

# Install git hooks
Write-Host ""
Write-Host "[6/7] Git hooks (security filters)" -ForegroundColor Yellow

if ((Test-Path ".git") -and (Ask-YesNo "Install security pre-commit hooks in this repo?" "Y")) {
    if ($installGlobal) {
        & powershell -ExecutionPolicy Bypass -File ".memory-system\scripts\install-git-hooks.ps1"
    }
    Write-Host "  ✓ Git hooks installed" -ForegroundColor Green
} else {
    Write-Host "  ℹ Skipped git hooks" -ForegroundColor Blue
}

# Summary
Write-Host ""
Write-Host "[7/7] Installation summary" -ForegroundColor Yellow
Write-Host ""

if ($installGlobal) {
    Write-Host "✅ Global Installation" -ForegroundColor Green
    Write-Host "   Location: ~/.claude/" -ForegroundColor Cyan
    $commandCount = (Get-ChildItem "$env:USERPROFILE\.claude\commands" -ErrorAction SilentlyContinue).Count
    $skillCount = (Get-ChildItem "$env:USERPROFILE\.claude\skills" -ErrorAction SilentlyContinue).Count
    Write-Host "   • Commands: $commandCount installed"
    Write-Host "   • Skills: $skillCount installed"
    Write-Host ""
}

if ($installProject) {
    Write-Host "✅ Project Installation" -ForegroundColor Green
    Write-Host "   Location: ./.claude/" -ForegroundColor Cyan
    $commandCount = (Get-ChildItem ".\.claude\commands" -ErrorAction SilentlyContinue).Count
    $skillCount = (Get-ChildItem ".\.claude\skills" -ErrorAction SilentlyContinue).Count
    Write-Host "   • Commands: $commandCount in project"
    Write-Host "   • Skills: $skillCount in project"
    Write-Host ""
}

# Final instructions
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                                                              ║" -ForegroundColor Cyan
Write-Host "║            ✅ INSTALLATION COMPLETE!                          ║" -ForegroundColor Cyan
Write-Host "║                                                              ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Write-Host "Usage:" -ForegroundColor Blue
if ($installGlobal) {
    Write-Host "  Global: Use in ANY project" -ForegroundColor Green
    Write-Host "    1. cd any-project"
    Write-Host "    2. claude code ."
    Write-Host "    3. Use commands: /interview, /think-critically, etc."
    Write-Host ""
}

if ($installProject) {
    Write-Host "  Project: Use in THIS project" -ForegroundColor Green
    Write-Host "    1. claude code ."
    Write-Host "    2. Use commands: /interview, /think-critically, etc."
    Write-Host ""
}

Write-Host "Available Commands:" -ForegroundColor Blue
Write-Host "  • /interview FEAT-XXX - Interview phase" -ForegroundColor Green
Write-Host "  • /think-critically FEAT-XXX - Critical analysis" -ForegroundColor Green
Write-Host "  • /plan FEAT-XXX - Planning phase" -ForegroundColor Green
Write-Host ""

Write-Host "Happy coding! 🚀" -ForegroundColor Magenta
Write-Host ""
