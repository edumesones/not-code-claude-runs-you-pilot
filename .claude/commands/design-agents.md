---
description: Derive and define specialized agents for the project based on its characteristics
argument-hint: [--force]
allowed-tools: Read, Write, Bash(mkdir:*)
---

# Design Agents

## Purpose

Analyze the project's stack, architecture, and features to derive specialized agents. Creates `docs/agents.md` and per-agent RULES.md + harness.md files.

## Usage

```
/design-agents              # Derive agents (skip if agents.md already exists)
/design-agents --force      # Re-derive agents (overwrite existing agents.md)
```

## Instructions

1. Check if `docs/agents.md` already exists:
   - If exists and no `--force` → tell user to use `--force` to re-derive
   - If exists and `--force` → proceed (will overwrite)
   - If not exists → proceed

2. Invoke the `agent-designer` skill to:
   - Read `docs/project.md` for project characteristics
   - Read `docs/architecture/` for technical constraints
   - Read `docs/features/` for feature scope
   - Derive the optimal agent set
   - Generate `docs/agents.md`
   - Generate `docs/agents/{id}/RULES.md` for each agent
   - Generate `docs/agents/{id}/harness.md` for each agent

3. Show summary of derived agents and next steps

## Argument
$ARGUMENTS
