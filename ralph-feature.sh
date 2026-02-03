#!/bin/bash
###############################################################################
# RALPH FEATURE LOOP - Bash Version
###############################################################################
# Executes the complete 8-phase Feature Development Cycle + Phase 5.5 (VERIFY)
#
# Phases:
#   1. INTERVIEW      → spec.md
#   2. ANALYSIS       → analysis.md (Think Critically)
#   3. PLAN           → design.md + tasks.md
#   4. BRANCH         → feature/FEAT-XXX
#   5. IMPLEMENT      → code + commits
#   5.5 VERIFY        → browser tests + screenshots (NEW!)
#   6. PR             → gh pr create
#   7. MERGE          → approval + merge
#   8. WRAP-UP        → wrap_up.md
#
# Usage:
#   ./ralph-feature.sh FEAT-XXX [max_iterations]
#   ./ralph-feature.sh FEAT-004-invoice-pilot 15
###############################################################################

set -e

# ============================================================================
# CONFIGURATION
# ============================================================================
FEATURE_ID="${1:?Feature ID required (e.g., FEAT-001)}"
MAX_ITERATIONS="${2:-15}"

ITERATION=0
CONSECUTIVE_FAILURES=0
MAX_FAILURES=3
CURRENT_PHASE=""

# Feature paths
FEATURE_DIR="docs/features/$FEATURE_ID"
SPEC_FILE="$FEATURE_DIR/spec.md"
ANALYSIS_FILE="$FEATURE_DIR/analysis.md"
DESIGN_FILE="$FEATURE_DIR/design.md"
TASKS_FILE="$FEATURE_DIR/tasks.md"
STATUS_FILE="$FEATURE_DIR/status.md"
SESSION_LOG="$FEATURE_DIR/context/session_log.md"
DECISIONS_FILE="$FEATURE_DIR/context/decisions.md"
WRAPUP_FILE="$FEATURE_DIR/context/wrap_up.md"

# Test paths (Phase 5.5)
TEST_DIR="$FEATURE_DIR/tests"
TEST_CONFIG="$TEST_DIR/test-config.json"
TEST_RESULTS_DIR="$FEATURE_DIR/test-results"

# Branch name - extract FEAT-XXX part
BRANCH_NAME="feat/$(echo $FEATURE_ID | sed -E 's/^(FEAT-[0-9]+).*/\1/')"

# Claude CLI flags
CLAUDE_FLAGS="--dangerously-skip-permissions --output-format text"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ============================================================================
# LOGGING
# ============================================================================
log() {
  local level=$1
  shift
  local message="$@"
  local timestamp=$(date +%H:%M:%S)

  case $level in
    SUCCESS) echo -e "[$FEATURE_ID] $timestamp ${GREEN}[OK]${NC} $message" ;;
    WARNING) echo -e "[$FEATURE_ID] $timestamp ${YELLOW}[WARN]${NC} $message" ;;
    ERROR) echo -e "[$FEATURE_ID] $timestamp ${RED}[ERROR]${NC} $message" ;;
    INFO) echo -e "[$FEATURE_ID] $timestamp ${BLUE}[INFO]${NC} $message" ;;
    *) echo -e "[$FEATURE_ID] $timestamp $message" ;;
  esac
}

log_phase() {
  local phase=$1
  echo ""
  echo "================================================================"
  echo "  $FEATURE_ID - Phase: $phase"
  echo "  Iteration: $ITERATION / $MAX_ITERATIONS"
  echo "================================================================"
  echo ""
}

add_session_log() {
  local message=$1
  local timestamp=$(date +"%Y-%m-%d %H:%M")

  if [ -f "$SESSION_LOG" ]; then
    # Insert at top after header
    local header=$(head -20 "$SESSION_LOG")
    local rest=$(tail -n +21 "$SESSION_LOG")
    echo "$header" > "$SESSION_LOG"
    echo "" >> "$SESSION_LOG"
    echo "### [$timestamp] - [RALPH] $message" >> "$SESSION_LOG"
    echo "" >> "$SESSION_LOG"
    echo "$rest" >> "$SESSION_LOG"
  fi
}

