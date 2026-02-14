# Feature Development Methodology - Installation Guide

## Quick Install

### Linux / macOS

```bash
curl -fsSL https://raw.githubusercontent.com/edumesones/not-code-claude-runs-you-pilot/main/install.sh | bash
```

Or manually:

```bash
git clone https://github.com/edumesones/not-code-claude-runs-you-pilot
cd not-code-claude-runs-you-pilot
chmod +x install.sh
./install.sh
```

### Windows (PowerShell)

```powershell
iwr -useb https://raw.githubusercontent.com/edumesones/not-code-claude-runs-you-pilot/main/install.ps1 | iex
```

Or manually:

```powershell
git clone https://github.com/edumesones/not-code-claude-runs-you-pilot
cd not-code-claude-runs-you-pilot
powershell -ExecutionPolicy Bypass -File install.ps1
```

---

## Installation Options

The installer is **smart** - it offers 3 options:

### Option 1: Global Installation

**Location:** `~/.claude/`

**Best for:**
- Want methodology available in **ALL projects**
- Use Claude Code across multiple projects
- Team-wide standardization

**What happens:**
- Installs to `~/.claude/`
- Commands work in any project
- Preserves existing `~/.claude/` config (merges intelligently)

**Example:**
```bash
cd any-project/
claude code .
# /interview, /think-critically all available!
```

---

### Option 2: Project-Level Installation

**Location:** `./.claude/` (current directory)

**Best for:**
- Want methodology only in **this project**
- Project-specific customization
- Testing before global adoption

**What happens:**
- Installs to `./.claude/` in current directory
- Only works in this project
- Can customize for project needs
- Preserves existing `.claude/` config (merges intelligently)

---

### Option 3: Both (Recommended)

**Locations:** `~/.claude/` + `./.claude/`

**Best for:**
- Global baseline + project overrides
- Consistent methodology across projects
- Project-specific tweaks

---

## What Gets Installed

### Global Installation (`~/.claude/`)

```
~/.claude/
├── CLAUDE.md                    # Methodology instructions
├── commands/                    # Custom commands
│   ├── interview.md             # /interview command
│   ├── think-critically.md      # /think-critically command
│   ├── plan.md                  # /plan command
│   └── wrap-up.md               # /wrap-up command
└── skills/                      # Custom skills
    ├── implementer/SKILL.md
    ├── status-reporter/SKILL.md
    └── thinking-critically/SKILL.md
```

### Project Installation (`./.claude/`)

```
my-project/
├── .claude/
│   ├── CLAUDE.md               # Project instructions (merged)
│   ├── commands/               # Project commands (merged)
│   └── skills/                 # Project skills (merged)
├── .memory-system/             # Memory & security
└── docs/
    └── features/
        └── _template/          # Feature template
```

---

## Prerequisites

### Required
- **Git** - Version control
- **Claude CLI** - Get from https://claude.ai/download

### Recommended
- **GitHub CLI** (`gh`) - For PR automation
- **Node.js 18+** - For Memory-MCP features

### Optional
- **agent-browser** - For Phase 5.5 (VERIFY) browser tests
  ```bash
  npm install -g @anthropic-ai/agent-browser
  ```

---

## Post-Installation

### 1. Verify Installation

**Global:**
```bash
ls ~/.claude/
# Should show: CLAUDE.md, commands/, skills/
```

**Project:**
```bash
ls ./.claude/
# Should show: CLAUDE.md, commands/, skills/
```

### 2. Test Commands

```bash
cd any-project/
claude code .
```

In Claude:
```
/interview --help
/think-critically --help
```

### 3. Run First Feature

```bash
# Create feature directory
mkdir -p docs/features/FEAT-001-test

# In Claude:
/interview FEAT-001-test
```

---

## Security Features

### Pre-Commit Hooks (Optional)

During installation, you'll be asked:

```
Install security pre-commit hooks in this repo? [Y/n]:
```

**If YES:**
- Installs git pre-commit hook
- Scans test results for secrets before commit
- Blocks commits containing API keys, tokens, passwords
- See `.memory-system/docs/security-mitigations.md`

**If NO:**
- Skip hooks (can install later)
- Run manually: `bash .memory-system/scripts/install-git-hooks.sh`

---

## Uninstalling

### Remove Global Installation

```bash
rm -rf ~/.claude/
# Or selectively remove specific commands/skills
```

### Remove Project Installation

```bash
rm -rf ./.claude/
rm -rf .memory-system/
```

---

## Support

- **Documentation:** `docs/feature_cycle.md`
- **Issues:** https://github.com/edumesones/not-code-claude-runs-you-pilot/issues
- **PR:** https://github.com/edumesones/not-code-claude-runs-you-pilot/pulls
