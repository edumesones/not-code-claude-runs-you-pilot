# Ralph Loop - Installation Guide

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
- Want Ralph Loop available in **ALL projects**
- Use Claude Code across multiple projects
- Team-wide standardization

**What happens:**
- Installs to `~/.claude/`
- Commands work in any project
- Scripts available globally
- Preserves existing `~/.claude/` config (merges intelligently)

**Example:**
```bash
cd any-project/
claude code .
# /ralph, /interview, /think-critically all available!
```

---

### Option 2: Project-Level Installation

**Location:** `./.claude/` (current directory)

**Best for:**
- Want Ralph Loop only in **this project**
- Project-specific customization
- Testing before global adoption

**What happens:**
- Installs to `./.claude/` in current directory
- Only works in this project
- Can customize for project needs
- Preserves existing `.claude/` config (merges intelligently)

**Example:**
```bash
cd my-project/
./install.sh
# Ralph Loop only available in my-project/
```

---

### Option 3: Both (Recommended)

**Locations:** `~/.claude/` + `./.claude/`

**Best for:**
- Global baseline + project overrides
- Consistent methodology across projects
- Project-specific tweaks

**What happens:**
- Global: Core Ralph Loop methodology
- Project: Project-specific commands/skills
- Project overrides take precedence
- Full flexibility

**Example:**
```bash
# Global: Available everywhere
~/.claude/commands/ralph.md

# Project: Custom command for this project
./my-project/.claude/commands/custom-deploy.md
```

---

## Intelligent Merge

The installer **never overwrites without asking**:

### Scenario 1: No existing config
```bash
./install.sh
# ✓ Clean install, everything copied
```

### Scenario 2: Existing CLAUDE.md
```
⚠ CLAUDE.md already exists
  Current: ~/.claude/CLAUDE.md

  Replace with Ralph Loop version? [y/N]: n

  ✓ Ralph Loop version saved as: CLAUDE.md.ralph-backup
  ℹ You can manually merge later
```

### Scenario 3: Existing commands/skills
```
⚠ commands/ralph.md already exists and is different

  Replace with Ralph Loop version? [y/N]: n

  ✓ Saved as ralph.md.ralph-backup
```

**Result:** Your existing config is **preserved**. Ralph Loop files saved as `.ralph-backup`.

---

## What Gets Installed

### Global Installation (`~/.claude/`)

```
~/.claude/
├── CLAUDE.md                    # Ralph Loop instructions
├── commands/                    # Custom commands
│   ├── ralph.md                # /ralph command
│   ├── interview.md            # /interview command
│   ├── think-critically.md     # /think-critically command
│   ├── plan.md                 # /plan command
│   └── wrap-up.md              # /wrap-up command
├── skills/                      # Custom skills
│   ├── ralph-loop/SKILL.md
│   ├── implementer/SKILL.md
│   ├── status-reporter/SKILL.md
│   └── thinking-critically/SKILL.md
└── ralph-loop/                  # Scripts & docs
    ├── ralph-feature.sh
    ├── ralph-feature.ps1
    ├── .memory-system/
    └── docs/
```

### Project Installation (`./.claude/`)

```
my-project/
├── .claude/
│   ├── CLAUDE.md               # Project instructions (merged)
│   ├── commands/               # Project commands (merged)
│   └── skills/                 # Project skills (merged)
├── ralph-feature.sh            # Ralph Loop script
├── ralph-feature.ps1           # PowerShell version
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
# Should show: CLAUDE.md, commands/, skills/, ralph-loop/
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
/ralph --help
/interview --help
/think-critically --help
```

### 3. Run First Feature

```bash
# Create feature directory
mkdir -p docs/features/FEAT-001-test

# Run Ralph Loop
./ralph-feature.sh FEAT-001-test

# Or in Claude:
/ralph FEAT-001-test
```

---

## Configuration

### Global Config (`~/.claude/CLAUDE.md`)

Applies to **ALL projects**. Edit for team-wide standards:

```bash
vim ~/.claude/CLAUDE.md
```

### Project Config (`./.claude/CLAUDE.md`)

Applies only to **this project**. Edit for project-specific needs:

```bash
vim ./.claude/CLAUDE.md
```

### Priority

When both exist:
1. Project config (`./.claude/`) takes precedence
2. Global config (`~/.claude/`) as fallback

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

## Updating

### Update Global Installation

```bash
cd ~/.claude/ralph-loop/
git pull
./install.sh
# Choose option 1 (Global)
```

### Update Project Installation

```bash
cd my-project/
git clone https://github.com/edumesones/not-code-claude-runs-you-pilot /tmp/ralph-loop
cd /tmp/ralph-loop
./install.sh
# Choose option 2 (Project)
```

---

## Uninstalling

### Remove Global Installation

```bash
rm -rf ~/.claude/ralph-loop/
# Manually remove from ~/.claude/CLAUDE.md if needed
```

### Remove Project Installation

```bash
rm -rf ./.claude/
rm ralph-feature.sh ralph-feature.ps1
rm -rf .memory-system/
```

---

## Troubleshooting

### "Command not found: /ralph"

**Cause:** Commands not in `~/.claude/commands/`

**Fix:**
```bash
ls ~/.claude/commands/
# If empty, reinstall:
./install.sh
```

### "Scripts not in PATH"

**Cause:** `~/.claude/ralph-loop/` not in PATH

**Fix (Linux/Mac):**
```bash
echo 'export PATH="$HOME/.claude/ralph-loop:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

**Fix (Windows):**
```powershell
$env:Path += ";$env:USERPROFILE\.claude\ralph-loop"
# Or set permanently via System Properties
```

### "Existing config conflicts"

**Cause:** Installer found existing files

**Fix:**
1. Check `.ralph-backup` files created by installer
2. Manually merge:
   ```bash
   # Compare
   diff ~/.claude/CLAUDE.md ~/.claude/CLAUDE.md.ralph-backup

   # Merge manually
   vim ~/.claude/CLAUDE.md
   ```

---

## Examples

### Example 1: Solo Developer (Global)

```bash
# Install globally
./install.sh
# Choose: 1 (Global)

# Use in any project
cd ~/projects/app1
claude code .
# /ralph, /interview available

cd ~/projects/app2
claude code .
# /ralph, /interview available
```

### Example 2: Team (Global + Project)

```bash
# Install globally for baseline
./install.sh
# Choose: 1 (Global)

# Install project-specific overrides
cd ~/projects/team-app
./install.sh
# Choose: 2 (Project)

# Add team-specific command
vim ./.claude/commands/deploy-staging.md
```

### Example 3: Testing (Project Only)

```bash
# Test in one project first
cd ~/projects/test-app
./install.sh
# Choose: 2 (Project)

# If it works, go global
./install.sh
# Choose: 1 (Global)
```

---

## Next Steps

1. ✅ **Read Quick Start:** `docs/feature_cycle.md`
2. ✅ **Run First Feature:** `./ralph-feature.sh FEAT-001`
3. ✅ **Configure Memory:** `docs/memory-integration-plan.md`
4. ✅ **Setup Security:** `bash .memory-system/scripts/install-git-hooks.sh`
5. ✅ **Learn Commands:** See `.claude/commands/` directory

---

## Support

- **Documentation:** `~/.claude/ralph-loop/docs/`
- **Issues:** https://github.com/edumesones/not-code-claude-runs-you-pilot/issues
- **PR:** https://github.com/edumesones/not-code-claude-runs-you-pilot/pulls

---

**Happy coding with Ralph Loop!** 🚀
