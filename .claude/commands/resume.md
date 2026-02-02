---
description: Resume an interrupted feature - Recover context and continue from where you left off
argument-hint: FEAT-XXX
allowed-tools: Read, Bash(git:*), Bash(cat:*), Bash(ls:*)
---

# Resume Feature

## Purpose

Recover context from an interrupted feature session and continue work seamlessly.

## When to Use

- Session interrupted unexpectedly
- Returning to feature after days/weeks
- Switching machines or environments
- Starting new Claude session on existing feature

## Instructions

### 1. Read Feature Status (FIRST)

```bash
cat docs/features/$ARGUMENTS/status.md
```

Identify:
- Current phase (Interview, Plan, Branch, Implement, PR, Merge)
- Progress (X/Y tasks if in Implement)
- Any blockers
- Last activity date

### 2. Read Session Log (SECOND)

```bash
cat docs/features/$ARGUMENTS/context/session_log.md
```

Find:
- Last entry timestamp
- What was being worked on
- Next step that was planned

### 3. Read Current Tasks (THIRD)

```bash
cat docs/features/$ARGUMENTS/tasks.md
```

Identify:
- Tasks marked [x] (complete)
- Tasks marked [🟡] (in progress - was interrupted)
- Tasks marked [🔴] (blocked)
- Next pending task [ ]

### 4. Check for Active Blockers

```bash
cat docs/features/$ARGUMENTS/context/blockers.md
```

Look for any 🔴 Active blockers that need resolution.

### 5. Verify Git State

```bash
# Current branch
git branch --show-current

# Expected: feature/XXX-nombre
# If on main: need to checkout feature branch

# Uncommitted changes?
git status

# Recent commits
git log -n 5 --oneline
```

If not on correct branch:
```bash
git checkout feature/XXX-nombre
git pull origin feature/XXX-nombre
```

### 6. Create Resume Entry

Add to `docs/features/$ARGUMENTS/context/session_log.md`:

```markdown
### [YYYY-MM-DD HH:MM] - Session Resumed 🔄

**Última actividad:** [fecha del último log]
**Días sin actividad:** X
**Estado encontrado:**
- Fase: [fase actual]
- Progreso: X/Y tasks
- Branch: [nombre]
- Uncommitted changes: ✅/❌

**Continuando desde:** [task o acción pendiente]

**Blockers activos:** [ninguno / lista]
```

### 7. Present Summary to User

```
🔄 Resuming FEAT-XXX

**Last Activity:** [date] ([X days ago])

**Current State:**
- Phase: [Implement]
- Progress: [5/12 tasks (42%)]
- Branch: feature/XXX-nombre

**Last Completed:** [Task B3 - Create UserService]

**Next Task:** [Task B4 - Create API endpoints]

**Blockers:** [None] or [List active blockers]

**Ready to continue?**
```

### 8. Handle Different Scenarios

**If in INTERVIEW phase:**
```
"You were in the Interview phase. Let me read spec.md to see 
what decisions were already made, then we can continue..."
```
→ Read spec.md and continue interview

**If in PLAN phase:**
```
"You were creating the implementation plan. Let me check 
design.md and tasks.md progress..."
```
→ Read design.md, continue planning

**If in IMPLEMENT phase:**
```
"You were implementing. Task [X] was in progress [🟡].
Should I continue with that task or start fresh?"
```
→ Continue from in-progress task

**If in PR phase:**
```
"PR was created but not merged. Let me check the PR status..."
```
→ Check PR, see if review needed

**If MERGED but no wrap-up:**
```
"Feature was merged but wrap-up wasn't done. 
Run /wrap-up $ARGUMENTS to close properly."
```

### 9. Continue Work

Once context is recovered:
- Resume from the identified task/phase
- Follow normal feature_cycle.md flow
- Update context/session_log.md as you progress

## Quick Recovery Commands

```bash
# One-liner to see feature state
cat docs/features/FEAT-XXX/status.md && echo "---" && tail -50 docs/features/FEAT-XXX/context/session_log.md

# Check git state
git branch --show-current && git status --short && git log -n 3 --oneline
```

## Argument
$ARGUMENTS
