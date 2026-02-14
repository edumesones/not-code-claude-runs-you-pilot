---
name: agent-designer
description: Derive and define specialized agents for a project based on its characteristics. Triggers on "Design agents", "Define agents for project", or as Step 4 of /new-project flow.
globs: ["docs/project.md", "docs/agents.md", "docs/agents/**", "docs/architecture/**"]
---

# Agent Designer

Derive specialized agents from project characteristics during `/new-project` setup (Step 4).

## Triggers

- "Design agents for this project"
- "Define project agents"
- "What agents does this project need?"
- Automatically called as Step 4 of `/new-project`
- `/design-agents` (opt-in for existing projects)

## Prerequisites

- `docs/project.md` exists with project definition (from project-interview)
- Architecture decisions exist (from architecture-designer)
- MVP features defined (from mvp-planner)

## Purpose

Analyze the project's stack, architecture, and feature set to determine:
1. **Which agents** the project needs
2. **How they specialize** (focus areas per project characteristic)
3. **When they activate** (phase assignments)
4. **How they execute** (Task sub-agent, worktree, sequential)
5. **What rules govern them** (per-agent RULES.md)

## Process

### 1. Analyze Project Characteristics

Read `docs/project.md` and extract:

```
Project Characteristics Checklist:
- [ ] Has backend code? → Which framework?
- [ ] Has frontend code? → Which framework?
- [ ] Has API endpoints? → REST, GraphQL, gRPC?
- [ ] Has database? → Which DB? Migrations?
- [ ] Has authentication? → Which method?
- [ ] Has external API integrations?
- [ ] Has browser UI that needs E2E tests?
- [ ] Is security-sensitive? (finance, health, auth-heavy)
- [ ] Has ML/data pipeline?
- [ ] Is a library/SDK? (documentation-heavy)
- [ ] Has real-time features? (websockets, SSE)
- [ ] Has background jobs/queues?
```

### 2. Derive Agent Set

Apply derivation rules:

#### Always Included (Default Agents)
| Agent | Reason |
|-------|--------|
| A1: implementor | Every project needs code written |
| A2: reviewer | Every project needs code review |
| A5: test-writer | Every project needs tests |

#### Conditionally Added
| Condition | Agent | Specialization |
|-----------|-------|---------------|
| Has backend + frontend | A1 splits into A1-be + A1-fe | Domain-specific worktrees |
| Has backend + frontend + data | A1 splits into A1-be + A1-fe + A1-data | Three parallel worktrees |
| Has API endpoints | A3: bug-detector | + API security focus |
| Has database | A3: bug-detector | + data integrity focus |
| Has authentication | A3: bug-detector | + security audit focus |
| Has external integrations | A3: bug-detector | + contract testing focus |
| Has browser UI | A5: test-writer | + E2E browser tests (agent-browser) |
| Is documentation-heavy | A4: doc-writer | Required (not optional) |
| Is complex architecture | A6: architect | Adversarial review + design validation |
| Simple project (< 3 features) | Skip A4, A6 | Keep agent count minimal |

#### Agent Count Guidelines
- **Simple project** (CLI tool, single service): 3 agents (A1, A2, A5)
- **Medium project** (API + frontend): 4-5 agents (A1-be, A1-fe, A2, A3, A5)
- **Complex project** (full-stack + auth + integrations): 5-6 agents (A1-be, A1-fe, A2, A3, A4, A5, A6)

### 3. Determine Execution Model Per Agent

```
Decision Tree:
├── Agent works on different file domain than other agents?
│   └── YES → Worktree (fork-feature)
├── Agent reviews/analyzes other agent's output?
│   └── YES → Task sub-agent (receives output as input)
├── Only 2 agents in sequence?
│   └── YES → Sequential in same session
└── Default → Task sub-agent
```

### 4. Generate Artifacts

#### A. Create `docs/agents.md`

Use template from `docs/features/_template/agents.md` and fill in:
- Agent Registry table with derived agents
- Phase Assignments with execution details
- Project-specific derivation notes

#### B. Create per-agent RULES.md

For each agent, create `docs/agents/{agent-id}/RULES.md`:
- Start from template: `docs/features/_template/agents/{type}-RULES.md`
- Customize focus areas based on project characteristics
- Set specific file boundaries (which files each agent can/cannot touch)
- Define project-specific quality criteria

#### C. Create per-agent harness.md

For each agent, create `docs/agents/{agent-id}/harness.md`:

```markdown
# Test Harness: {agent-name}

## Self-Verification Checks

### Before Starting
- [ ] Required input files exist: {list files}
- [ ] Git branch is correct
- [ ] Previous agent's output is valid: {describe expected input}

### During Execution
- [ ] Changes stay within allowed files: {list allowed patterns}
- [ ] No RULES.md violations
- [ ] Progress logged correctly

### After Completing
- [ ] All deliverables produced: {list expected outputs}
- [ ] Output matches expected format
- [ ] Quality criteria met: {from RULES.md}
- [ ] Handoff artifact ready: {describe handoff}

## Smoke Tests
{Project-specific validation — e.g., "run npm test", "python -m pytest", "go build"}
```

### 5. Present to User

Show the user a summary:

```
╔═══════════════════════════════════════════════════════════════╗
║  AGENT DESIGN COMPLETE                                        ║
╠═══════════════════════════════════════════════════════════════╣
║                                                               ║
║  Project: {name}                                             ║
║  Agents defined: {count}                                     ║
║                                                               ║
║  Agent Overview:                                             ║
║  {ID} {name} — {role} ({execution model})                    ║
║  ...                                                          ║
║                                                               ║
║  Files Created:                                              ║
║  ✅ docs/agents.md                                           ║
║  ✅ docs/agents/{id}/RULES.md  (× {count})                  ║
║  ✅ docs/agents/{id}/harness.md (× {count})                  ║
║                                                               ║
║  The 9-phase cycle will now use these agents automatically.  ║
║  Edit docs/agents.md to customize agent behavior.            ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
```

### 6. Ask for Confirmation

Before finalizing, ask the user:
- "Does this agent set match your project needs?"
- "Any agents to add, remove, or modify?"
- "Any specific boundaries or rules to customize?"

## File Structure Created

```
docs/
├── agents.md                    # Agent registry & phase assignments
└── agents/
    ├── A1/RULES.md              # (or A1-be/, A1-fe/ if split)
    ├── A1/harness.md
    ├── A2/RULES.md
    ├── A2/harness.md
    ├── A3/RULES.md              # (if derived)
    ├── A3/harness.md
    ├── A5/RULES.md
    ├── A5/harness.md
    └── ...
```

## Integration with /new-project

When called as Step 4 of `/new-project`:

```
/new-project flow:
1. project-interview    → docs/project.md      ✅
2. architecture-designer → docs/architecture/   ✅
3. mvp-planner          → docs/features/        ✅
4. agent-designer       → docs/agents.md + docs/agents/  ← THIS SKILL
```

The skill reads all outputs from Steps 1-3 to make informed agent decisions.

## Opt-In for Existing Projects

Existing projects without `agents.md` can run:
```
/design-agents
```
This analyzes the existing project structure and generates `agents.md` + RULES files.
