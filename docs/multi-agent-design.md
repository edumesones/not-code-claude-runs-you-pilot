# Multi-Agent Integration Design

## Overview

This document defines how the existing 9-phase feature development methodology evolves from a single-agent system to a **multi-agent system** where specialized agents collaborate within and across phases.

### Core Principles

1. **Relay Pattern**: Agents hand off work continuously. When one finishes, the next picks up.
2. **Specialization over Brute Force**: Each agent has a focused role — not one agent doing everything.
3. **Context Management ("Headspace")**: Each agent operates with a clean, focused context window.
4. **Environment > Model**: Scaffolding (test harnesses, RULES.md, guardrails) matters more than the model.
5. **Dynamic Agent Definition**: Agents are NOT hardcoded — they are derived from project characteristics during `/new-project`.
6. **Trust through Verification**: Agents self-verify using test harnesses and validation tools.

---

## Architecture

### New `/new-project` Flow

```
/new-project (current flow + new step)
├── 1. Project Interview        → project.md
├── 2. Architecture Design      → ADRs
├── 3. MVP Definition           → features/
└── 4. NEW: Agent Design        → agents.md + agents/RULES per agent
```

### Per-Feature Flow (9 Phases, Modified)

```
Each phase:
  1. Read agents.md → find agents assigned to this phase
  2. Determine execution model (Task sub-agent / worktree / sequential)
  3. For each agent in phase:
     a. Build agent prompt from RULES.md + phase context
     b. Execute agent with appropriate isolation
     c. Collect results
     d. Hand off to next agent (relay) or merge (parallel)
  4. Phase completes when all agents finish
```

### Execution Model (Hybrid)

| Situation | Model | Mechanism |
|-----------|-------|-----------|
| Agents within a phase (reviewer, bug-finder) | Sub-agents | `Task` tool with focused prompt |
| Parallel implementation (backend/frontend) | Worktrees | `fork-feature` skill |
| Simple sequential relay (2 agents) | Same session | Sequential prompts |

---

## Agent Definition: `agents.md`

Generated during `/new-project` step 4 (Agent Design). Located at `docs/agents.md`.

### Structure

```markdown
# Project Agents

## Agent Registry

| ID | Name | Role | Phases | Execution |
|----|------|------|--------|-----------|
| A1 | implementor | Write production code | 5 | worktree/task |
| A2 | reviewer | Code review & quality | 5, 6 | task |
| A3 | bug-detector | Find bugs & edge cases | 5, 5.5 | task |
| A4 | doc-writer | Documentation & comments | 5, 8 | task |
| A5 | test-writer | Write & run tests | 5, 5.5 | worktree/task |
| A6 | architect | Design decisions | 2, 3 | task |

## Phase Assignments

### Phase 1: INTERVIEW
- No agents (human-driven with spec-architect skill)

### Phase 2: THINK CRITICALLY
- **A6 (architect)**: Runs adversarial review (Step 9)
- Sequential after human completes Steps 1-8

### Phase 3: PLAN
- **A6 (architect)**: Validates design against analysis
- Sequential after implementation-planner

### Phase 4: BRANCH
- No agents (automated by git-automator)

### Phase 5: IMPLEMENT
- **A1 (implementor)**: Executes tasks from tasks.md
- **A2 (reviewer)**: Reviews every 3 tasks (relay after A1 checkpoint)
- **A3 (bug-detector)**: Scans for bugs after A2 review
- **A5 (test-writer)**: Writes tests in parallel with A1 (worktree)
- Execution: A1 + A5 parallel (worktrees), A2 + A3 sequential relay after checkpoints

### Phase 5.5: VERIFY
- **A3 (bug-detector)**: Analyzes test results
- **A5 (test-writer)**: Fixes failing tests
- Sequential relay

### Phase 6: PR
- **A2 (reviewer)**: Final review before PR
- **A4 (doc-writer)**: PR description generation
- Sequential relay

### Phase 7: MERGE
- No agents (human approval)

### Phase 8: WRAP-UP
- **A4 (doc-writer)**: Generate wrap-up documentation
- **A6 (architect)**: Capture architectural learnings

## Agent Derivation Rules

Agents are derived from project characteristics:

| Project Characteristic | Agents Added |
|----------------------|--------------|
| Has backend code | A1 (implementor-backend) |
| Has frontend code | A1 (implementor-frontend), A3 with UI focus |
| Has API endpoints | A2 with API review focus, A5 with integration tests |
| Has database | A3 with data integrity focus |
| Has external integrations | A3 with contract testing focus |
| Has documentation needs | A4 (doc-writer) |
| Is security-sensitive | A3 with security audit focus |
| Has ML/data pipeline | A1 (implementor-data), A5 with data validation |
```

---

## Per-Agent RULES.md

Each agent gets a `docs/agents/{agent-id}/RULES.md` that defines:

### Template

```markdown
# Agent: {name} ({id})

## Identity
- **Role**: {one-line role description}
- **Phases**: {comma-separated phases}
- **Execution**: {task | worktree | sequential}

## Responsibilities
- {What this agent MUST do}

## Boundaries
- {What this agent MUST NOT do}
- {Files it cannot modify}
- {Decisions it cannot make}

## Input
- {What context/files this agent receives}

## Output
- {What this agent produces}
- {Format of deliverables}

## Quality Criteria
- {How to verify this agent did its job well}
- {Self-check checklist}

## Relay Protocol
- **Receives from**: {previous agent or phase trigger}
- **Hands off to**: {next agent}
- **Handoff artifact**: {what gets passed — file, report, commit}
```

---

## Test Harness Generation

During `/new-project` step 4, generate per-agent test harnesses at `docs/agents/{agent-id}/harness.md`:

