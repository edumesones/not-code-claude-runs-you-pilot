#!/bin/bash
###############################################################################
# Feature Development Methodology - Global Installation Script
# Installs methodology globally in ~/.claude/
###############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}"
cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║          FEATURE DEVELOPMENT METHODOLOGY                     ║
║         Global Installation for Claude Code                  ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo ""
echo -e "${BLUE}This will install the methodology globally in ~/.claude/${NC}"
echo -e "${BLUE}Available in ANY project you open with Claude Code${NC}"
echo ""

# Check prerequisites
echo -e "${YELLOW}[1/6] Checking prerequisites...${NC}"

if ! command -v git &> /dev/null; then
    echo -e "${RED}❌ Git not found. Please install git first.${NC}"
    exit 1
fi
echo -e "${GREEN}  ✓ Git found${NC}"

if ! command -v gh &> /dev/null; then
    echo -e "${YELLOW}  ⚠ GitHub CLI not found (optional but recommended)${NC}"
else
    echo -e "${GREEN}  ✓ GitHub CLI found${NC}"
fi

if ! command -v claude &> /dev/null; then
    echo -e "${YELLOW}  ⚠ Claude CLI not found (install from https://claude.ai/download)${NC}"
else
    echo -e "${GREEN}  ✓ Claude CLI found${NC}"
fi

if ! command -v node &> /dev/null; then
    echo -e "${YELLOW}  ⚠ Node.js not found (required for Memory-MCP features)${NC}"
else
    echo -e "${GREEN}  ✓ Node.js found${NC}"
fi

# Create Claude config directory
echo ""
echo -e "${YELLOW}[2/6] Creating ~/.claude/ directory structure...${NC}"

CLAUDE_HOME="$HOME/.claude"
mkdir -p "$CLAUDE_HOME"
mkdir -p "$CLAUDE_HOME/commands"
mkdir -p "$CLAUDE_HOME/skills"

echo -e "${GREEN}  ✓ Directories created${NC}"

# Backup existing CLAUDE.md if exists
echo ""
echo -e "${YELLOW}[3/6] Backing up existing configuration...${NC}"

if [ -f "$CLAUDE_HOME/CLAUDE.md" ]; then
    BACKUP_FILE="$CLAUDE_HOME/CLAUDE.md.backup-$(date +%Y%m%d-%H%M%S)"
    cp "$CLAUDE_HOME/CLAUDE.md" "$BACKUP_FILE"
    echo -e "${GREEN}  ✓ Existing CLAUDE.md backed up to: $BACKUP_FILE${NC}"
else
    echo -e "${BLUE}  ℹ No existing CLAUDE.md found${NC}"
fi

# Copy global CLAUDE.md
echo ""
echo -e "${YELLOW}[4/6] Installing global methodology instructions...${NC}"

cp CLAUDE.md "$CLAUDE_HOME/CLAUDE.md"
echo -e "${GREEN}  ✓ CLAUDE.md installed${NC}"

# Copy commands
if [ -d ".claude/commands" ]; then
    cp -r .claude/commands/* "$CLAUDE_HOME/commands/" 2>/dev/null || true
    echo -e "${GREEN}  ✓ Commands installed${NC}"
fi

# Copy skills
if [ -d ".claude/skills" ]; then
    cp -r .claude/skills/* "$CLAUDE_HOME/skills/" 2>/dev/null || true
    echo -e "${GREEN}  ✓ Skills installed${NC}"
fi

# Copy memory system and docs
echo ""
echo -e "${YELLOW}[5/6] Installing memory system and docs...${NC}"

cp -r .memory-system "$CLAUDE_HOME/" 2>/dev/null || true
cp -r docs "$CLAUDE_HOME/" 2>/dev/null || true

echo -e "${GREEN}  ✓ Memory system and docs installed${NC}"

# Setup complete
echo ""
echo -e "${YELLOW}[6/6] Setup complete${NC}"

# Installation complete
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                              ║${NC}"
echo -e "${GREEN}║            ✅ INSTALLATION COMPLETE!                          ║${NC}"
echo -e "${GREEN}║                                                              ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Methodology is now available GLOBALLY in Claude Code!${NC}"
echo ""
echo -e "${BLUE}Usage:${NC}"
echo -e "  1. Open ANY project in Claude Code"
echo -e "  2. Use commands: ${GREEN}/interview${NC}, ${GREEN}/think-critically${NC}"
echo ""
echo -e "${BLUE}What was installed:${NC}"
echo -e "  • ${GREEN}~/.claude/CLAUDE.md${NC} - Global instructions"
echo -e "  • ${GREEN}~/.claude/commands/${NC} - Custom commands"
echo -e "  • ${GREEN}~/.claude/skills/${NC} - Custom skills"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo -e "  1. ${GREEN}cd your-project${NC}"
echo -e "  2. ${GREEN}claude code .${NC}"
echo -e "  3. Use methodology commands!"
echo ""
echo -e "${BLUE}Documentation:${NC}"
echo -e "  • Quick start: ${GREEN}docs/feature_cycle.md${NC}"
echo ""
