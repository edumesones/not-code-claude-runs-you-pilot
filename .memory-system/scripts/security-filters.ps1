# Security Filters for Browser Automation Tests (PowerShell)
#
# MANDATORY pre-commit filters to prevent secret leakage

#Requires -Version 5.1

param(
    [Parameter(Position=0)]
    [string]$Command,

    [Parameter(Position=1)]
    [string]$Path,

    [Parameter(Position=2)]
    [string]$OutputPath
)

###############################################################################
# SECRET PATTERNS (Regex)
###############################################################################

$script:API_KEY_PATTERNS = @(
    'api[_-]?key\s*[:=]\s*["\047]?[a-zA-Z0-9_\-]{20,}',
    'apikey\s*[:=]\s*["\047]?[a-zA-Z0-9_\-]{20,}',
    'api_secret\s*[:=]\s*["\047]?[a-zA-Z0-9_\-]{20,}'
)

$script:TOKEN_PATTERNS = @(
    'Bearer\s+[a-zA-Z0-9_\-\.]{20,}',
    'token\s*[:=]\s*["\047]?[a-zA-Z0-9_\-\.]{20,}',
    'access_token\s*[:=]\s*["\047]?[a-zA-Z0-9_\-\.]{20,}',
    'jwt\s*[:=]\s*["\047]?eyJ[a-zA-Z0-9_\-\.]{20,}'
)

$script:PASSWORD_PATTERNS = @(
    'password\s*[:=]\s*["\047][^\s"'\'']{8,}',
    'passwd\s*[:=]\s*["\047][^\s"'\'']{8,}'
)

$script:AWS_PATTERNS = @(
    'AKIA[0-9A-Z]{16}',
    'aws_access_key_id\s*[:=]\s*["\047]?[A-Z0-9]{20}'
)

$script:KEY_PATTERNS = @(
    '-----BEGIN\s+(RSA\s+)?PRIVATE\s+KEY-----'
)

$script:DB_PATTERNS = @(
    'postgres://[^:]+:[^@]+@[^/]+',
    'mysql://[^:]+:[^@]+@[^/]+',
    'mongodb://[^:]+:[^@]+@[^/]+'
)

###############################################################################
# FUNCTIONS
###############################################################################

function Test-TextForSecrets {
    param(
        [string]$Text,
        [string]$Source
    )

    $found = $false

    foreach ($pattern in $script:API_KEY_PATTERNS) {
        if ($Text -match $pattern) {
            Write-Host "[SECURITY] API key pattern detected in $Source" -ForegroundColor Red
            $found = $true
        }
    }

    foreach ($pattern in $script:TOKEN_PATTERNS) {
        if ($Text -match $pattern) {
            Write-Host "[SECURITY] Token pattern detected in $Source" -ForegroundColor Red
            $found = $true
        }
    }

    foreach ($pattern in $script:PASSWORD_PATTERNS) {
        if ($Text -match $pattern) {
            Write-Host "[SECURITY] Password pattern detected in $Source" -ForegroundColor Red
            $found = $true
        }
    }

    foreach ($pattern in $script:AWS_PATTERNS) {
        if ($Text -match $pattern) {
            Write-Host "[SECURITY] AWS credential detected in $Source" -ForegroundColor Red
            $found = $true
        }
    }

    foreach ($pattern in $script:KEY_PATTERNS) {
        if ($Text -match $pattern) {
            Write-Host "[SECURITY] Private key detected in $Source" -ForegroundColor Red
            $found = $true
        }
    }

    foreach ($pattern in $script:DB_PATTERNS) {
        if ($Text -match $pattern) {
            Write-Host "[SECURITY] Database URL with credentials detected in $Source" -ForegroundColor Red
            $found = $true
        }
    }

    return $found
}

