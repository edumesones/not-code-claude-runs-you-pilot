#!/bin/bash
###############################################################################
# Ralph Loop - Smart Installer
# Supports both global and project-level installation with intelligent merge
###############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

echo -e "${CYAN}"
cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║               RALPH LOOP METHODOLOGY                         ║
║            Smart Installer for Claude Code                   ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo ""
echo -e "${BLUE}This installer supports:${NC}"
echo -e "  • ${GREEN}Global installation${NC} - Available in ALL projects"
echo -e "  • ${GREEN}Project-level installation${NC} - Only in current project"
echo -e "  • ${GREEN}Intelligent merge${NC} - Preserves existing configuration"
echo ""

# Function to ask yes/no
ask_yn() {
    local prompt="$1"
    local default="${2:-n}"

    if [ "$default" = "y" ]; then
        prompt="$prompt [Y/n]: "
    else
        prompt="$prompt [y/N]: "
    fi

    read -p "$prompt" response
    response=${response:-$default}

    [[ "$response" =~ ^[Yy]$ ]]
}

# Function to merge files
merge_file() {
    local source="$1"
    local dest="$2"
    local name="$(basename "$dest")"

    if [ -f "$dest" ]; then
        echo -e "${YELLOW}  ⚠ $name already exists${NC}"
        echo -e "${BLUE}    Current: $dest${NC}"

        if ask_yn "    Replace with Ralph Loop version?" "n"; then
            cp "$source" "$dest"
            echo -e "${GREEN}    ✓ Replaced${NC}"
        else
            local backup="${dest}.ralph-backup"
            cp "$source" "$backup"
            echo -e "${GREEN}    ✓ Ralph Loop version saved as: $(basename "$backup")${NC}"
            echo -e "${YELLOW}    ℹ You can manually merge later${NC}"
        fi
    else
        cp "$source" "$dest"
        echo -e "${GREEN}  ✓ Installed $name${NC}"
    fi
}

