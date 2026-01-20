---
name: implementer
description: Execute feature tasks one by one with live documentation. Triggers on "Execute FEAT-XXX tasks", "Start implementing FEAT-XXX", "Work on FEAT-XXX", "Continue FEAT-XXX".
globs: ["docs/features/**/tasks.md", "docs/features/**/status.md", "src/**", "tests/**"]
---

# Implementer

Execute feature tasks one by one with live documentation updates.

## Triggers

- "Execute FEAT-XXX tasks"
- "Start implementing FEAT-XXX"
- "Work on FEAT-XXX"
- "Continue FEAT-XXX"
- "Resume FEAT-XXX"
- "Next task for FEAT-XXX"

## Prerequisites

- Feature folder exists with completed:
  - `spec.md` ✅
  - `design.md` ✅
  - `tasks.md` ✅
- Git branch created for feature
- If missing: guide user to complete previous phases

## Purpose

1. **Find next uncompleted task** in tasks.md
2. **Execute task** (write code, create files, etc.)
3. **Update documentation** in real-time
4. **Commit** after each task
5. **Update status** after each task
6. **Repeat** until all tasks done or blocker hit

## Process

### 1. Read Context

```bash
# Read tasks
cat docs/features/FEAT-XXX/tasks.md

# Read design for reference
cat docs/features/FEAT-XXX/design.md

# Read spec for requirements
cat docs/features/FEAT-XXX/spec.md

# Check current status
cat docs/features/FEAT-XXX/status.md

# Verify git branch
git branch --show-current
```

### 2. Verify Branch

```
╔═══════════════════════════════════════════════════════════════════════════════╗
║  BRANCH CHECK                                                                  ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║                                                                                ║
║  If on main/master:                                                           ║
║  → STOP and say: "Create feature branch first:                                ║
║    git checkout -b feature/XXX-name"                                          ║
║                                                                                ║
║  If on correct feature branch:                                                ║
║  → Continue with implementation                                               ║
║                                                                                ║
╚═══════════════════════════════════════════════════════════════════════════════╝
```

### 3. Find Next Task

Scan tasks.md for first task that is:
- `[ ]` Pending, OR
- `[🟡]` In Progress (resume)

Skip tasks that are:
- `[x]` Complete
- `[⏭️]` Skipped
- `[🔴]` Blocked

### 4. Execute Task Loop

For each task:

```
╔═══════════════════════════════════════════════════════════════════════════════╗
║  TASK EXECUTION FLOW                                                           ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║                                                                                ║
║  A. BEFORE starting:                                                           ║
║     1. Update tasks.md: [ ] → [🟡]                                            ║
║     2. Announce: "Starting task: [task description]"                          ║
║                                                                                ║
║  B. DURING execution:                                                          ║
║     1. Write code / create files                                              ║
║     2. Follow design.md specifications                                        ║
║     3. If unclear → ask user, don't assume                                    ║
║     4. If blocked → mark [🔴] and move to next                                ║
║                                                                                ║
║  C. AFTER completing:                                                          ║
║     1. Update tasks.md: [🟡] → [x]                                            ║
║     2. Update progress table in tasks.md                                      ║
║     3. Commit: git add . && git commit -m "FEAT-XXX: [task]"                  ║
║     4. Update status.md with progress                                         ║
║     5. Update _index.md with progress                                         ║
║     6. Announce: "✅ Task complete. Progress: X/Y tasks"                      ║
║                                                                                ║
║  D. EVERY 3 tasks or 30 minutes:                                               ║
║     1. git push origin [branch]                                               ║
║     2. Summary of progress                                                    ║
║                                                                                ║
╚═══════════════════════════════════════════════════════════════════════════════╝
```

### 5. Task Documentation

**tasks.md updates:**

```markdown
# Before
- [ ] Create User model in src/models/user.py

# During  
- [🟡] Create User model in src/models/user.py

# After
- [x] Create User model in src/models/user.py
```

**Progress table update:**

```markdown
| Section | Progress | Tasks |
|---------|----------|-------|
| Backend | 🟡 25% | 2/8 |  ← UPDATE after each task
```

### 6. Commit Format

```bash
git add [specific files for this task]
git commit -m "FEAT-XXX: [Task description]"
```

**Examples:**
```
FEAT-001: Create User model
FEAT-001: Add user validation schemas
FEAT-001: Implement UserService CRUD methods
FEAT-001: Add POST /users endpoint
FEAT-001: Add unit tests for UserService
```

### 7. Status Updates

**After EACH task, update:**

**status.md:**
```markdown
## Progress
- Tasks completed: X/Y
- Current task: [next task or "All complete"]
- Last update: {timestamp}
```

**_index.md (global):**
```markdown
| FEAT-XXX | [Name] | 🟡 In Progress | Implement (X/Y) |
```

### 8. Blocker Handling

If task cannot be completed:

```markdown
# In tasks.md:
- [🔴] Create payment integration (blocked: waiting for Stripe API keys)

# In status.md:
## Blockers
| Task | Reason | Action Needed |
|------|--------|---------------|
| Payment integration | Missing API keys | User to provide keys |
```

Then continue with next unblocked task.

### 9. Completion

When all tasks done:

```
✅ FEAT-XXX implementation complete!

Summary:
- Total tasks: X
- Completed: X
- Skipped: X
- Blocked: X

Updated:
- docs/features/FEAT-XXX/tasks.md (all marked)
- docs/features/FEAT-XXX/status.md (Phase: Implement ✅)
- docs/features/_index.md (status updated)

Next steps:
1. Push: git push -u origin feature/XXX-name
2. Create PR: "Create PR for FEAT-XXX"
```

### 10. Integration with Status Reporter

**CRITICAL: This skill updates status after EVERY task:**

1. tasks.md - task checkbox + progress table
2. status.md - progress count + current task
3. _index.md - global feature status
4. status-log.md - append action log

## Pause/Resume

If user needs to stop:
- Current task stays as `[🟡]`
- status.md shows "Paused at task X"
- Resume with "Continue FEAT-XXX"

## Error Recovery

If something goes wrong:
- Don't mark task complete
- Ask user for guidance
- Document issue in status.md Blockers section
