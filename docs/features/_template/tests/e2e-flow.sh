#!/bin/bash
###############################################################################
# E2E Test: FEAT-XXX Main Flow
# Tests the complete user journey for this feature
###############################################################################

set -e

# Get script directory for relative imports
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load helpers
source "$SCRIPT_DIR/helpers.sh"

# Load configuration from test-config.json if available
if [ -f "$SCRIPT_DIR/test-config.json" ]; then
  log_info "Loading test configuration..."

  # Extract values using grep/sed (simple JSON parsing)
  FEATURE_ID=$(grep -o '"feature_id"[^,}]*' "$SCRIPT_DIR/test-config.json" | sed 's/"feature_id"[^"]*"\([^"]*\)".*/\1/')
  TEST_EMAIL=$(grep -o '"email"[^,}]*' "$SCRIPT_DIR/test-config.json" | sed 's/"email"[^"]*"\([^"]*\)".*/\1/' | head -1)
  TEST_PASSWORD=$(grep -o '"password"[^,}]*' "$SCRIPT_DIR/test-config.json" | sed 's/"password"[^"]*"\([^"]*\)".*/\1/' | head -1)

  log_success "Configuration loaded"
fi

# Override from environment if set
FEATURE_ID="${FEATURE_ID:-FEAT-XXX}"
BASE_URL="${BASE_URL:-http://localhost:3000}"
TEST_EMAIL="${TEST_EMAIL:-feat-xxx-test@example.com}"
TEST_PASSWORD="${TEST_PASSWORD:-test-feat-xxx-password}"
SESSION="${SESSION:-ralph-$FEATURE_ID}"
RESULTS_DIR="$SCRIPT_DIR/../test-results"

###############################################################################
# Test Functions
###############################################################################

test_user_login() {
  log_info "Test: User Login"

  # Navigate to login page
  goto_page "/login"
  screenshot "step-01-login-page"

  # Fill credentials
  fill_field "input[type='email']" "$TEST_EMAIL"
  fill_field "input[type='password']" "$TEST_PASSWORD"
  screenshot "step-02-credentials-filled"

  # Submit login
  click_button "button[type='submit']"

  # Wait for redirect to dashboard
  wait_for_url "**/dashboard"
  screenshot "step-03-logged-in"

  # Verify login success
  assert_text_present "Dashboard" || assert_text_present "Welcome"

  log_success "User Login: PASSED"
}

test_feature_navigation() {
  log_info "Test: Feature Navigation"

  # Navigate to feature page
  goto_page "/feature-page"  # Replace with actual feature URL
  screenshot "step-04-feature-page"

  # Verify feature page loaded
  assert_url_contains "/feature-page"
  assert_text_present "Feature Name"  # Replace with actual page title

  log_success "Feature Navigation: PASSED"
}

test_feature_interaction() {
  log_info "Test: Feature Interaction"

  # Click create/add button
  click_button "button:has-text('Create'), button:has-text('Add')"
  screenshot "step-05-create-dialog"

  # Wait for dialog/form to appear
  agent-browser --session "$SESSION" wait 1000

  # Fill form fields
  fill_field "input[name='title']" "Test Item"
  fill_field "textarea" "Test description for automated E2E test"
  screenshot "step-06-form-filled"

  # Submit form
  click_button "button:has-text('Save'), button:has-text('Submit')"

  # Wait for save to complete
  agent-browser --session "$SESSION" wait 2000
  screenshot "step-07-item-created"

  # Verify item appears in list
  assert_text_present "Test Item"

  log_success "Feature Interaction: PASSED"
}

test_feature_verification() {
  log_info "Test: Feature Verification"

  # Refresh page to ensure data persisted
  goto_page "/feature-page"
  screenshot "step-08-page-refreshed"

  # Verify item still appears
  assert_text_present "Test Item"

  log_success "Feature Verification: PASSED"
}

###############################################################################
# Main Test Execution
###############################################################################

main() {
  echo ""
  echo "=========================================="
  echo "  E2E Test: $FEATURE_ID"
  echo "=========================================="
  echo ""
  echo "Configuration:"
  echo "  Feature ID: $FEATURE_ID"
  echo "  Base URL:   $BASE_URL"
  echo "  Test Email: $TEST_EMAIL"
  echo "  Session:    $SESSION"
  echo ""

  # Setup
  setup_test "$FEATURE_ID"

  # Open browser session
  log_info "Opening browser session..."
  agent-browser --session "$SESSION" open "$BASE_URL"
  log_success "Browser session opened"

  # Run tests
  local test_failed=0

  # Test 1: Login
  if ! test_user_login; then
    test_failed=1
    on_test_failure "user_login"
  fi

  # Test 2: Navigation (only if login passed)
  if [ $test_failed -eq 0 ]; then
    if ! test_feature_navigation; then
      test_failed=1
      on_test_failure "feature_navigation"
    fi
  fi

  # Test 3: Interaction (only if navigation passed)
  if [ $test_failed -eq 0 ]; then
    if ! test_feature_interaction; then
      test_failed=1
      on_test_failure "feature_interaction"
    fi
  fi

  # Test 4: Verification (only if interaction passed)
  if [ $test_failed -eq 0 ]; then
    if ! test_feature_verification; then
      test_failed=1
      on_test_failure "feature_verification"
    fi
  fi

  # Cleanup
  capture_console_logs
  capture_network_logs
  cleanup_test

  # Generate report
  if [ $test_failed -eq 0 ]; then
    generate_test_report "PASSED" "E2E Flow Test"
  else
    generate_test_report "FAILED" "E2E Flow Test"
  fi

  # Summary
  echo ""
  echo "=========================================="
  if [ $test_failed -eq 0 ]; then
    echo "  ✅ ALL TESTS PASSED"
    echo "=========================================="
    echo ""
    exit 0
  else
    echo "  ❌ TESTS FAILED"
    echo "=========================================="
    echo ""
    echo "Review failure details:"
    echo "  - Screenshots: $RESULTS_DIR/screenshots/"
    echo "  - Console logs: $RESULTS_DIR/console-logs.txt"
    echo "  - Network logs: $RESULTS_DIR/network-logs.json"
    echo "  - Test report: $RESULTS_DIR/test-report.md"
    echo ""
    exit 1
  fi
}

# Run main with error handling
if main "$@"; then
  exit 0
else
  log_error "Test execution failed"
  exit 1
fi
