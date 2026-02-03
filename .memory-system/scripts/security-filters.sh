#!/bin/bash
###############################################################################
# Security Filters for Browser Automation Tests
#
# MANDATORY pre-commit filters to prevent secret leakage in:
# - Screenshots
# - Console logs
# - Network logs
# - Test reports
###############################################################################

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

###############################################################################
# SECRET PATTERNS (Regex)
###############################################################################

# API Keys
declare -a API_KEY_PATTERNS=(
  'api[_-]?key\s*[:=]\s*["\047]?[a-zA-Z0-9_\-]{20,}'
  'apikey\s*[:=]\s*["\047]?[a-zA-Z0-9_\-]{20,}'
  'api_secret\s*[:=]\s*["\047]?[a-zA-Z0-9_\-]{20,}'
)

# Tokens
declare -a TOKEN_PATTERNS=(
  'Bearer\s+[a-zA-Z0-9_\-\.]{20,}'
  'token\s*[:=]\s*["\047]?[a-zA-Z0-9_\-\.]{20,}'
  'access_token\s*[:=]\s*["\047]?[a-zA-Z0-9_\-\.]{20,}'
  'refresh_token\s*[:=]\s*["\047]?[a-zA-Z0-9_\-\.]{20,}'
  'jwt\s*[:=]\s*["\047]?eyJ[a-zA-Z0-9_\-\.]{20,}'
)

# Passwords
declare -a PASSWORD_PATTERNS=(
  'password\s*[:=]\s*["\047][^\s"'\'']{8,}'
  'passwd\s*[:=]\s*["\047][^\s"'\'']{8,}'
  'pwd\s*[:=]\s*["\047][^\s"'\'']{8,}'
)

# AWS Credentials
declare -a AWS_PATTERNS=(
  'AKIA[0-9A-Z]{16}'
  'aws_access_key_id\s*[:=]\s*["\047]?[A-Z0-9]{20}'
  'aws_secret_access_key\s*[:=]\s*["\047]?[A-Za-z0-9/+=]{40}'
)

# Private Keys
declare -a KEY_PATTERNS=(
  '-----BEGIN\s+(RSA\s+)?PRIVATE\s+KEY-----'
  '-----BEGIN\s+OPENSSH\s+PRIVATE\s+KEY-----'
)

# Database URLs
declare -a DB_PATTERNS=(
  'postgres://[^:]+:[^@]+@[^/]+'
  'mysql://[^:]+:[^@]+@[^/]+'
  'mongodb://[^:]+:[^@]+@[^/]+'
)

###############################################################################
# FUNCTION: Scan text for secrets
###############################################################################

scan_text_for_secrets() {
  local TEXT="$1"
  local SOURCE="$2"
  local FOUND=0

  # Check all pattern arrays
  for pattern in "${API_KEY_PATTERNS[@]}"; do
    if echo "$TEXT" | grep -qiE "$pattern"; then
      echo -e "${RED}[SECURITY] API key pattern detected in $SOURCE${NC}"
      echo "  Pattern: $pattern"
      FOUND=1
    fi
  done

  for pattern in "${TOKEN_PATTERNS[@]}"; do
    if echo "$TEXT" | grep -qiE "$pattern"; then
      echo -e "${RED}[SECURITY] Token pattern detected in $SOURCE${NC}"
      echo "  Pattern: $pattern"
      FOUND=1
    fi
  done

  for pattern in "${PASSWORD_PATTERNS[@]}"; do
    if echo "$TEXT" | grep -qiE "$pattern"; then
      echo -e "${RED}[SECURITY] Password pattern detected in $SOURCE${NC}"
      echo "  Pattern: $pattern"
      FOUND=1
    fi
  done

  for pattern in "${AWS_PATTERNS[@]}"; do
    if echo "$TEXT" | grep -qE "$pattern"; then
      echo -e "${RED}[SECURITY] AWS credential detected in $SOURCE${NC}"
      echo "  Pattern: $pattern"
      FOUND=1
    fi
  done

  for pattern in "${KEY_PATTERNS[@]}"; do
    if echo "$TEXT" | grep -qE "$pattern"; then
      echo -e "${RED}[SECURITY] Private key detected in $SOURCE${NC}"
      echo "  Pattern: $pattern"
      FOUND=1
    fi
  done

  for pattern in "${DB_PATTERNS[@]}"; do
    if echo "$TEXT" | grep -qE "$pattern"; then
      echo -e "${RED}[SECURITY] Database URL with credentials detected in $SOURCE${NC}"
      echo "  Pattern: $pattern"
      FOUND=1
    fi
  done

  return $FOUND
}

###############################################################################
# FUNCTION: Filter console logs
###############################################################################

