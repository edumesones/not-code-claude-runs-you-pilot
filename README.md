# ralph-spec-agent-mem

> **Spec-driven 9-phase feature development with agent-browser E2E testing and memory system**

[![npm version](https://img.shields.io/npm/v/ralph-spec-agent-mem.svg)](https://www.npmjs.com/package/ralph-spec-agent-mem)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## What is this?

A **feature development methodology** that executes the complete lifecycle from specification to production merge using a structured 9-phase cycle.

### The 9-Phase Cycle

```
1. INTERVIEW        → Capture technical decisions (spec.md)
2. THINK CRITICALLY → 11-step pre-implementation analysis (analysis.md)
3. PLAN             → Design architecture + tasks (design.md, tasks.md)
4. BRANCH           → Create isolated git branch
5. IMPLEMENT        → Execute tasks with atomic commits
5.5 VERIFY          → Browser automation tests (agent-browser E2E)
6. PR               → Auto-sync, auto-resolve conflicts, create PR
7. MERGE            → Human approval → Production
8. WRAP-UP          → Capture learnings (wrap_up.md)
```

### Key Features

- **Spec-Driven**: Every feature starts with a complete specification
- **Agent Automation**: Browser E2E tests with Anthropic's agent-browser
- **Memory System**: Context preservation across development cycles
- **Security Filters**: Automatic secret detection and filtering
- **Progress Tracking**: Real-time status and session logs

## Installation

### NPM (Recommended)

```bash
# Global installation (available in all projects)
npm install -g ralph-spec-agent-mem

# Run the installer
ralph-spec-agent-mem
```

### NPX (No installation required)

```bash
# Run directly
npx ralph-spec-agent-mem
```

### Installation Options

The interactive installer offers 3 options:

1. **Global Installation** → `~/.claude/`
   - Available in ALL projects
   - Commands/skills work everywhere

2. **Project-Level Installation** → `./.claude/`
   - Only in current project
   - Project-specific customization

3. **Both (Recommended)**
   - Global: Core methodology
   - Project: Project-specific overrides

### What Gets Installed?

- Claude commands (`/interview`, `/think-critically`, `/plan`)
- Claude skills (phase execution)
- Memory system (`.memory-system/` with security filters)
- Feature templates (`docs/features/_template/`)
- Documentation (complete guides)

## Quick Start

### 1. Create a Feature

```bash
mkdir -p docs/features/FEAT-001-auth
cp -r docs/features/_template/* docs/features/FEAT-001-auth/
```

### 2. Use Claude Commands

```bash
claude code .
# In Claude:
/interview FEAT-001-auth
/think-critically FEAT-001-auth
/plan FEAT-001-auth
```

## Phase 5.5: VERIFY (Browser E2E Testing)

Includes **automatic browser testing** using Anthropic's agent-browser.

**Auto-runs when:**
- Frontend files changed (tsx/jsx/css/scss)
- Test scripts exist in `docs/features/FEAT-XXX/tests/`

**Features:**
- Agent-browser CLI for E2E tests
- Security filters prevent secret leakage
- Screenshots + console logs
- Blocks PR if tests fail

## Available Commands

Once installed, you can use:

```bash
# Individual phases
/interview FEAT-XXX          # Phase 1: Capture spec
/think-critically FEAT-XXX   # Phase 2: Critical analysis
/plan FEAT-XXX               # Phase 3: Design + tasks
/implement FEAT-XXX          # Phase 5: Execute tasks
/wrap-up FEAT-XXX            # Phase 8: Document learnings

# Git operations
/git commit "message"
/git pr
/git sync
```

## Documentation

- [Complete Feature Cycle Guide](./docs/feature_cycle.md)
- [Installation Guide](./INSTALLATION.md)

## Security

Includes comprehensive security features:

- **Pre-commit hooks**: Block secrets before they're committed
- **Security filters**: 6 pattern types (API keys, tokens, passwords, AWS, private keys, DB URLs)
- **Test data isolation**: Per-feature test users prevent conflicts

## Requirements

- Git
- GitHub CLI (`gh`)
- Claude CLI (`claude`) - recommended
- Node.js 14+ (for agent-browser)
- Python 3 (for JSON manipulation)

## Contributing

Contributions welcome! This is a methodology repository - improve the process, not specific code.

## License

MIT License - see [LICENSE](./LICENSE)

## Author

Eduardo Mesones ([@edumesones](https://github.com/edumesones))

## Support

- [Documentation](https://github.com/edumesones/not-code-claude-runs-you-pilot)
- [Issues](https://github.com/edumesones/not-code-claude-runs-you-pilot/issues)
- [Discussions](https://github.com/edumesones/not-code-claude-runs-you-pilot/discussions)