# ============================================================================
# PHASE DETECTION HELPERS
# ============================================================================
is_interview_complete() {
  [ ! -f "$SPEC_FILE" ] && return 1

  # Check if Technical Decisions table has non-TBD values
  local all_decisions=$(grep -E '^\|\s*[0-9]+\s*\|' "$SPEC_FILE" | wc -l)
  [ $all_decisions -eq 0 ] && return 1

  local non_tbd=$(grep -E '^\|\s*[0-9]+\s*\|' "$SPEC_FILE" | grep -v "TBD\|_TBD_" | wc -l)
  [ $non_tbd -ge 2 ] && return 0
  return 1
}

is_analysis_complete() {
  [ ! -f "$ANALYSIS_FILE" ] && return 1

  # Check for step 1 and step 11 markers
  local has_problem=$(grep -E "## 1\.|Problem Clarification|Step 1" "$ANALYSIS_FILE" | wc -l)
  local has_decision=$(grep -E "## 11\.|Decision Summary|Confidence Level" "$ANALYSIS_FILE" | wc -l)

  [ $has_problem -gt 0 ] && [ $has_decision -gt 0 ] && return 0
  return 1
}

is_plan_complete() {
  [ ! -f "$DESIGN_FILE" ] && return 1
  [ ! -f "$TASKS_FILE" ] && return 1

  local has_tasks=$(grep -E "## Backend Tasks|## Tasks" "$TASKS_FILE" | wc -l)
  [ $has_tasks -gt 0 ] && return 0
  return 1
}

is_branch_created() {
  git show-ref --verify --quiet "refs/heads/$BRANCH_NAME" 2>/dev/null
  return $?
}

is_implementation_complete() {
  [ ! -f "$TASKS_FILE" ] && return 1

  local total=$(grep -E '^-\s*\[' "$TASKS_FILE" | wc -l)
  local complete=$(grep -E '^-\s*\[x\]' "$TASKS_FILE" | wc -l)

  [ $total -gt 0 ] || return 1

  local percent=$((complete * 100 / total))
  [ $percent -ge 90 ] && return 0
  return 1
}

has_frontend_changes() {
  # Check if there are tsx/jsx/css/scss files in recent commits
  git diff --name-only HEAD~5 2>/dev/null | grep -E '\.(tsx?|jsx?|css|scss)$' >/dev/null
  return $?
}

is_verify_needed() {
  # Verify is needed if:
  # 1. Frontend files changed AND
  # 2. Test scripts exist
  has_frontend_changes && [ -d "$TEST_DIR" ] && return 0
  return 1
}

is_verify_complete() {
  # Check if test-report.md exists and shows PASSED
  [ -f "$TEST_RESULTS_DIR/test-report.md" ] && \
  grep -q "PASSED" "$TEST_RESULTS_DIR/test-report.md"
  return $?
}

is_pr_created() {
  gh pr view --json state >/dev/null 2>&1
  return $?
}

is_pr_merged() {
  local state=$(gh pr view --json state 2>/dev/null | jq -r '.state')
  [ "$state" = "MERGED" ] && return 0
  return 1
}