filter_console_logs() {
  local INPUT_FILE="$1"
  local OUTPUT_FILE="${2:-${INPUT_FILE}.filtered}"

  if [ ! -f "$INPUT_FILE" ]; then
    echo -e "${RED}[ERROR] Input file not found: $INPUT_FILE${NC}"
    return 1
  fi

  echo -e "${YELLOW}[SECURITY] Filtering console logs: $INPUT_FILE${NC}"

  # Read and filter
  local CONTENT=$(cat "$INPUT_FILE")

  # Apply filters (replace with [REDACTED])
  for pattern in "${API_KEY_PATTERNS[@]}"; do
    CONTENT=$(echo "$CONTENT" | sed -E "s/$pattern/[REDACTED-API-KEY]/gi")
  done

  for pattern in "${TOKEN_PATTERNS[@]}"; do
    CONTENT=$(echo "$CONTENT" | sed -E "s/$pattern/[REDACTED-TOKEN]/gi")
  done

  for pattern in "${PASSWORD_PATTERNS[@]}"; do
    CONTENT=$(echo "$CONTENT" | sed -E "s/$pattern/[REDACTED-PASSWORD]/gi")
  done

  for pattern in "${AWS_PATTERNS[@]}"; do
    CONTENT=$(echo "$CONTENT" | sed -E "s/$pattern/[REDACTED-AWS]/g")
  done

  for pattern in "${DB_PATTERNS[@]}"; do
    CONTENT=$(echo "$CONTENT" | sed -E "s/$pattern/[REDACTED-DB-URL]/g")
  done

  # Check if any secrets remain
  if scan_text_for_secrets "$CONTENT" "$INPUT_FILE"; then
    echo -e "${RED}[SECURITY] ⚠️  Secrets still detected after filtering!${NC}"
    echo -e "${RED}[SECURITY] Manual review required before git commit${NC}"
    return 1
  fi

  # Write filtered output
  echo "$CONTENT" > "$OUTPUT_FILE"
  echo -e "${GREEN}[SECURITY] ✅ Console logs filtered: $OUTPUT_FILE${NC}"

  # Show redaction count
  local REDACTED=$(echo "$CONTENT" | grep -o '\[REDACTED-[^]]*\]' | wc -l)
  echo -e "${YELLOW}[SECURITY] Redacted $REDACTED secrets${NC}"

  return 0
}

###############################################################################
# FUNCTION: Filter network logs (HAR)
###############################################################################

filter_network_logs() {
  local INPUT_FILE="$1"
  local OUTPUT_FILE="${2:-${INPUT_FILE}.filtered}"

  if [ ! -f "$INPUT_FILE" ]; then
    echo -e "${RED}[ERROR] Input file not found: $INPUT_FILE${NC}"
    return 1
  fi

  echo -e "${YELLOW}[SECURITY] Filtering network logs: $INPUT_FILE${NC}"

  # Read and filter
  local CONTENT=$(cat "$INPUT_FILE")

  # Apply filters
  for pattern in "${API_KEY_PATTERNS[@]}"; do
    CONTENT=$(echo "$CONTENT" | sed -E "s/$pattern/[REDACTED-API-KEY]/gi")
  done

  for pattern in "${TOKEN_PATTERNS[@]}"; do
    CONTENT=$(echo "$CONTENT" | sed -E "s/$pattern/[REDACTED-TOKEN]/gi")
  done

  for pattern in "${PASSWORD_PATTERNS[@]}"; do
    CONTENT=$(echo "$CONTENT" | sed -E "s/$pattern/[REDACTED-PASSWORD]/gi")
  done

  # Write filtered output
  echo "$CONTENT" > "$OUTPUT_FILE"
  echo -e "${GREEN}[SECURITY] ✅ Network logs filtered: $OUTPUT_FILE${NC}"

  return 0
}

###############################################################################
# FUNCTION: Scan file for secrets (pre-commit check)
###############################################################################

scan_file() {
  local FILE="$1"

  if [ ! -f "$FILE" ]; then
    echo -e "${RED}[ERROR] File not found: $FILE${NC}"
    return 1
  fi

  echo -e "${YELLOW}[SECURITY] Scanning: $FILE${NC}"

  local CONTENT=$(cat "$FILE")

  if scan_text_for_secrets "$CONTENT" "$FILE"; then
    echo -e "${RED}[SECURITY] ❌ BLOCK: Secrets detected in $FILE${NC}"
    echo -e "${RED}[SECURITY] Run filter script before git commit${NC}"
    return 1
  fi

  echo -e "${GREEN}[SECURITY] ✅ No secrets detected in $FILE${NC}"
  return 0
}

###############################################################################
# FUNCTION: Scan directory recursively
###############################################################################

