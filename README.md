# ralph-spec-agent-mem

> **Autonomous 9-phase feature development with spec-driven design, agent-browser E2E testing, and memory system**

[![npm version](https://img.shields.io/npm/v/ralph-spec-agent-mem.svg)](https://www.npmjs.com/package/ralph-spec-agent-mem)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## What is Ralph Loop?

Ralph Loop is an **autonomous feature development methodology** that executes the complete lifecycle from specification to production merge with minimal human intervention.

### The 9-Phase Cycle

```
1. INTERVIEW        → Capture technical decisions (spec.md)
2. THINK CRITICALLY → 11-step pre-implementation analysis (analysis.md)
3. PLAN             → Design architecture + tasks (design.md, tasks.md)
4. BRANCH           → Create isolated git worktree
5. IMPLEMENT        → Execute tasks with atomic commits
5.5 VERIFY          → Browser automation tests (agent-browser E2E) ✨ NEW
6. PR               → Auto-sync, auto-resolve conflicts, create PR
7. MERGE            → Human approval → Production
8. WRAP-UP          → Capture learnings (wrap_up.md)
```

### Key Features

- ✅ **Spec-Driven**: Every feature starts with a complete specification
- 🤖 **Agent Automation**: Browser E2E tests with Anthropic's agent-browser
- 🧠 **Memory System**: Context preservation across development cycles
- 🔒 **Security Filters**: Automatic secret detection and filtering
- 🔄 **Git Worktrees**: Isolated parallel feature development
- 📊 **Progress Tracking**: Real-time status and session logs

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

- ✅ Ralph Loop scripts (`ralph-feature.sh`, `ralph-feature.ps1`)
- ✅ Claude commands (`/ralph`, `/interview`, `/think-critically`, `/plan`)
- ✅ Claude skills (autonomous loop execution)
- ✅ Memory system (`.memory-system/` with security filters)
- ✅ Feature templates (`docs/features/_template/`)
- ✅ Documentation (complete guides)

## Quick Start

### 1. Create a Feature

```bash
mkdir -p docs/features/FEAT-001-auth
cp -r docs/features/_template/* docs/features/FEAT-001-auth/
```

### 2. Run Ralph Loop

```bash
# Bash/Linux/macOS
./ralph-feature.sh FEAT-001-auth

# PowerShell/Windows
.\ralph-feature.ps1 FEAT-001-auth
```

### 3. Or Use Claude Commands

```bash
claude code .
# In Claude:
/ralph FEAT-001-auth
```

## Phase 5.5: VERIFY (Browser E2E Testing)

Ralph Loop now includes **automatic browser testing** using Anthropic's agent-browser.

**Auto-runs when:**
- ✅ Frontend files changed (tsx/jsx/css/scss)
- ✅ Test scripts exist in `docs/features/FEAT-XXX/tests/`

**Features:**
- 🤖 Agent-browser CLI for E2E tests
- 🔒 Security filters prevent secret leakage
- 📸 Screenshots + console logs
- 🚫 Blocks PR if tests fail

**Example test structure:**

```bash
docs/features/FEAT-001-auth/
├── tests/
│   ├── e2e-flow.sh          # Main E2E test
│   ├── e2e-smoke.sh         # Quick smoke test
│   ├── helpers.sh           # Reusable functions
│   └── test-config.json     # Test configuration
└── test-results/
    ├── screenshots/
    ├── console.log
    └── network.log
```

## Available Commands

Once installed, you can use:

```bash
# Autonomous loop (processes all phases)
/ralph FEAT-XXX

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
- [Ralph Loop Documentation](./docs/ralph-feature-loop.md)
- [Methodology Article](./docs/RALPH_METHODOLOGY_ARTICLE.md)
- [Installation Guide](./INSTALLATION.md)

## Architecture

Ralph Loop uses **git worktrees** for parallel feature development:

```
project/                            ← Main repo
project-FEAT-001-auth-loop/         ← Worktree for FEAT-001
project-FEAT-002-api-loop/          ← Worktree for FEAT-002
project-FEAT-003-dashboard-loop/    ← Worktree for FEAT-003
```

**Benefits:**
- Zero conflicts between parallel features
- Independent branches per feature
- Clean state for each loop
- Automatic cleanup after merge

## Security

Ralph Loop includes comprehensive security features:

- 🔒 **Pre-commit hooks**: Block secrets before they're committed
- 🛡️ **Security filters**: 6 pattern types (API keys, tokens, passwords, AWS, private keys, DB URLs)
- 🧪 **Test data isolation**: Per-feature test users prevent conflicts
- 📦 **Version locking**: agent-browser@0.8.4 prevents breaking changes

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

- 📖 [Documentation](https://github.com/edumesones/not-code-claude-runs-you-pilot)
- 🐛 [Issues](https://github.com/edumesones/not-code-claude-runs-you-pilot/issues)
- 💬 [Discussions](https://github.com/edumesones/not-code-claude-runs-you-pilot/discussions)

---

**Made with ❤️ for autonomous development**
