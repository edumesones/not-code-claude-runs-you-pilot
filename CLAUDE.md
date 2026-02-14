# Feature Development Methodology - Project Guide

This is a **methodology-only repository**. It contains a spec-driven feature development system with agent-browser E2E testing and memory system.

## The 9-Phase Feature Cycle

```
1. INTERVIEW        → Capture technical decisions (spec.md)
2. THINK CRITICALLY → 11-step pre-implementation analysis (analysis.md)
3. PLAN             → Design architecture + tasks (design.md, tasks.md)
4. BRANCH           → Create isolated git branch
5. IMPLEMENT        → Execute tasks with atomic commits
5.5 VERIFY          → Browser automation tests (agent-browser E2E)
6. PR               → Auto-sync, auto-resolve conflicts, create PR with test results
7. MERGE            → Human approval → Production
8. WRAP-UP          → Capture learnings (wrap_up.md)
```

**Phase 5.5 (VERIFY)** automatically runs when:
- Frontend files changed (tsx/jsx/css/scss)
- Test scripts exist in `docs/features/FEAT-XXX/tests/`
- Uses Anthropic's agent-browser CLI for E2E testing
- Blocks PR creation if tests fail
- Security filters prevent secret leakage

## Documentation

- [Feature Development Cycle](./docs/feature_cycle.md)

## This is NOT a Code Repository

This repository contains methodology documentation, not project code.
Use this as a reference implementation for your own projects.
