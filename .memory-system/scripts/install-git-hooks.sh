#!/bin/bash
###############################################################################
# Install Git Hooks for Browser Automation Security
#
# Installs pre-commit hook that scans for secrets before allowing commits
###############################################################################

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  Git Hooks Installation - Browser Automation Security${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Get git root
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ $? -ne 0 ]; then
  echo -e "${RED}❌ Not a git repository${NC}"
  echo -e "${YELLOW}Run this script from inside a git repository${NC}"
  exit 1
fi

echo -e "${GREEN}✓${NC} Git repository: $GIT_ROOT"

# Check if .git/hooks directory exists
HOOKS_DIR="$GIT_ROOT/.git/hooks"
if [ ! -d "$HOOKS_DIR" ]; then
  echo -e "${YELLOW}⚠${NC}  Creating hooks directory: $HOOKS_DIR"
  mkdir -p "$HOOKS_DIR"
fi

# Path to hook templates
HOOK_TEMPLATE="$GIT_ROOT/.memory-system/git-hooks/pre-commit"
HOOK_DEST="$HOOKS_DIR/pre-commit"

# Check if template exists
if [ ! -f "$HOOK_TEMPLATE" ]; then
  echo -e "${RED}❌ Hook template not found: $HOOK_TEMPLATE${NC}"
  echo -e "${YELLOW}Expected location: .memory-system/git-hooks/pre-commit${NC}"
  exit 1
fi

# Backup existing hook if present
if [ -f "$HOOK_DEST" ]; then
  BACKUP_FILE="$HOOK_DEST.backup-$(date +%Y%m%d-%H%M%S)"
  echo -e "${YELLOW}⚠${NC}  Existing pre-commit hook found"
  echo -e "${YELLOW}⚠${NC}  Creating backup: $BACKUP_FILE"
  mv "$HOOK_DEST" "$BACKUP_FILE"
fi

# Copy hook template
echo -e "${GREEN}✓${NC} Installing pre-commit hook..."
cp "$HOOK_TEMPLATE" "$HOOK_DEST"

# Make executable
chmod +x "$HOOK_DEST"
echo -e "${GREEN}✓${NC} Hook is executable"

# Verify installation
if [ -f "$HOOK_DEST" ] && [ -x "$HOOK_DEST" ]; then
  echo ""
  echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║                 ✅ Installation Complete                  ║${NC}"
  echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "${CYAN}Pre-commit hook installed at:${NC}"
  echo -e "  $HOOK_DEST"
  echo ""
  echo -e "${CYAN}What happens now:${NC}"
  echo -e "  • Every git commit will scan for secrets in test results"
  echo -e "  • Commits are blocked if API keys, tokens, or passwords detected"
  echo -e "  • Run security filters to redact secrets before committing"
  echo ""
  echo -e "${CYAN}Test the hook:${NC}"
  echo -e "  git commit -m \"test commit\" --allow-empty"
  echo ""
  echo -e "${CYAN}Bypass the hook (NOT RECOMMENDED):${NC}"
  echo -e "  git commit --no-verify -m \"message\""
  echo ""
else
  echo -e "${RED}❌ Installation failed${NC}"
  exit 1
fi
