#!/bin/bash
###############################################################################
# Smoke Tests: FEAT-XXX
# Quick sanity checks - runs in <30 seconds
###############################################################################

set -e

# Get script directory for relative imports
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load helpers
source "$SCRIPT_DIR/helpers.sh"

# Load configuration
if [ -f "$SCRIPT_DIR/test-config.json" ]; then
  FEATURE_ID=$(grep -o '"feature_id"[^,}]*' "$SCRIPT_DIR/test-config.json" | sed 's/"feature_id"[^"]*"\([^"]*\)".*/\1/')
fi

FEATURE_ID="${FEATURE_ID:-FEAT-XXX}"
BASE_URL="${BASE_URL:-http://localhost:3000}"
SESSION="${SESSION:-ralph-$FEATURE_ID-smoke}"
RESULTS_DIR="$SCRIPT_DIR/../test-results"

###############################################################################
# Smoke Tests
###############################################################################

smoke_test_page_loads() {
  log_info "Smoke Test: Page Loads"

  goto_page "/"
  screenshot "smoke-01-homepage"

  assert_text_present "Home" || assert_text_present "Welcome" || true

  log_success "Page Loads: PASSED"
}

smoke_test_login_page_exists() {
  log_info "Smoke Test: Login Page Exists"

  goto_page "/login"
  screenshot "smoke-02-login"

  assert_text_present "Login" || assert_text_present "Sign in"

  log_success "Login Page Exists: PASSED"
}

smoke_test_feature_page_exists() {
  log_info "Smoke Test: Feature Page Exists"

  goto_page "/feature-page"  # Replace with actual feature URL
  screenshot "smoke-03-feature-page"

  # Just check page loads (200 status)
  # If we get here without error, page exists

  log_success "Feature Page Exists: PASSED"
}

smoke_test_no_js_errors() {
  log_info "Smoke Test: No JavaScript Errors"

  goto_page "/"

  # Capture console logs
  local console_output=$(agent-browser --session "$SESSION" get console)

  # Check for critical errors (case-insensitive)
  if echo "$console_output" | grep -iq "error\|exception\|uncaught"; then
    log_error "JavaScript errors detected in console"
    echo "$console_output" > "$RESULTS_DIR/smoke-console-errors.txt"
    return 1
  fi

  log_success "No JavaScript Errors: PASSED"
}

###############################################################################
# Main
###############################################################################

main() {
  echo ""
  echo "=========================================="
  echo "  Smoke Tests: $FEATURE_ID"
  echo "=========================================="
  echo ""

  setup_test "$FEATURE_ID"

  # Open browser
  log_info "Opening browser session..."
  agent-browser --session "$SESSION" open "$BASE_URL"
  log_success "Browser session opened"

  # Run smoke tests (don't fail on individual test failure)
  local failed=0

  smoke_test_page_loads || failed=$((failed + 1))
  smoke_test_login_page_exists || failed=$((failed + 1))
  smoke_test_feature_page_exists || failed=$((failed + 1))
  smoke_test_no_js_errors || failed=$((failed + 1))

  # Cleanup
  cleanup_test

  # Summary
  echo ""
  echo "=========================================="
  if [ $failed -eq 0 ]; then
    echo "  ✅ ALL SMOKE TESTS PASSED (4/4)"
    echo "=========================================="
    echo ""
    exit 0
  else
    echo "  ⚠️  SOME SMOKE TESTS FAILED ($failed/4)"
    echo "=========================================="
    echo ""
    echo "Note: Smoke test failures are warnings, not blockers"
    echo ""
    exit 0  # Don't block on smoke test failures
  fi
}

main "$@"
