---
description: Initialize a new project with complete documentation structure
argument-hint: ProjectName ["Description"] ["Stack"]
allowed-tools: Bash(python:*), Bash(mkdir:*), Write, Read
---

# Initialize New Project

## Purpose

Create a complete project structure with:
- Documentation templates (features, architecture, sprints)
- Claude Code workflow commands
- Feature development cycle
- Git-ready structure

## Usage Examples

```
/new-project MyApp
/new-project "SQL Assistant" "Natural language to SQL queries"
/new-project DataPipeline "ETL pipeline" "Python, Apache Airflow, PostgreSQL"
```

## Instructions

1. Parse arguments:
   - First argument: Project name (required)
   - Second argument: Description (optional)
   - Third argument: Stack (optional)

2. Execute the creation script:
   ```bash
   python .claude/skills/project-init/tools/create_structure.py "$ARGUMENTS"
   ```

3. If script not found, create structure manually following SKILL.md

4. After creation, show summary:
   - Files created
   - Next steps for user

## Structure Created

```
{project}/
├── .claude/
│   ├── commands/
│   │   ├── new-feature.md
│   │   ├── interview.md
│   │   ├── plan.md
│   │   └── implement.md
│   ├── skills/
│   │   ├── agent-designer/SKILL.md
│   │   └── agent-orchestrator/SKILL.md
│   └── settings.json
├── docs/
│   ├── project.md
│   ├── feature_cycle.md
│   ├── agents.md                    ← NEW: Generated in Step 4
│   ├── agents/                      ← NEW: Per-agent RULES + harness
│   │   └── {agent-id}/
│   │       ├── RULES.md
│   │       └── harness.md
│   ├── architecture/_index.md
│   ├── features/
│   │   ├── _index.md
│   │   └── _template/
│   ├── sprints/_index.md
│   └── decisions/_index.md
├── src/
├── tests/
├── CLAUDE.md
└── README.md
```

## Instructions (Updated with Agent Design)

1. Parse arguments:
   - First argument: Project name (required)
   - Second argument: Description (optional)
   - Third argument: Stack (optional)

2. Execute Steps 1-3 (existing flow):
   - Step 1: `project-interview` → `docs/project.md`
   - Step 2: `architecture-designer` → `docs/architecture/`
   - Step 3: `mvp-planner` → `docs/features/`

3. **Step 4 (NEW): Agent Design**
   - Invoke `agent-designer` skill
   - Reads outputs from Steps 1-3
   - Derives specialized agents from project characteristics
   - Generates: `docs/agents.md` + `docs/agents/{id}/RULES.md` + `docs/agents/{id}/harness.md`
   - Agent templates available at `docs/features/_template/agents/`

4. After creation, show summary:
   - Files created
   - Agents derived and their roles
   - Next steps for user

## Post-Creation

Tell the user:

1. "Project structure created!"
2. "Edit `docs/project.md` to define your project"
3. "Agents defined in `docs/agents.md` — review and customize"
4. "Run `/new-feature FEAT-001-nombre` to create your first feature"
5. "Follow `docs/feature_cycle.md` for the development workflow (now multi-agent)"
6. "Run `/design-agents` anytime to re-derive agents if project evolves"

## Argument
$ARGUMENTS