# Function to merge directory
merge_directory() {
    local source_dir="$1"
    local dest_dir="$2"
    local label="$3"

    mkdir -p "$dest_dir"

    local file_count=0
    local new_count=0
    local skip_count=0

    for file in "$source_dir"/*; do
        [ -e "$file" ] || continue

        local filename="$(basename "$file")"
        local dest_file="$dest_dir/$filename"

        file_count=$((file_count + 1))

        if [ -f "$dest_file" ]; then
            # File exists - check if it's different
            if ! diff -q "$file" "$dest_file" >/dev/null 2>&1; then
                echo -e "${YELLOW}  ⚠ $label/$filename already exists and is different${NC}"

                if ask_yn "    Replace with Ralph Loop version?" "n"; then
                    cp "$file" "$dest_file"
                    echo -e "${GREEN}    ✓ Replaced${NC}"
                    new_count=$((new_count + 1))
                else
                    cp "$file" "${dest_file}.ralph-backup"
                    echo -e "${GREEN}    ✓ Saved as ${filename}.ralph-backup${NC}"
                    skip_count=$((skip_count + 1))
                fi
            else
                echo -e "${BLUE}  ℹ $label/$filename (identical, skipped)${NC}"
                skip_count=$((skip_count + 1))
            fi
        else
            cp "$file" "$dest_file"
            echo -e "${GREEN}  ✓ Added $label/$filename${NC}"
            new_count=$((new_count + 1))
        fi
    done

    echo -e "${CYAN}  Summary: $new_count added, $skip_count skipped${NC}"
}

# Check prerequisites
echo -e "${YELLOW}[1/7] Checking prerequisites...${NC}"

if ! command -v git &> /dev/null; then
    echo -e "${RED}❌ Git required${NC}"
    exit 1
fi
echo -e "${GREEN}  ✓ Git${NC}"

command -v gh &> /dev/null && echo -e "${GREEN}  ✓ GitHub CLI${NC}" || echo -e "${YELLOW}  ⚠ GitHub CLI (optional)${NC}"
command -v claude &> /dev/null && echo -e "${GREEN}  ✓ Claude CLI${NC}" || echo -e "${YELLOW}  ⚠ Claude CLI (recommended)${NC}"
command -v node &> /dev/null && echo -e "${GREEN}  ✓ Node.js${NC}" || echo -e "${YELLOW}  ⚠ Node.js (for Memory-MCP)${NC}"

# Ask installation type
echo ""
echo -e "${YELLOW}[2/7] Choose installation type${NC}"
echo ""
echo -e "${MAGENTA}1) Global Installation${NC}"
echo -e "   • Installs to ${GREEN}~/.claude/${NC}"
echo -e "   • Available in ${GREEN}ALL projects${NC}"
echo -e "   • Commands/skills work everywhere"
echo ""
echo -e "${MAGENTA}2) Project-Level Installation${NC}"
echo -e "   • Installs to ${GREEN}./.claude/${NC} (current directory)"
echo -e "   • Only in ${GREEN}this project${NC}"
echo -e "   • Project-specific customization"
echo ""
echo -e "${MAGENTA}3) Both (Recommended)${NC}"
echo -e "   • Global: Core methodology"
echo -e "   • Project: Project-specific overrides"
echo ""

read -p "Choose [1/2/3]: " install_type

case $install_type in
    1)
        INSTALL_GLOBAL=true
        INSTALL_PROJECT=false
        echo -e "${GREEN}✓ Global installation selected${NC}"
        ;;
    2)
        INSTALL_GLOBAL=false
        INSTALL_PROJECT=true
        echo -e "${GREEN}✓ Project-level installation selected${NC}"
        ;;
    3)
        INSTALL_GLOBAL=true
        INSTALL_PROJECT=true
        echo -e "${GREEN}✓ Both installations selected${NC}"
        ;;
    *)
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac

# Global installation
if [ "$INSTALL_GLOBAL" = true ]; then
    echo ""
    echo -e "${YELLOW}[3/7] Installing globally to ~/.claude/${NC}"

    CLAUDE_HOME="$HOME/.claude"
    mkdir -p "$CLAUDE_HOME"
    mkdir -p "$CLAUDE_HOME/commands"
    mkdir -p "$CLAUDE_HOME/skills"
    mkdir -p "$CLAUDE_HOME/ralph-loop"

    # Backup existing CLAUDE.md
    if [ -f "$CLAUDE_HOME/CLAUDE.md" ]; then
        BACKUP="$CLAUDE_HOME/CLAUDE.md.backup-$(date +%Y%m%d-%H%M%S)"
        cp "$CLAUDE_HOME/CLAUDE.md" "$BACKUP"
        echo -e "${GREEN}  ✓ Backed up existing CLAUDE.md${NC}"
    fi

    # Install global CLAUDE.md
    merge_file "CLAUDE.md" "$CLAUDE_HOME/CLAUDE.md"

    # Merge commands
    if [ -d ".claude/commands" ]; then
        echo ""
        echo -e "${BLUE}  Installing commands...${NC}"
        merge_directory ".claude/commands" "$CLAUDE_HOME/commands" "commands"
    fi

    # Merge skills
    if [ -d ".claude/skills" ]; then
        echo ""
        echo -e "${BLUE}  Installing skills...${NC}"
        merge_directory ".claude/skills" "$CLAUDE_HOME/skills" "skills"
    fi

    # Copy scripts
    echo ""
    echo -e "${BLUE}  Installing scripts...${NC}"
    cp ralph-feature.sh "$CLAUDE_HOME/ralph-loop/"
    cp ralph-feature.ps1 "$CLAUDE_HOME/ralph-loop/"
    cp -r .memory-system "$CLAUDE_HOME/ralph-loop/" 2>/dev/null || true
    cp -r docs "$CLAUDE_HOME/ralph-loop/" 2>/dev/null || true
    chmod +x "$CLAUDE_HOME/ralph-loop/ralph-feature.sh"
    echo -e "${GREEN}  ✓ Scripts installed${NC}"

    echo -e "${GREEN}✅ Global installation complete${NC}"
fi

# Project installation
if [ "$INSTALL_PROJECT" = true ]; then
    echo ""
    echo -e "${YELLOW}[4/7] Installing to current project (./.claude/)${NC}"

    PROJECT_CLAUDE="./.claude"
    mkdir -p "$PROJECT_CLAUDE"
    mkdir -p "$PROJECT_CLAUDE/commands"
    mkdir -p "$PROJECT_CLAUDE/skills"

    # Check for existing project configuration
    if [ -f "$PROJECT_CLAUDE/CLAUDE.md" ]; then
        echo -e "${BLUE}  ℹ Existing project configuration detected${NC}"
    fi

    # Install project CLAUDE.md (optional override)
    if [ -f "CLAUDE.md" ]; then
        if [ -f "$PROJECT_CLAUDE/CLAUDE.md" ]; then
            echo -e "${YELLOW}  ⚠ Project already has CLAUDE.md${NC}"
            if ask_yn "    Add Ralph Loop instructions to it?" "y"; then
                cat >> "$PROJECT_CLAUDE/CLAUDE.md" << 'EOF'

# Ralph Loop Methodology

Ralph Loop is available in this project. See ~/.claude/ralph-loop/docs/ for documentation.

Quick commands:
- /ralph FEAT-XXX - Start autonomous feature development
- /interview FEAT-XXX - Interview phase
- /think-critically FEAT-XXX - Critical analysis
- /plan FEAT-XXX - Planning phase

EOF
                echo -e "${GREEN}    ✓ Appended Ralph Loop instructions${NC}"
            fi
        else
            cp "CLAUDE.md" "$PROJECT_CLAUDE/CLAUDE.md"
            echo -e "${GREEN}  ✓ Installed CLAUDE.md${NC}"
        fi
    fi

    # Merge commands
    if [ -d ".claude/commands" ]; then
        echo ""
        echo -e "${BLUE}  Installing commands...${NC}"
        merge_directory ".claude/commands" "$PROJECT_CLAUDE/commands" "commands"
    fi

    # Merge skills
    if [ -d ".claude/skills" ]; then
        echo ""
        echo -e "${BLUE}  Installing skills...${NC}"
        merge_directory ".claude/skills" "$PROJECT_CLAUDE/skills" "skills"
    fi

    # Copy scripts to project
    echo ""
    echo -e "${BLUE}  Installing scripts...${NC}"
    cp ralph-feature.sh ./ 2>/dev/null || true
    cp ralph-feature.ps1 ./ 2>/dev/null || true
    chmod +x ralph-feature.sh 2>/dev/null || true

    # Copy .memory-system if not exists
    if [ ! -d ".memory-system" ]; then
        cp -r .memory-system ./ 2>/dev/null || true
        echo -e "${GREEN}  ✓ Installed .memory-system${NC}"
    else
        echo -e "${BLUE}  ℹ .memory-system already exists (preserved)${NC}"
    fi

    # Copy docs if not exists
    if [ ! -d "docs/features" ]; then
        mkdir -p docs/features
        cp -r docs/features/_template docs/features/ 2>/dev/null || true
        cp docs/feature_cycle.md docs/ 2>/dev/null || true
        echo -e "${GREEN}  ✓ Installed docs/features/_template${NC}"
    else
        echo -e "${BLUE}  ℹ docs/features already exists (preserved)${NC}"
    fi

    echo -e "${GREEN}✅ Project-level installation complete${NC}"
fi

# Setup PATH
echo ""
echo -e "${YELLOW}[5/7] Setting up PATH...${NC}"

SHELL_RC=""
if [ -n "$BASH_VERSION" ]; then
    SHELL_RC="$HOME/.bashrc"
elif [ -n "$ZSH_VERSION" ]; then
    SHELL_RC="$HOME/.zshrc"
fi

if [ -n "$SHELL_RC" ] && [ "$INSTALL_GLOBAL" = true ]; then
    if ! grep -q "ralph-loop" "$SHELL_RC" 2>/dev/null; then
        echo "" >> "$SHELL_RC"
        echo "# Ralph Loop Methodology" >> "$SHELL_RC"
        echo "export PATH=\"\$HOME/.claude/ralph-loop:\$PATH\"" >> "$SHELL_RC"
        echo -e "${GREEN}  ✓ Added to $SHELL_RC${NC}"
        echo -e "${YELLOW}  ⚠ Run: source $SHELL_RC${NC}"
    else
        echo -e "${BLUE}  ℹ Already in PATH${NC}"
    fi
fi

# Install git hooks (optional)
echo ""
echo -e "${YELLOW}[6/7] Git hooks (security filters)${NC}"

if [ -d ".git" ] && ask_yn "Install security pre-commit hooks in this repo?" "y"; then
    if [ "$INSTALL_GLOBAL" = true ]; then
        bash "$HOME/.claude/ralph-loop/.memory-system/scripts/install-git-hooks.sh"
    else
        bash ".memory-system/scripts/install-git-hooks.sh"
    fi
    echo -e "${GREEN}  ✓ Git hooks installed${NC}"
else
    echo -e "${BLUE}  ℹ Skipped git hooks${NC}"
fi

# Summary
echo ""
echo -e "${YELLOW}[7/7] Installation summary${NC}"
echo ""

if [ "$INSTALL_GLOBAL" = true ]; then
    echo -e "${GREEN}✅ Global Installation${NC}"
    echo -e "   Location: ${CYAN}~/.claude/${NC}"
    echo -e "   • Commands: $(ls ~/.claude/commands 2>/dev/null | wc -l) installed"
    echo -e "   • Skills: $(ls ~/.claude/skills 2>/dev/null | wc -l) installed"
    echo -e "   • Scripts: ${CYAN}~/.claude/ralph-loop/${NC}"
    echo ""
fi

if [ "$INSTALL_PROJECT" = true ]; then
    echo -e "${GREEN}✅ Project Installation${NC}"
    echo -e "   Location: ${CYAN}./.claude/${NC}"
    echo -e "   • Commands: $(ls ./.claude/commands 2>/dev/null | wc -l) in project"
    echo -e "   • Skills: $(ls ./.claude/skills 2>/dev/null | wc -l) in project"
    echo -e "   • Scripts: ${CYAN}./ralph-feature.sh${NC}"
    echo ""
fi

# Final instructions
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                                                              ║${NC}"
echo -e "${CYAN}║            ✅ INSTALLATION COMPLETE!                          ║${NC}"
echo -e "${CYAN}║                                                              ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${BLUE}Usage:${NC}"
if [ "$INSTALL_GLOBAL" = true ]; then
    echo -e "  ${GREEN}Global:${NC} Use in ANY project"
    echo -e "    1. cd any-project"
    echo -e "    2. claude code ."
    echo -e "    3. Use commands: /ralph, /interview, etc."
    echo ""
fi

if [ "$INSTALL_PROJECT" = true ]; then
    echo -e "  ${GREEN}Project:${NC} Use in THIS project"
    echo -e "    1. claude code ."
    echo -e "    2. ./ralph-feature.sh FEAT-XXX"
    echo ""
fi

echo -e "${BLUE}Available Commands:${NC}"
echo -e "  • ${GREEN}/ralph FEAT-XXX${NC} - Start autonomous feature development"
echo -e "  • ${GREEN}/interview FEAT-XXX${NC} - Interview phase"
echo -e "  • ${GREEN}/think-critically FEAT-XXX${NC} - Critical analysis (11-step)"
echo -e "  • ${GREEN}/plan FEAT-XXX${NC} - Planning phase"
echo ""

echo -e "${BLUE}Documentation:${NC}"
if [ "$INSTALL_GLOBAL" = true ]; then
    echo -e "  • ${CYAN}~/.claude/ralph-loop/docs/feature_cycle.md${NC}"
    echo -e "  • ${CYAN}~/.claude/ralph-loop/docs/ralph-feature-loop.md${NC}"
fi
if [ "$INSTALL_PROJECT" = true ]; then
    echo -e "  • ${CYAN}./docs/feature_cycle.md${NC}"
fi
echo ""

echo -e "${BLUE}What's Next?${NC}"
echo -e "  1. Read quick start: ${GREEN}docs/feature_cycle.md${NC}"
echo -e "  2. Create a feature: ${GREEN}mkdir -p docs/features/FEAT-001${NC}"
echo -e "  3. Run Ralph Loop: ${GREEN}./ralph-feature.sh FEAT-001${NC}"
echo ""

echo -e "${MAGENTA}Happy coding with Ralph Loop! 🚀${NC}"
echo ""