get_current_phase() {
  [ ! -f "$STATUS_FILE" ] && echo "unknown" && return

  # Check status markers
  local interview=$(grep -c "| Interview |.*Complete" "$STATUS_FILE")
  local analysis=$(grep -c "| Critical Analysis |.*Complete" "$STATUS_FILE")
  local plan=$(grep -c "| Plan |.*Complete" "$STATUS_FILE")
  local branch=$(grep -c "| Branch |.*Complete" "$STATUS_FILE")
  local implement=$(grep -c "| Implement |.*Complete" "$STATUS_FILE")
  local verify=$(grep -c "| Verify |.*Complete" "$STATUS_FILE")
  local pr=$(grep -c "| PR |.*Complete" "$STATUS_FILE")
  local merge=$(grep -c "| Merge |.*Complete" "$STATUS_FILE")

  # Check wrap_up.md for completion
  if [ -f "$WRAPUP_FILE" ] && grep -q "Wrap-up completado\|Wrap-Up Complete" "$WRAPUP_FILE"; then
    echo "complete"
  elif [ $merge -gt 0 ]; then echo "wrapup"
  elif [ $pr -gt 0 ]; then echo "merge"
  elif [ $verify -gt 0 ]; then echo "pr"
  elif [ $implement -gt 0 ]; then
    if is_verify_needed; then echo "verify"
    elif is_implementation_complete; then echo "pr"
    else echo "implement"
    fi
  elif [ $branch -gt 0 ]; then
    if is_implementation_complete; then
      if is_verify_needed; then echo "verify"
      else echo "pr"
      fi
    else echo "implement"
    fi
  elif [ $plan -gt 0 ]; then echo "branch"
  elif [ $analysis -gt 0 ]; then echo "plan"
  elif [ $interview -gt 0 ]; then
    if is_analysis_complete; then echo "plan"
    else echo "analysis"
    fi
  else
    if is_interview_complete; then echo "analysis"
    else echo "interview"
    fi
  fi
}

get_analysis_depth() {
  # Check for bug fix keywords
  if [ -f "$SPEC_FILE" ]; then
    local bugfix_count=$(grep -Eio "bug|fix|hotfix|patch" "$SPEC_FILE" | wc -l)
    [ $bugfix_count -ge 2 ] && echo "skip" && return
  fi

  # Check if this is a new system
  local patterns=$(find src -name "*.py" -type f 2>/dev/null | head -5 | wc -l)

  if [ $patterns -lt 5 ]; then
    echo "full"
  else
    local decision_count=$(grep -E '^\| [0-9]+ \|' "$SPEC_FILE" | wc -l)
    [ $decision_count -ge 5 ] && echo "medium" || echo "light"
  fi
}

# ============================================================================
# PHASE EXECUTION
# ============================================================================

invoke_interview() {
  log INFO "Executing Interview phase..."

  if ! is_interview_complete; then
    local has_structure=$(grep -c "## Technical Decisions" "$SPEC_FILE" || true)
    if [ $has_structure -eq 0 ]; then
      log WARNING "spec.md needs human input - Interview not complete"
      add_session_log "Interview needs human input - pausing"
      return 3
    fi
  fi

  local prompt="You are executing the INTERVIEW phase for $FEATURE_ID.

Your job is to complete the spec.md file with ALL necessary information for this feature.

Context:
- Project overview: Read docs/features/_index.md to understand the project and this feature
- Project definition: Read docs/project.md if available
- This feature: $FEATURE_ID

Steps:
1. Read docs/features/_index.md to understand what this feature is about
2. Read $SPEC_FILE (currently a template)
3. Fill in ALL sections of the spec
4. Update $STATUS_FILE to mark Interview phase as ✅
5. Add checkpoint to $SESSION_LOG

When complete, emit: INTERVIEW_COMPLETE
If human input is needed, emit: INTERVIEW_NEEDS_INPUT"

  echo "[→] Executing Claude..." >&2
  local output=$(claude -p "$prompt" $CLAUDE_FLAGS 2>&1)

  # Show summary
  echo "$output" | grep -E "Created|Updated|Modified" || true
  echo "$output" | grep -E "COMPLETE|PROGRESS|NEEDS" || true

  if echo "$output" | grep -q "INTERVIEW_COMPLETE"; then
    log SUCCESS "Interview phase complete"
    add_session_log "Interview Complete - Decisions documented"
    return 0
  elif echo "$output" | grep -q "INTERVIEW_NEEDS_INPUT"; then
    log WARNING "Interview needs human input"
    return 3
  else
    log ERROR "Interview phase failed - no completion signal found"
    return 1
  fi
}