scan_directory() {
  local DIR="$1"
  local PATTERN="${2:-*.txt}"
  local FAILED=0

  echo -e "${YELLOW}[SECURITY] Scanning directory: $DIR${NC}"
  echo -e "${YELLOW}[SECURITY] Pattern: $PATTERN${NC}"

  # Find all matching files
  while IFS= read -r file; do
    if ! scan_file "$file"; then
      FAILED=$((FAILED + 1))
    fi
  done < <(find "$DIR" -name "$PATTERN" -type f 2>/dev/null)

  if [ $FAILED -gt 0 ]; then
    echo -e "${RED}[SECURITY] ❌ Found secrets in $FAILED files${NC}"
    return 1
  fi

  echo -e "${GREEN}[SECURITY] ✅ Directory scan complete: no secrets found${NC}"
  return 0
}

###############################################################################
# FUNCTION: Pre-commit hook
###############################################################################

pre_commit_hook() {
  echo -e "${YELLOW}[SECURITY] Running pre-commit security scan...${NC}"

  local FAILED=0

  # Scan test results
  if [ -d "docs/features" ]; then
    # Scan console logs
    while IFS= read -r file; do
      if ! scan_file "$file"; then
        FAILED=$((FAILED + 1))
      fi
    done < <(find docs/features -name "console-logs.txt" -type f 2>/dev/null)

    # Scan network logs
    while IFS= read -r file; do
      if ! scan_file "$file"; then
        FAILED=$((FAILED + 1))
      fi
    done < <(find docs/features -name "network-logs.json" -type f 2>/dev/null)

    # Scan test reports
    while IFS= read -r file; do
      if ! scan_file "$file"; then
        FAILED=$((FAILED + 1))
      fi
    done < <(find docs/features -name "test-report.md" -type f 2>/dev/null)
  fi

  if [ $FAILED -gt 0 ]; then
    echo -e "${RED}[SECURITY] ❌ PRE-COMMIT BLOCKED: $FAILED files contain secrets${NC}"
    echo -e "${YELLOW}[SECURITY] Run security filters before committing:${NC}"
    echo -e "${YELLOW}    bash .memory-system/scripts/security-filters.sh filter-all docs/features/FEAT-XXX/test-results${NC}"
    return 1
  fi

  echo -e "${GREEN}[SECURITY] ✅ Pre-commit scan passed${NC}"
  return 0
}

###############################################################################
# FUNCTION: Filter all files in directory
###############################################################################

filter_all_directory() {
  local DIR="$1"

  if [ ! -d "$DIR" ]; then
    echo -e "${RED}[ERROR] Directory not found: $DIR${NC}"
    return 1
  fi

  echo -e "${YELLOW}[SECURITY] Filtering all files in: $DIR${NC}"

  # Filter console logs
  while IFS= read -r file; do
    filter_console_logs "$file" "$file"
  done < <(find "$DIR" -name "console-logs.txt" -type f 2>/dev/null)

  # Filter network logs
  while IFS= read -r file; do
    filter_network_logs "$file" "$file"
  done < <(find "$DIR" -name "network-logs.json" -type f 2>/dev/null)

  echo -e "${GREEN}[SECURITY] ✅ All files filtered${NC}"
}

###############################################################################
# CLI INTERFACE
###############################################################################

case "${1:-}" in
  scan)
    # Scan single file
    scan_file "$2"
    ;;

  scan-dir)
    # Scan directory
    scan_directory "$2" "${3:-*.txt}"
    ;;

  filter-console)
    # Filter console logs
    filter_console_logs "$2" "$3"
    ;;

  filter-network)
    # Filter network logs
    filter_network_logs "$2" "$3"
    ;;

  filter-all)
    # Filter all files in directory
    filter_all_directory "$2"
    ;;

  pre-commit)
    # Pre-commit hook
    pre_commit_hook
    ;;

  *)
    echo "Security Filters for Browser Automation Tests"
    echo ""
    echo "Usage: $0 <command> <args>"
    echo ""
    echo "Commands:"
    echo "  scan <file>                    - Scan file for secrets"
    echo "  scan-dir <dir> [pattern]       - Scan directory (default: *.txt)"
    echo "  filter-console <input> [out]   - Filter console logs"
    echo "  filter-network <input> [out]   - Filter network logs"
    echo "  filter-all <dir>               - Filter all files in directory"
    echo "  pre-commit                     - Run pre-commit security scan"
    echo ""
    echo "Examples:"
    echo "  $0 scan docs/features/FEAT-001/test-results/console-logs.txt"
    echo "  $0 scan-dir docs/features/FEAT-001/test-results"
    echo "  $0 filter-console docs/features/FEAT-001/test-results/console-logs.txt"
    echo "  $0 filter-all docs/features/FEAT-001/test-results"
    echo "  $0 pre-commit"
    echo ""
    ;;
esac
