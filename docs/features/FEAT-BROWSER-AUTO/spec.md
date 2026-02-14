# Feature Specification: Browser Automation Integration

**Feature ID:** FEAT-BROWSER-AUTO
**Feature Name:** Agent-Browser Integration for the feature cycle
**Priority:** P1 (Quality & Automation)
**Created:** 2025-02-02
**Status:** Planning

---

## Overview

Integrate **agent-browser** (Anthropic's browser automation CLI) into the feature cycle's 8-phase cycle to enable automatic frontend verification after implementation.

## Problem Statement

the feature cycle automates backend/logic implementation but has no automated frontend verification. Engineers must manually test UI changes, which:
- Slows down the cycle (manual testing ~15-30 min per feature)
- Introduces human error (missed edge cases)
- No regression detection (old features break silently)
- Can't run in autonomous mode (requires human QA)

## Solution

Add browser automation using **agent-browser** to:
1. Automatically verify frontend changes after implementation
2. Run regression tests on critical flows
3. Generate screenshots/videos for PR review
4. Enable fully autonomous the feature cycle execution

---

## Inspiration Source

### Pattern from top-people Project

```bash
# Example: Authentication test
agent-browser --session "e2e-test" open "http://localhost:3000/login"
agent-browser --session "e2e-test" snapshot -i  # Get element refs
agent-browser --session "e2e-test" fill @e1 "user@example.com"
agent-browser --session "e2e-test" fill @e2 "password123"
agent-browser --session "e2e-test" click @e3  # Login button
agent-browser --session "e2e-test" wait --url "**/dashboard"
```

**Key Features:**
- ✅ CLI-based (perfect for scripts)
- ✅ Session-based (parallel execution)
- ✅ Element refs (@e1, @e2) - language-independent
- ✅ Screenshot/video recording
- ✅ Network inspection
- ✅ Console log capture

**Test Structure (from top-people):**
```
tests/e2e/agent-browser/
├── helpers.sh                     # Reusable functions
├── test-auth.sh                   # Login flow
├── test-preferences-flow.sh       # Full E2E flow
├── test-preferences-smoke.sh      # Smoke tests
└── run-all.sh                     # Runner
```

---

## Integration Points in the feature cycle

### Current 8-Phase Cycle

```
1. INTERVIEW    → spec.md
2. ANALYSIS     → analysis.md
3. PLAN         → design.md + tasks.md
4. BRANCH       → feature/XXX-name
5. IMPLEMENT    → code + commits
6. PR           → gh pr create
7. MERGE        → approval + merge
8. WRAP-UP      → wrap_up.md
```

### Proposed Integration

**Option A: New Phase 5.5 (VERIFY) - Between IMPLEMENT and PR**

```
5. IMPLEMENT    → code + commits
5.5 VERIFY      → browser tests + screenshots  ← NEW
6. PR           → gh pr create (with test results)
7. MERGE        → approval + merge
8. WRAP-UP      → wrap_up.md
```

**Option B: Extend IMPLEMENT Phase (Subtask)**

```
5. IMPLEMENT
   ├── Write code
   ├── Write unit tests
   ├── Commit changes
   └── Run browser tests  ← NEW (if frontend feature)
```

**Recommended:** **Option A (new VERIFY phase)** for these reasons:
- Clear separation of concerns
- Can skip for backend-only features
- Parallel execution possible (implement in branch, verify in worktree)
- Better error reporting (failure in VERIFY != failure in IMPLEMENT)

---

## Technical Decisions

| # | Area | Question | Decision | Notes |
|---|------|----------|----------|-------|
| 1 | Tool | Browser automation framework | agent-browser CLI | Anthropic's official tool |
| 2 | Integration | Where in 8-phase cycle | New Phase 5.5 (VERIFY) | Between IMPLEMENT and PR |
| 3 | Trigger | When to run tests | Auto (if frontend files changed) | Detect tsx/jsx/css changes |
| 4 | Test Definition | How to define tests | Test scripts in feature docs | `docs/features/FEAT-XXX/tests/` |
| 5 | Execution | How to run | Bash/PowerShell scripts | Follow top-people pattern |
| 6 | Reporting | Test results format | Markdown + screenshots | Append to PR description |
| 7 | Failure Handling | If tests fail | Pause the feature cycle, notify | Don't auto-create PR |
| 8 | Parallel Execution | Run tests in parallel | Yes (per feature via sessions) | `--session FEAT-XXX` |
| 9 | Video Recording | Record test execution | Optional (flag in config) | For debugging failures |
| 10 | Regression Tests | Run on all features | Smoke tests only | Full tests only for current feature |

---

## Proposed File Structure

```
docs/features/FEAT-XXX/
├── spec.md
├── analysis.md
├── design.md
├── tasks.md
├── tests/                          ← NEW
│   ├── e2e-flow.sh                 # Main E2E test
│   ├── e2e-smoke.sh                # Smoke tests
│   ├── helpers.sh                  # Test helpers
│   └── test-config.json            # Test configuration
├── test-results/                   ← NEW (generated)
│   ├── screenshots/
│   │   ├── 01-login.png
│   │   ├── 02-create-item.png
│   │   └── 03-verify-list.png
│   ├── videos/
│   │   └── full-flow.webm
│   ├── console-logs.txt
│   ├── network-logs.json
│   └── test-report.md
├── status.md
└── context/
    ├── session_log.md
    ├── decisions.md
    ├── blockers.md
    └── wrap_up.md
```

---

## Test Configuration Schema

```json
{
  "feature_id": "FEAT-XXX-name",
  "base_url": "http://localhost:3000",
  "test_user": {
    "email": "test@example.com",
    "password": "testpassword123"
  },
  "tests": [
    {
      "name": "e2e-flow",
      "script": "./tests/e2e-flow.sh",
      "timeout": 120000,
      "required": true
    },
    {
      "name": "smoke-tests",
      "script": "./tests/e2e-smoke.sh",
      "timeout": 30000,
      "required": false
    }
  ],
  "options": {
    "record_video": false,
    "take_screenshots": true,
    "capture_console": true,
    "capture_network": false
  }
}
```

---

## Integration with the feature execution script

### New Phase: VERIFY

```bash
# Phase 5.5: VERIFY (Browser Tests)
verify_frontend() {
  local FEATURE_ID=$1

  echo "🧪 Phase 5.5: VERIFY - Running browser tests..."

  # Check if frontend files changed
  if ! has_frontend_changes; then
    echo "ℹ️  No frontend changes detected, skipping browser tests"
    return 0
  fi

  # Check if test scripts exist
  if [ ! -d "docs/features/$FEATURE_ID/tests" ]; then
    echo "⚠️  No test scripts found, skipping"
    return 0
  fi

  # Load test configuration
  local CONFIG="docs/features/$FEATURE_ID/tests/test-config.json"
  if [ ! -f "$CONFIG" ]; then
    echo "⚠️  No test configuration found, using defaults"
  fi

  # Create test results directory
  mkdir -p "docs/features/$FEATURE_ID/test-results/screenshots"
  mkdir -p "docs/features/$FEATURE_ID/test-results/videos"

  # Run E2E tests
  local SESSION="test-$FEATURE_ID"

  echo "  Running E2E flow tests..."
  if bash "docs/features/$FEATURE_ID/tests/e2e-flow.sh" --session "$SESSION"; then
    echo "  ✅ E2E tests passed"
  else
    echo "  ❌ E2E tests failed"
    capture_test_failure "$FEATURE_ID" "$SESSION"
    return 1
  fi

  # Run smoke tests (optional)
  if [ -f "docs/features/$FEATURE_ID/tests/e2e-smoke.sh" ]; then
    echo "  Running smoke tests..."
    bash "docs/features/$FEATURE_ID/tests/e2e-smoke.sh" --session "$SESSION" || true
  fi

  # Generate test report
  generate_test_report "$FEATURE_ID"

  # Update status
  echo "| Verify | ✅ Complete | $(date +%Y-%m-%d) | Tests passed |" >> "docs/features/$FEATURE_ID/status.md"

  echo "✅ VERIFY phase complete"
}

# Helper: Check if frontend files changed
has_frontend_changes() {
  git diff --name-only HEAD~5 | grep -E '\.(tsx?|jsx?|css|scss)$' > /dev/null
}

# Helper: Capture test failure
capture_test_failure() {
  local FEATURE_ID=$1
  local SESSION=$2

  echo "📸 Capturing failure state..."

  # Take screenshot
  agent-browser --session "$SESSION" screenshot \
    "docs/features/$FEATURE_ID/test-results/screenshots/failure.png"

  # Get console logs
  agent-browser --session "$SESSION" get console > \
    "docs/features/$FEATURE_ID/test-results/console-logs.txt"

  # Get network logs
  agent-browser --session "$SESSION" get network > \
    "docs/features/$FEATURE_ID/test-results/network-logs.json"

  echo "💾 Failure state saved to test-results/"
}

# Helper: Generate test report
generate_test_report() {
  local FEATURE_ID=$1
  local REPORT="docs/features/$FEATURE_ID/test-results/test-report.md"

  cat > "$REPORT" <<EOF
# Test Report: $FEATURE_ID

**Date:** $(date +%Y-%m-%d\ %H:%M:%S)
**Status:** ✅ PASSED

## Tests Executed

- ✅ E2E Flow Test
- ✅ Smoke Tests

## Screenshots

$(ls docs/features/$FEATURE_ID/test-results/screenshots/*.png 2>/dev/null | \
  xargs -I {} basename {} | \
  sed 's/^/- /')

## Console Logs

\`\`\`
$(cat docs/features/$FEATURE_ID/test-results/console-logs.txt 2>/dev/null | head -20)
\`\`\`

## Network Activity

$(cat docs/features/$FEATURE_ID/test-results/network-logs.json 2>/dev/null | head -10)
EOF

  echo "📄 Test report generated: $REPORT"
}
```

---

## Test Script Template

### docs/features/FEAT-XXX/tests/e2e-flow.sh

```bash
#!/bin/bash
# E2E Test: FEAT-XXX Flow
# Tests the main user flow for this feature

set -e

# Configuration
FEATURE_ID="FEAT-XXX"
BASE_URL="${BASE_URL:-http://localhost:3000}"
TEST_EMAIL="${TEST_EMAIL:-test@example.com}"
TEST_PASSWORD="${TEST_PASSWORD:-testpassword123}"
SESSION="${SESSION:-test-$FEATURE_ID}"

# Helper functions
source "$(dirname "$0")/helpers.sh"

# Test: Main flow
test_main_flow() {
  echo "🧪 Testing main flow..."

  # 1. Login
  agent-browser --session "$SESSION" open "$BASE_URL/login"
  agent-browser --session "$SESSION" wait --load networkidle

  agent-browser --session "$SESSION" fill @e1 "$TEST_EMAIL"
  agent-browser --session "$SESSION" fill @e2 "$TEST_PASSWORD"
  agent-browser --session "$SESSION" click @e3

  agent-browser --session "$SESSION" wait --url "**/dashboard" --timeout 10000
  screenshot "01-logged-in"

  # 2. Navigate to feature
  agent-browser --session "$SESSION" goto "$BASE_URL/feature-page"
  agent-browser --session "$SESSION" wait --load networkidle
  screenshot "02-feature-page"

  # 3. Interact with UI
  agent-browser --session "$SESSION" click "button:has-text('Create')"
  agent-browser --session "$SESSION" wait 1000
  screenshot "03-create-dialog"

  # 4. Fill form
  agent-browser --session "$SESSION" fill "input[name='title']" "Test Item"
  agent-browser --session "$SESSION" fill "textarea" "Test description"
  screenshot "04-filled-form"

  # 5. Submit
  agent-browser --session "$SESSION" click "button:has-text('Save')"
  agent-browser --session "$SESSION" wait 2000
  screenshot "05-item-created"

  # 6. Verify
  agent-browser --session "$SESSION" get text | grep -q "Test Item"
  if [ $? -eq 0 ]; then
    echo "✅ Main flow test passed"
    return 0
  else
    echo "❌ Main flow test failed: Item not found"
    return 1
  fi
}

# Run test
main() {
  echo "=========================================="
  echo "E2E Test: $FEATURE_ID"
  echo "=========================================="

  test_main_flow

  echo ""
  echo "=========================================="
  echo "✅ All tests passed!"
  echo "=========================================="
}

main "$@"
```

---

## Benefits

### For the feature cycle
1. **Autonomous QA** - Can verify frontend changes without human
2. **Regression Detection** - Catches UI breaks early
3. **PR Evidence** - Screenshots in PR show what changed
4. **Faster Cycles** - No manual testing delay
5. **Confidence** - Tests pass = safe to merge

### For Engineers
1. **Less Manual Testing** - Automation handles repetitive checks
2. **Visual Feedback** - Screenshots show actual UI state
3. **Debug Info** - Console logs + network logs on failure
4. **Standardized** - Same test pattern across features

### For Projects
1. **Quality Gates** - No untested code reaches PR
2. **Documentation** - Test scripts document expected behavior
3. **Onboarding** - New devs see how features should work
4. **Metrics** - Track test coverage per feature

---

## Success Criteria

- ✅ agent-browser installed and configured
- ✅ Test template scripts created
- ✅ VERIFY phase integrated into the feature execution script
- ✅ Test results appear in PR descriptions
- ✅ Failed tests prevent PR creation
- ✅ Screenshots captured automatically
- ✅ Works for both Bash and PowerShell
- ✅ Documentation updated with examples

---

## Non-Goals

- ❌ Unit test automation (use Jest/Pytest instead)
- ❌ API testing (use Postman/curl/httpie)
- ❌ Performance testing (use Lighthouse/WebPageTest)
- ❌ Visual regression (use Percy/Chromatic)
- ❌ Cross-browser testing (use BrowserStack/Sauce Labs)

---

## Open Questions

1. **How to handle localhost dependency?**
   - Option A: Require services running locally
   - Option B: Spin up Docker containers automatically
   - Option C: Use remote staging environment
   - **Recommendation:** Start with A (simplest), add B later

2. **What if no test scripts exist?**
   - Option A: Skip VERIFY phase silently
   - Option B: Generate basic smoke test template
   - Option C: Fail and require tests
   - **Recommendation:** A (graceful degradation)

3. **How to handle test flakiness?**
   - Option A: Retry failed tests (up to 3x)
   - Option B: Mark as flaky, don't block
   - Option C: Require stable tests only
   - **Recommendation:** A (retry with exponential backoff)

---

## Next Steps

1. **Install agent-browser** in development environment
2. **Create test template** based on top-people pattern
3. **Implement VERIFY phase** in the feature execution script
4. **Test with FEAT-023** (existing e2e tests from top-people)
5. **Document** usage in the feature cycle guide
6. **Iterate** based on real usage

---

**References:**
- top-people e2e tests: `D:\top-people\tests\e2e\agent-browser\`
- agent-browser docs: https://github.com/anthropics/agent-browser
- Playwright comparison: https://playwright.dev/