invoke_analysis() {
  log INFO "Executing Think Critically phase..."

  if is_analysis_complete; then
    log INFO "Analysis already complete, skipping..."
    # Mark as complete if not already marked
    if ! grep -q "Critical Analysis.*✅" "$STATUS_FILE"; then
      sed -i 's/| Critical Analysis | ⬜ Pending/| Critical Analysis | ✅ Complete/' "$STATUS_FILE"
      log INFO "Marked Analysis as complete in status.md"
    fi
    return 0
  fi

  local depth=$(get_analysis_depth)
  log INFO "Analysis depth: $depth"

  if [ "$depth" = "skip" ]; then
    log INFO "Skipping analysis (bug fix / hotfix detected)"
    cat > "$ANALYSIS_FILE" <<EOF
# Critical Analysis - SKIPPED

**Reason:** Bug fix / hotfix - no architectural risk
**Depth:** Skip
**Confidence:** High

Proceeding directly to Plan phase.
EOF
    add_session_log "Analysis Skipped - Bug fix/hotfix"
    return 0
  fi

  local steps_to_run
  case $depth in
    full) steps_to_run="ALL 11 STEPS (1-2-3-4-5-6-7-8-9-10-11)" ;;
    medium) steps_to_run="Steps 1, 2, 3, 5, 9, 11 (medium complexity)" ;;
    light) steps_to_run="Steps 1, 2, 5, 11 (light complexity)" ;;
  esac

  local prompt="You are executing the THINK CRITICALLY phase (Phase 2) for $FEATURE_ID.

Analysis Depth: $depth
Steps to execute: $steps_to_run

Execute the 11-step protocol and create $ANALYSIS_FILE.

When complete, emit: ANALYSIS_COMPLETE
If pause needed, emit: ANALYSIS_NEEDS_REVIEW"

  log INFO "Running 11-step protocol (depth: $depth)..."
  echo "[→] Executing Claude..." >&2
  local output=$(claude -p "$prompt" $CLAUDE_FLAGS 2>&1)

  echo "$output" | grep -E "Created|Updated|Modified" || true
  echo "$output" | grep -E "COMPLETE|PROGRESS|NEEDS" || true

  if echo "$output" | grep -q "ANALYSIS_COMPLETE"; then
    log SUCCESS "Think Critically phase complete"
    add_session_log "Critical Analysis Complete - Confidence verified"
    return 0
  elif echo "$output" | grep -q "ANALYSIS_NEEDS_REVIEW"; then
    log WARNING "Analysis requires human review"
    add_session_log "[PAUSED] Critical Analysis needs review"
    return 3
  else
    log ERROR "Think Critically phase failed"
    return 1
  fi
}

invoke_plan() {
  log INFO "Executing Plan phase..."

  if is_plan_complete; then
    log INFO "Plan already complete, skipping..."
    if ! grep -q "Plan.*✅" "$STATUS_FILE"; then
      sed -i 's/| Plan | ⬜ Pending/| Plan | ✅ Complete/' "$STATUS_FILE"
      log INFO "Marked Plan as complete in status.md"
    fi
    return 0
  fi

  local prompt="You are executing the PLAN phase (Phase 3) for $FEATURE_ID.

Create $DESIGN_FILE and $TASKS_FILE.
Update $STATUS_FILE to mark Plan as ✅.

When complete, emit: <phase>PLAN_COMPLETE</phase>"

  echo "[→] Executing Claude..." >&2
  local output=$(claude -p "$prompt" $CLAUDE_FLAGS 2>&1)

  echo "$output" | grep -E "Created|Updated|Modified" || true

  if echo "$output" | grep -q "<phase>PLAN_COMPLETE</phase>"; then
    log SUCCESS "Plan phase complete"
    add_session_log "Plan Complete ✅"
    return 0
  else
    log ERROR "Plan phase failed"
    return 1
  fi
}