```markdown
# Test Harness: {agent-name}

## Self-Verification Checks

### Before Starting
- [ ] Required input files exist
- [ ] Git branch is correct
- [ ] Previous agent's output is valid

### During Execution
- [ ] Changes stay within allowed file boundaries
- [ ] No RULES.md violations
- [ ] Progress logged correctly

### After Completing
- [ ] All deliverables produced
- [ ] Output matches expected format
- [ ] Quality criteria met
- [ ] Handoff artifact ready for next agent

## Smoke Tests
{Agent-specific validation commands}
```

---

## Orchestration Protocol

### How a Phase Runs with Agents

```
Phase N starts
│
├── 1. Read docs/agents.md → get agents for Phase N
├── 2. Read phase-specific ordering (sequential vs parallel)
│
├── 3. For PARALLEL agents:
│   ├── Launch via fork-feature (worktrees) or parallel Task calls
│   ├── Each agent gets: RULES.md + phase context + relevant files
│   └── Wait for all to complete → merge results
│
├── 4. For SEQUENTIAL agents (relay):
│   ├── Agent A executes → produces artifact → commits
│   ├── Agent B receives artifact → executes → produces artifact → commits
│   └── Continue chain until all agents complete
│
├── 5. Orchestrator validates:
│   ├── All agents' outputs present
│   ├── No RULES.md violations
│   └── Phase completion criteria met
│
└── Phase N complete → trigger Phase N+1
```

### Orchestrator Responsibilities

The orchestrator (main Claude session) does NOT do the agents' work. It:

1. **Routes**: Reads `agents.md`, determines which agents to invoke
2. **Launches**: Creates Task sub-agents or fork-feature worktrees
3. **Monitors**: Checks agent outputs against quality criteria
4. **Relays**: Passes artifacts between sequential agents
5. **Merges**: Combines parallel agent outputs
6. **Escalates**: If an agent fails or gets blocked, surfaces to user

---

## Integration with Existing Skills

### Skills That Become "Agent-Aware"

| Existing Skill | Modification |
|----------------|-------------|
| `spec-architect` | No change (Phase 1 stays human-driven) |
| `thinking-critically` | After Step 8, invoke architect agent for Step 9 adversarial review |
| `implementation-planner` | After planning, invoke architect agent for validation |
| `implementer` | Becomes the default A1 agent; adds reviewer/bug-detector relay |
| `git-automator` | No change (infrastructure, not agent) |
| `fork-feature` | Used as execution mechanism for parallel agents |
| `status-reporter` | Extended to track per-agent progress |
| `project-init` | Extended to create `docs/agents/` structure |

### New Skills Created

| New Skill | Purpose |
|-----------|---------|
| `agent-designer` | `/new-project` step 4: derive agents from project characteristics |
| `agent-orchestrator` | Phase-level agent routing, launching, monitoring |

---

## File Structure Changes

```
{project}/
├── docs/
│   ├── agents.md                    # NEW: Agent registry & phase assignments
│   ├── agents/                      # NEW: Per-agent definitions
│   │   ├── {agent-id}/
│   │   │   ├── RULES.md            # Agent rules & boundaries
│   │   │   └── harness.md          # Self-verification test harness
│   │   └── ...
│   ├── features/                    # EXISTING (unchanged)
│   └── ...
├── .claude/
│   ├── skills/
│   │   ├── agent-designer/          # NEW: Derives agents from project
│   │   │   └── SKILL.md
│   │   ├── agent-orchestrator/      # NEW: Routes & launches agents
│   │   │   └── SKILL.md
│   │   └── ... (existing skills modified)
│   └── commands/
│       └── new-project.md           # MODIFIED: adds step 4
```

---

## Example: Full-Stack Web App

After `/new-project MyWebApp "Full-stack e-commerce" "Next.js, FastAPI, PostgreSQL"`:

**Generated `agents.md`:**

| ID | Name | Role | Why Derived |
|----|------|------|-------------|
| A1-be | implementor-backend | FastAPI code | Has backend (FastAPI) |
| A1-fe | implementor-frontend | Next.js code | Has frontend (Next.js) |
| A2 | reviewer | Code review | Default for all projects |
| A3-sec | bug-detector-security | Security audit | Has auth + payments |
| A3-data | bug-detector-data | Data integrity | Has PostgreSQL |
| A4 | doc-writer | API docs, README | Has API endpoints |
| A5-unit | test-writer-unit | Unit tests | Default for all projects |
| A5-e2e | test-writer-e2e | E2E browser tests | Has frontend |

**Phase 5 execution:**

```
A1-be (worktree: backend) ──────────────────────┐
                                                  ├──→ A2 (review) → A3-sec (audit) → commit
A1-fe (worktree: frontend) ──────────────────────┘
A5-unit (worktree: tests) ────→ parallel with A1s
```

---

## Example: CLI Tool

After `/new-project MyCLI "Data processing CLI" "Python, Click, SQLite"`:

**Generated `agents.md`:**

| ID | Name | Role | Why Derived |
|----|------|------|-------------|
| A1 | implementor | Python CLI code | Single codebase |
| A2 | reviewer | Code review | Default |
| A3 | bug-detector | Edge cases | CLI input handling |
| A5 | test-writer | Unit + integration | Default |

**Phase 5 execution (simpler):**

```
A1 (implement) → A2 (review) → A3 (bugs) → A5 (tests) → commit
All sequential relay, no worktrees needed
```

---

## Migration Path

This is **additive**, not breaking:

1. Existing projects without `agents.md` → everything works as before (single-agent mode)
2. New projects get `agents.md` during `/new-project` → multi-agent mode
3. Existing projects can opt-in by running a new `/design-agents` command

The orchestrator checks: if `docs/agents.md` exists → multi-agent mode. Otherwise → legacy single-agent mode.
