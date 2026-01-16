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
│   └── settings.json
├── docs/
│   ├── project.md
│   ├── feature_cycle.md
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

## Post-Creation

Tell the user:

1. "✅ Project structure created!"
2. "📝 Edit `docs/project.md` to define your project"
3. "🆕 Run `/new-feature FEAT-001-nombre` to create your first feature"
4. "📖 Follow `docs/feature_cycle.md` for the development workflow"

## Argument
$ARGUMENTS