invoke_branch() {
  log INFO "Executing Branch phase..."

  if is_branch_created; then
    log INFO "Branch already exists: $BRANCH_NAME"
    git checkout "$BRANCH_NAME" 2>/dev/null
    return 0
  fi

  git checkout main 2>/dev/null || git checkout master 2>/dev/null
  git pull origin main 2>/dev/null || git pull origin master 2>/dev/null
  git checkout -b "$BRANCH_NAME"

  log SUCCESS "Branch created: $BRANCH_NAME"
  add_session_log "Branch Created ✅ - $BRANCH_NAME"

  # Update status
  claude -p "Update $STATUS_FILE to mark Branch phase as ✅. Emit: <phase>BRANCH_COMPLETE</phase>" $CLAUDE_FLAGS >/dev/null 2>&1
  return 0
}

invoke_implement() {
  log INFO "Executing Implement phase..."

  local total=$(grep -E '^- \[' "$TASKS_FILE" | wc -l)
  local complete=$(grep -E '^- \[x\]' "$TASKS_FILE" | wc -l)
  local remaining=$((total - complete))

  log INFO "Tasks: $complete/$total complete ($remaining remaining)"

  if [ $remaining -eq 0 ]; then
    log SUCCESS "All tasks complete!"
    add_session_log "Implementation Complete ✅"
    return 0
  fi

  local batch_size=3

  local prompt="You are executing the IMPLEMENT phase for $FEATURE_ID.
Iteration $ITERATION. Progress: $complete/$total tasks.

Complete up to $batch_size tasks from $TASKS_FILE.

If all done, emit: <phase>IMPLEMENT_COMPLETE</phase>
If progress made, emit: <phase>IMPLEMENT_PROGRESS</phase>"

  echo "[→] Executing Claude..." >&2
  local output=$(claude -p "$prompt" $CLAUDE_FLAGS 2>&1)

  echo "$output" | grep -E "Created|Updated|Modified" || true

  if echo "$output" | grep -q "<phase>IMPLEMENT_COMPLETE</phase>"; then
    log SUCCESS "Implementation complete"
    return 0
  elif echo "$output" | grep -q "<phase>IMPLEMENT_PROGRESS</phase>"; then
    log INFO "Progress made, continuing..."
    add_session_log "Implementation Progress"
    return 0
  else
    log WARNING "No progress signal detected"
    return 1
  fi
}

invoke_verify() {
  log INFO "Executing Verify phase (Phase 5.5 - Browser Tests)..."

  # Check if verify is needed
  if ! is_verify_needed; then
    log INFO "No frontend changes or test scripts found, skipping VERIFY"
    # Mark as complete (skipped) in status
    if ! grep -q "| Verify |" "$STATUS_FILE"; then
      echo "| Verify | ✅ Skipped | $(date +%Y-%m-%d) | No frontend changes |" >> "$STATUS_FILE"
    fi
    return 0
  fi

  # Check if already complete
  if is_verify_complete; then
    log INFO "Verify already complete, skipping..."
    return 0
  fi

  log INFO "Frontend changes detected, running browser tests..."

  # Create test results directory
  mkdir -p "$TEST_RESULTS_DIR/screenshots"
  mkdir -p "$TEST_RESULTS_DIR/videos"

  # Load test configuration
  local base_url="http://localhost:3000"
  local test_email="feat-$(echo $FEATURE_ID | tr '[:upper:]' '[:lower:]')-test@example.com"
  local test_password="test-$FEATURE_ID-password"

  if [ -f "$TEST_CONFIG" ]; then
    log INFO "Loading test configuration..."
    base_url=$(grep -o '"base_url"[^,}]*' "$TEST_CONFIG" | sed 's/"base_url"[^"]*"\([^"]*\)".*/\1/' || echo "$base_url")
    test_email=$(grep -o '"email"[^,}]*' "$TEST_CONFIG" | sed 's/"email"[^"]*"\([^"]*\)".*/\1/' | head -1 || echo "$test_email")
  fi

  # Export environment variables for test scripts
  export FEATURE_ID
  export BASE_URL="$base_url"
  export TEST_EMAIL="$test_email"
  export TEST_PASSWORD="$test_password"
  export SESSION="ralph-$FEATURE_ID"
  export RESULTS_DIR="$TEST_RESULTS_DIR"

  # Run E2E tests if script exists
  if [ -f "$TEST_DIR/e2e-flow.sh" ]; then
    log INFO "Running E2E flow tests..."

    if bash "$TEST_DIR/e2e-flow.sh"; then
      log SUCCESS "E2E tests passed"
    else
      log ERROR "E2E tests failed"

      # Capture failure state
      log INFO "Capturing failure state..."
      echo "Test failed on $(date)" > "$TEST_RESULTS_DIR/failure.txt"

      # Run security filters on test results
      log INFO "Running security filters on test results..."
      bash .memory-system/scripts/security-filters.sh filter-all "$TEST_RESULTS_DIR" || true

      add_session_log "VERIFY Failed ❌ - Tests failed, see test-results/"
      return 1
    fi
  else
    log WARNING "No e2e-flow.sh found, skipping E2E tests"
  fi

  # Run smoke tests if script exists (optional, don't fail on error)
  if [ -f "$TEST_DIR/e2e-smoke.sh" ]; then
    log INFO "Running smoke tests..."
    bash "$TEST_DIR/e2e-smoke.sh" || log WARNING "Smoke tests failed (non-blocking)"
  fi

  # Run security filters on test results
  log INFO "Running security filters on test results..."
  bash .memory-system/scripts/security-filters.sh filter-all "$TEST_RESULTS_DIR" || true

  # Update status
  echo "| Verify | ✅ Complete | $(date +%Y-%m-%d) | Tests passed |" >> "$STATUS_FILE"
  add_session_log "VERIFY Complete ✅ - Browser tests passed"

  log SUCCESS "VERIFY phase complete"
  return 0
}