function Invoke-FilterConsoleLogs {
    param(
        [string]$InputFile,
        [string]$OutputFile
    )

    if (-not (Test-Path $InputFile)) {
        Write-Host "[ERROR] Input file not found: $InputFile" -ForegroundColor Red
        return $false
    }

    Write-Host "[SECURITY] Filtering console logs: $InputFile" -ForegroundColor Yellow

    $content = Get-Content $InputFile -Raw

    # Apply filters
    foreach ($pattern in $script:API_KEY_PATTERNS) {
        $content = $content -replace $pattern, '[REDACTED-API-KEY]'
    }

    foreach ($pattern in $script:TOKEN_PATTERNS) {
        $content = $content -replace $pattern, '[REDACTED-TOKEN]'
    }

    foreach ($pattern in $script:PASSWORD_PATTERNS) {
        $content = $content -replace $pattern, '[REDACTED-PASSWORD]'
    }

    foreach ($pattern in $script:AWS_PATTERNS) {
        $content = $content -replace $pattern, '[REDACTED-AWS]'
    }

    foreach ($pattern in $script:DB_PATTERNS) {
        $content = $content -replace $pattern, '[REDACTED-DB-URL]'
    }

    # Check if secrets remain
    if (Test-TextForSecrets $content $InputFile) {
        Write-Host "[SECURITY] ⚠️  Secrets still detected after filtering!" -ForegroundColor Red
        Write-Host "[SECURITY] Manual review required before git commit" -ForegroundColor Red
        return $false
    }

    # Write filtered output
    $content | Set-Content -Path $OutputFile -Encoding UTF8
    Write-Host "[SECURITY] ✅ Console logs filtered: $OutputFile" -ForegroundColor Green

    # Show redaction count
    $redacted = ([regex]::Matches($content, '\[REDACTED-[^\]]*\]')).Count
    Write-Host "[SECURITY] Redacted $redacted secrets" -ForegroundColor Yellow

    return $true
}

function Invoke-ScanFile {
    param(
        [string]$FilePath
    )

    if (-not (Test-Path $FilePath)) {
        Write-Host "[ERROR] File not found: $FilePath" -ForegroundColor Red
        return $false
    }

    Write-Host "[SECURITY] Scanning: $FilePath" -ForegroundColor Yellow

    $content = Get-Content $FilePath -Raw

    if (Test-TextForSecrets $content $FilePath) {
        Write-Host "[SECURITY] ❌ BLOCK: Secrets detected in $FilePath" -ForegroundColor Red
        Write-Host "[SECURITY] Run filter script before git commit" -ForegroundColor Red
        return $false
    }

    Write-Host "[SECURITY] ✅ No secrets detected in $FilePath" -ForegroundColor Green
    return $true
}

function Invoke-ScanDirectory {
    param(
        [string]$Directory,
        [string]$Pattern = "*.txt"
    )

    Write-Host "[SECURITY] Scanning directory: $Directory" -ForegroundColor Yellow
    Write-Host "[SECURITY] Pattern: $Pattern" -ForegroundColor Yellow

    $failed = 0

    Get-ChildItem -Path $Directory -Filter $Pattern -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
        if (-not (Invoke-ScanFile $_.FullName)) {
            $failed++
        }
    }

    if ($failed -gt 0) {
        Write-Host "[SECURITY] ❌ Found secrets in $failed files" -ForegroundColor Red
        return $false
    }

    Write-Host "[SECURITY] ✅ Directory scan complete: no secrets found" -ForegroundColor Green
    return $true
}

