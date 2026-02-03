#!/bin/bash
###############################################################################
# Test Helpers for Browser Automation
# Reusable functions for agent-browser E2E tests
###############################################################################

set -e

# Configuration from test-config.json or environment
FEATURE_ID="${FEATURE_ID:-FEAT-XXX}"
BASE_URL="${BASE_URL:-http://localhost:3000}"
SESSION="${SESSION:-ralph-$FEATURE_ID}"
RESULTS_DIR="${RESULTS_DIR:-./test-results}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

###############################################################################
# Logging
###############################################################################

log_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[✓]${NC} $1"
}

log_error() {
  echo -e "${RED}[✗]${NC} $1"
}

log_warn() {
  echo -e "${YELLOW}[!]${NC} $1"
}

###############################################################################
# Setup / Teardown
###############################################################################

setup_test() {
  local feature_id=$1

  log_info "Setting up test for $feature_id..."

  # Create results directories
  mkdir -p "$RESULTS_DIR/screenshots"
  mkdir -p "$RESULTS_DIR/videos"

  # Clear previous results
  rm -f "$RESULTS_DIR/screenshots"/*.png 2>/dev/null || true
  rm -f "$RESULTS_DIR/console-logs.txt" 2>/dev/null || true
  rm -f "$RESULTS_DIR/network-logs.json" 2>/dev/null || true

  log_success "Test setup complete"
}

cleanup_test() {
  log_info "Cleaning up test session..."

  # Close browser session
  agent-browser --session "$SESSION" close 2>/dev/null || true

  log_success "Cleanup complete"
}

###############################################################################
# Screenshot Helpers
###############################################################################

screenshot() {
  local name=$1
  local filepath="$RESULTS_DIR/screenshots/${name}.png"

  log_info "Taking screenshot: $name"
  agent-browser --session "$SESSION" screenshot "$filepath"

  if [ -f "$filepath" ]; then
    log_success "Screenshot saved: $filepath"
  else
    log_error "Screenshot failed: $filepath"
    return 1
  fi
}

###############################################################################
# Navigation Helpers
###############################################################################

goto_page() {
  local path=$1
  local url="$BASE_URL$path"

  log_info "Navigating to: $url"
  agent-browser --session "$SESSION" goto "$url"
  agent-browser --session "$SESSION" wait --load networkidle --timeout 10000
  log_success "Page loaded"
}

wait_for_url() {
  local pattern=$1
  local timeout=${2:-10000}

  log_info "Waiting for URL: $pattern"
  agent-browser --session "$SESSION" wait --url "$pattern" --timeout "$timeout"
  log_success "URL matched: $pattern"
}

###############################################################################
# Element Interaction Helpers
###############################################################################

click_button() {
  local selector=$1

  log_info "Clicking: $selector"
  agent-browser --session "$SESSION" click "$selector"
  agent-browser --session "$SESSION" wait 500
  log_success "Clicked: $selector"
}

fill_field() {
  local selector=$1
  local value=$2

  log_info "Filling field: $selector"
  agent-browser --session "$SESSION" fill "$selector" "$value"
  log_success "Filled: $selector"
}

###############################################################################
# Assertion Helpers
###############################################################################

assert_text_present() {
  local text=$1
  local page_text=$(agent-browser --session "$SESSION" get text)

  if echo "$page_text" | grep -q "$text"; then
    log_success "Text found: '$text'"
    return 0
  else
    log_error "Text NOT found: '$text'"
    screenshot "assertion-failed-$(date +%s)"
    return 1
  fi
}

assert_url_contains() {
  local pattern=$1
  local current_url=$(agent-browser --session "$SESSION" get url)

  if echo "$current_url" | grep -q "$pattern"; then
    log_success "URL contains: '$pattern'"
    return 0
  else
    log_error "URL does NOT contain: '$pattern' (current: $current_url)"
    screenshot "url-assertion-failed-$(date +%s)"
    return 1
  fi
}

###############################################################################
# Login Helper
###############################################################################

login_user() {
  local email=$1
  local password=$2

  log_info "Logging in as: $email"

  goto_page "/login"
  screenshot "01-login-page"

  fill_field "input[type='email'], input[name='email']" "$email"
  fill_field "input[type='password'], input[name='password']" "$password"
  screenshot "02-login-filled"

  click_button "button[type='submit'], button:has-text('Login'), button:has-text('Sign in')"

  wait_for_url "**/dashboard" 2>/dev/null || wait_for_url "**/home" 2>/dev/null || true
  screenshot "03-logged-in"

  log_success "Login complete"
}

###############################################################################
# Console & Network Capture
###############################################################################

capture_console_logs() {
  log_info "Capturing console logs..."
  agent-browser --session "$SESSION" get console > "$RESULTS_DIR/console-logs.txt"
  log_success "Console logs saved: $RESULTS_DIR/console-logs.txt"
}

capture_network_logs() {
  log_info "Capturing network logs..."
  agent-browser --session "$SESSION" get network > "$RESULTS_DIR/network-logs.json"
  log_success "Network logs saved: $RESULTS_DIR/network-logs.json"
}

###############################################################################
# Failure Handling
###############################################################################

on_test_failure() {
  local test_name=$1

  log_error "Test failed: $test_name"

  # Capture failure state
  screenshot "failure-${test_name}-$(date +%s)"
  capture_console_logs
  capture_network_logs

  log_info "Failure state captured"
}

###############################################################################
# Test Report Generation
###############################################################################

generate_test_report() {
  local status=$1
  local test_name=$2
  local report_file="$RESULTS_DIR/test-report.md"

  log_info "Generating test report..."

  cat > "$report_file" <<EOF
# Test Report: $FEATURE_ID

**Test:** $test_name
**Date:** $(date +"%Y-%m-%d %H:%M:%S")
**Status:** $status

## Test Results

$(if [ "$status" = "PASSED" ]; then echo "✅ All tests passed"; else echo "❌ Tests failed"; fi)

## Screenshots

$(ls $RESULTS_DIR/screenshots/*.png 2>/dev/null | while read f; do echo "- $(basename $f)"; done)

## Console Logs

\`\`\`
$(head -20 $RESULTS_DIR/console-logs.txt 2>/dev/null || echo "No console logs captured")
\`\`\`

## Network Activity

$(head -10 $RESULTS_DIR/network-logs.json 2>/dev/null || echo "No network logs captured")

---
*Generated by Ralph Loop Phase 5.5 (VERIFY)*
EOF

  log_success "Test report generated: $report_file"
}

###############################################################################
# Retry Helper
###############################################################################

retry() {
  local max_attempts=$1
  shift
  local command="$@"
  local attempt=1

  while [ $attempt -le $max_attempts ]; do
    log_info "Attempt $attempt/$max_attempts: $command"

    if eval "$command"; then
      log_success "Command succeeded on attempt $attempt"
      return 0
    fi

    log_warn "Command failed, retrying..."
    attempt=$((attempt + 1))
    sleep 2
  done

  log_error "Command failed after $max_attempts attempts"
  return 1
}