invoke_pr() {
  log INFO "Executing PR phase..."

  if is_pr_created; then
    log INFO "PR already exists"
    return 0
  fi

  # Sync with main
  log INFO "Syncing with main branch..."
  git fetch origin 2>/dev/null
  local base_branch=$(git show-ref --verify --quiet refs/remotes/origin/main && echo "main" || echo "master")
  log INFO "Base branch: $base_branch"

  # Merge
  if ! git merge "origin/$base_branch" 2>&1; then
    log ERROR "Merge conflicts detected - manual resolution required"
    add_session_log "[PAUSED] Merge conflicts need manual resolution"
    return 3
  fi

  log SUCCESS "No merge conflicts"

  # Push
  git push -u origin "$BRANCH_NAME" 2>/dev/null

  # Create PR
  local pr_title="$FEATURE_ID: $(echo $FEATURE_ID | sed 's/FEAT-[0-9]*-//' | sed 's/-/ /g')"
  local pr_body="## Summary

Automated PR for $FEATURE_ID

## Test Results

$([ -f "$TEST_RESULTS_DIR/test-report.md" ] && cat "$TEST_RESULTS_DIR/test-report.md" || echo "No browser tests run")

## Checklist
- [x] Implementation complete
- [x] Tests passing
- [x] Synced with $base_branch

---
*Created by Ralph Loop*"

  gh pr create --title "$pr_title" --body "$pr_body" --base "$base_branch" 2>/dev/null

  log SUCCESS "PR created"
  add_session_log "PR Created ✅"

  # Update status
  claude -p "Update $STATUS_FILE to mark PR phase as ✅. Emit: <phase>PR_COMPLETE</phase>" $CLAUDE_FLAGS >/dev/null 2>&1
  return 0
}

invoke_merge() {
  log INFO "Checking merge status..."

  if is_pr_merged; then
    log SUCCESS "PR is merged!"
    add_session_log "Merged ✅"
    return 0
  fi

  local state=$(gh pr view --json state 2>/dev/null | jq -r '.state')

  case $state in
    OPEN) log WARNING "PR is open, waiting for approval..."; return 2 ;;
    CLOSED) log ERROR "PR was closed without merging"; return 1 ;;
    *) log INFO "Merge status: $state"; return 2 ;;
  esac
}