function Invoke-PreCommitHook {
    Write-Host "[SECURITY] Running pre-commit security scan..." -ForegroundColor Yellow

    $failed = 0

    if (Test-Path "docs\features") {
        # Scan console logs
        Get-ChildItem -Path "docs\features" -Filter "console-logs.txt" -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
            if (-not (Invoke-ScanFile $_.FullName)) {
                $failed++
            }
        }

        # Scan network logs
        Get-ChildItem -Path "docs\features" -Filter "network-logs.json" -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
            if (-not (Invoke-ScanFile $_.FullName)) {
                $failed++
            }
        }

        # Scan test reports
        Get-ChildItem -Path "docs\features" -Filter "test-report.md" -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
            if (-not (Invoke-ScanFile $_.FullName)) {
                $failed++
            }
        }
    }

    if ($failed -gt 0) {
        Write-Host "[SECURITY] ❌ PRE-COMMIT BLOCKED: $failed files contain secrets" -ForegroundColor Red
        Write-Host "[SECURITY] Run security filters before committing:" -ForegroundColor Yellow
        Write-Host "    .\memory-system\scripts\security-filters.ps1 filter-all docs\features\FEAT-XXX\test-results" -ForegroundColor Yellow
        return $false
    }

    Write-Host "[SECURITY] ✅ Pre-commit scan passed" -ForegroundColor Green
    return $true
}

function Invoke-FilterAllDirectory {
    param(
        [string]$Directory
    )

    if (-not (Test-Path $Directory)) {
        Write-Host "[ERROR] Directory not found: $Directory" -ForegroundColor Red
        return $false
    }

    Write-Host "[SECURITY] Filtering all files in: $Directory" -ForegroundColor Yellow

    # Filter console logs
    Get-ChildItem -Path $Directory -Filter "console-logs.txt" -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
        Invoke-FilterConsoleLogs $_.FullName $_.FullName
    }

    # Filter network logs
    Get-ChildItem -Path $Directory -Filter "network-logs.json" -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
        Invoke-FilterConsoleLogs $_.FullName $_.FullName
    }

    Write-Host "[SECURITY] ✅ All files filtered" -ForegroundColor Green
    return $true
}

###############################################################################
# CLI INTERFACE
###############################################################################

switch ($Command) {
    "scan" {
        $result = Invoke-ScanFile $Path
        exit $(if ($result) { 0 } else { 1 })
    }

    "scan-dir" {
        $pattern = if ($OutputPath) { $OutputPath } else { "*.txt" }
        $result = Invoke-ScanDirectory $Path $pattern
        exit $(if ($result) { 0 } else { 1 })
    }

    "filter-console" {
        $output = if ($OutputPath) { $OutputPath } else { $Path }
        $result = Invoke-FilterConsoleLogs $Path $output
        exit $(if ($result) { 0 } else { 1 })
    }

    "filter-network" {
        $output = if ($OutputPath) { $OutputPath } else { $Path }
        $result = Invoke-FilterConsoleLogs $Path $output
        exit $(if ($result) { 0 } else { 1 })
    }

    "filter-all" {
        $result = Invoke-FilterAllDirectory $Path
        exit $(if ($result) { 0 } else { 1 })
    }

    "pre-commit" {
        $result = Invoke-PreCommitHook
        exit $(if ($result) { 0 } else { 1 })
    }

    default {
        Write-Host "Security Filters for Browser Automation Tests" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Usage: .\security-filters.ps1 <command> <args>"
        Write-Host ""
        Write-Host "Commands:"
        Write-Host "  scan <file>                    - Scan file for secrets"
        Write-Host "  scan-dir <dir> [pattern]       - Scan directory (default: *.txt)"
        Write-Host "  filter-console <input> [out]   - Filter console logs"
        Write-Host "  filter-network <input> [out]   - Filter network logs"
        Write-Host "  filter-all <dir>               - Filter all files in directory"
        Write-Host "  pre-commit                     - Run pre-commit security scan"
        Write-Host ""
        Write-Host "Examples:"
        Write-Host "  .\security-filters.ps1 scan docs\features\FEAT-001\test-results\console-logs.txt"
        Write-Host "  .\security-filters.ps1 scan-dir docs\features\FEAT-001\test-results"
        Write-Host "  .\security-filters.ps1 filter-console docs\features\FEAT-001\test-results\console-logs.txt"
        Write-Host "  .\security-filters.ps1 filter-all docs\features\FEAT-001\test-results"
        Write-Host "  .\security-filters.ps1 pre-commit"
        Write-Host ""
    }
}