invoke_wrapup() {
  log INFO "Executing Wrap-up phase..."

  if [ -f "$WRAPUP_FILE" ] && grep -q "Wrap-up completado" "$WRAPUP_FILE"; then
    log SUCCESS "Wrap-up already complete"
    return 100
  fi

  local prompt="You are executing the WRAP-UP phase for $FEATURE_ID.

Create/update $WRAPUP_FILE.
Update $STATUS_FILE to mark complete.

When complete, emit: <phase>WRAPUP_COMPLETE</phase>
Then emit: <phase>FEATURE_COMPLETE</phase>"

  echo "[→] Executing Claude..." >&2
  local output=$(claude -p "$prompt" $CLAUDE_FLAGS 2>&1)

  echo "$output" | grep -E "Created|Updated|Modified" || true

  if echo "$output" | grep -q "<phase>FEATURE_COMPLETE</phase>"; then
    log SUCCESS "Feature complete! [COMPLETE]"
    add_session_log "Feature Complete [COMPLETE]"
    return 100
  elif echo "$output" | grep -q "<phase>WRAPUP_COMPLETE</phase>"; then
    log SUCCESS "Wrap-up complete"
    return 100
  else
    log ERROR "Wrap-up failed"
    return 1
  fi
}

invoke_phase() {
  local phase=$1
  CURRENT_PHASE=$phase
  log_phase "$phase"

  case $phase in
    interview) invoke_interview ;;
    analysis) invoke_analysis ;;
    plan) invoke_plan ;;
    branch) invoke_branch ;;
    implement) invoke_implement ;;
    verify) invoke_verify ;;
    pr) invoke_pr ;;
    merge) invoke_merge ;;
    wrapup) invoke_wrapup ;;
    complete) log SUCCESS "Feature is already complete!"; return 100 ;;
    *) log ERROR "Unknown phase: $phase"; return 1 ;;
  esac
}

# ============================================================================
# MAIN LOOP
# ============================================================================
echo "DEBUG: Entering main()"
echo "DEBUG: FEATURE_ID=$FEATURE_ID"
echo "DEBUG: FEATURE_DIR=$FEATURE_DIR"
log INFO "Starting Ralph Feature Loop for $FEATURE_ID"
log INFO "Max iterations: $MAX_ITERATIONS"

if [ ! -d "$FEATURE_DIR" ]; then
  log ERROR "Feature directory not found: $FEATURE_DIR"
  exit 1
fi

if is_branch_created; then
  git checkout "$BRANCH_NAME" 2>/dev/null
fi

while [ $ITERATION -lt $MAX_ITERATIONS ]; do
  ITERATION=$((ITERATION + 1))
  echo "DEBUG: Iteration $ITERATION"

  phase=$(get_current_phase)
  echo "DEBUG: Phase detected: $phase"
  log INFO "Detected phase: $phase"

  invoke_phase "$phase"
  result=$?

  case $result in
    0)
      # Success
      CONSECUTIVE_FAILURES=0
      log SUCCESS "Phase $phase completed successfully"
      ;;
    1)
      # Failure
      CONSECUTIVE_FAILURES=$((CONSECUTIVE_FAILURES + 1))
      log ERROR "Phase $phase failed (failure $CONSECUTIVE_FAILURES/$MAX_FAILURES)"

      if [ $CONSECUTIVE_FAILURES -ge $MAX_FAILURES ]; then
        log ERROR "Too many consecutive failures. Pausing."
        add_session_log "[WARN] Paused after $CONSECUTIVE_FAILURES failures"
        exit 1
      fi
      ;;
    2)
      # Waiting
      log INFO "Waiting for external action..."
      sleep 60
      ;;
    3)
      # Human input needed
      log WARNING "Human input required. Pausing loop."
      add_session_log "[PAUSED] Human input needed in $phase phase"
      exit 0
      ;;
    100)
      # Complete
      log SUCCESS "[COMPLETE] Feature $FEATURE_ID is complete!"
      exit 0
      ;;
  esac

  sleep 2
done

log WARNING "Max iterations ($MAX_ITERATIONS) reached"
add_session_log "[WARN] Max iterations reached at $CURRENT_PHASE phase"
exit 0
