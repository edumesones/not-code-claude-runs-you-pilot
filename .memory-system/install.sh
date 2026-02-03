#!/bin/bash

###############################################################################
# Memory-MCP Installation Script for Ralph Loop
#
# This script sets up the complete memory system integration
###############################################################################

set -e  # Exit on error

echo "🚀 Memory-MCP Integration Installer"
echo "===================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get project root (parent of .memory-system)
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MEMORY_SYSTEM_DIR="$PROJECT_ROOT/.memory-system"
MEMORY_DIR="$PROJECT_ROOT/.memory"

echo "📂 Project root: $PROJECT_ROOT"
echo ""

###############################################################################
# Step 1: Check prerequisites
###############################################################################

echo "🔍 Step 1: Checking prerequisites..."

if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js not found. Please install Node.js 18+ first.${NC}"
    exit 1
fi

NODE_VERSION=$(node --version | cut -d 'v' -f 2 | cut -d '.' -f 1)
if [ "$NODE_VERSION" -lt 18 ]; then
    echo -e "${RED}❌ Node.js version must be 18 or higher (found: $(node --version))${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Node.js $(node --version) found${NC}"

if ! command -v git &> /dev/null; then
    echo -e "${RED}❌ Git not found. Please install Git first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Git $(git --version | cut -d ' ' -f 3) found${NC}"

###############################################################################
# Step 2: Create directory structure
###############################################################################

echo ""
echo "📁 Step 2: Creating directory structure..."

mkdir -p "$MEMORY_DIR/snapshots"
mkdir -p "$MEMORY_SYSTEM_DIR/scripts"
mkdir -p "$MEMORY_SYSTEM_DIR/logs"

echo -e "${GREEN}✅ Directories created${NC}"

###############################################################################
# Step 3: Initialize state.json (if not exists)
###############################################################################

echo ""
echo "💾 Step 3: Initializing memory state..."

STATE_FILE="$MEMORY_DIR/state.json"

if [ -f "$STATE_FILE" ]; then
    echo -e "${YELLOW}⚠️  state.json already exists, skipping...${NC}"
else
    cat > "$STATE_FILE" <<'EOF'
{
  "version": "1.0",
  "memories": [],
  "metadata": {
    "total_memories": 0,
    "last_consolidation": null,
    "confidence_avg": 0,
    "features_processed": [],
    "schema_version": "1.0.0",
    "created_at": "TIMESTAMP"
  },
  "config": {
    "confidence_decay_enabled": false,
    "confidence_decay_rate": 0.01,
    "max_memories": 2000,
    "deduplication_threshold": 0.8,
    "secret_detection_enabled": true
  }
}
EOF

    # Replace TIMESTAMP with actual timestamp
    TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/TIMESTAMP/$TIMESTAMP/" "$STATE_FILE"
    else
        sed -i "s/TIMESTAMP/$TIMESTAMP/" "$STATE_FILE"
    fi

    echo -e "${GREEN}✅ state.json initialized${NC}"
fi

###############################################################################
# Step 4: Make scripts executable
###############################################################################

echo ""
echo "🔧 Step 4: Making scripts executable..."

chmod +x "$MEMORY_SYSTEM_DIR/scripts/extract-memory.js"
chmod +x "$MEMORY_SYSTEM_DIR/scripts/consolidate-claude-md.js"
chmod +x "$MEMORY_SYSTEM_DIR/install.sh"

echo -e "${GREEN}✅ Scripts are now executable${NC}"

###############################################################################
# Step 5: Test installation
###############################################################################

echo ""
echo "🧪 Step 5: Testing installation..."

# Test extract-memory.js
if node "$MEMORY_SYSTEM_DIR/scripts/extract-memory.js" stats > /dev/null 2>&1; then
    echo -e "${GREEN}✅ extract-memory.js working${NC}"
else
    echo -e "${RED}❌ extract-memory.js failed${NC}"
    exit 1
fi

# Test consolidate-claude-md.js
export MEMORY_DIR="$MEMORY_DIR"
export OUTPUT_FILE="$PROJECT_ROOT/CLAUDE.md.test"
if node "$MEMORY_SYSTEM_DIR/scripts/consolidate-claude-md.js" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ consolidate-claude-md.js working${NC}"
    rm -f "$PROJECT_ROOT/CLAUDE.md.test" "$PROJECT_ROOT/CLAUDE.md.test.backup"
else
    echo -e "${RED}❌ consolidate-claude-md.js failed${NC}"
    exit 1
fi

###############################################################################
# Step 6: Create .gitignore entries
###############################################################################

echo ""
echo "📝 Step 6: Configuring Git ignore..."

GITIGNORE="$PROJECT_ROOT/.gitignore"

if [ -f "$GITIGNORE" ]; then
    # Check if memory entries already exist
    if ! grep -q ".memory/snapshots/" "$GITIGNORE"; then
        echo "" >> "$GITIGNORE"
        echo "# Memory-MCP (keep state.json, ignore snapshots)" >> "$GITIGNORE"
        echo ".memory/snapshots/" >> "$GITIGNORE"
        echo ".memory-system/logs/" >> "$GITIGNORE"
        echo "CLAUDE.md.backup" >> "$GITIGNORE"
        echo -e "${GREEN}✅ Added entries to .gitignore${NC}"
    else
        echo -e "${YELLOW}⚠️  .gitignore entries already exist${NC}"
    fi
else
    cat > "$GITIGNORE" <<'EOF'
# Memory-MCP
.memory/snapshots/
.memory-system/logs/
CLAUDE.md.backup
EOF
    echo -e "${GREEN}✅ Created .gitignore${NC}"
fi

###############################################################################
# Step 7: Generate initial CLAUDE.md
###############################################################################

echo ""
echo "📄 Step 7: Generating initial CLAUDE.md..."

export MEMORY_DIR="$MEMORY_DIR"
export OUTPUT_FILE="$PROJECT_ROOT/CLAUDE.md"

node "$MEMORY_SYSTEM_DIR/scripts/consolidate-claude-md.js"

echo -e "${GREEN}✅ CLAUDE.md generated${NC}"

###############################################################################
# Step 8: Installation complete
###############################################################################

echo ""
echo "=========================================="
echo -e "${GREEN}🎉 Installation Complete!${NC}"
echo "=========================================="
echo ""
echo "📊 Memory Statistics:"
node "$MEMORY_SYSTEM_DIR/scripts/extract-memory.js" stats
echo ""
echo "📝 Next Steps:"
echo ""
echo "1. Test with a feature:"
echo "   cd docs/features"
echo "   mkdir -p FEAT-TEST/context"
echo "   # Create spec.md with Technical Decisions table"
echo ""
echo "2. Extract memories:"
echo "   node .memory-system/scripts/extract-memory.js interview FEAT-TEST docs/features/FEAT-TEST/spec.md"
echo ""
echo "3. Generate CLAUDE.md:"
echo "   node .memory-system/scripts/consolidate-claude-md.js"
echo ""
echo "4. View CLAUDE.md:"
echo "   cat CLAUDE.md"
echo ""
echo "📚 Documentation:"
echo "   - Integration Plan: docs/memory-integration-plan.md"
echo "   - Implementation Guide: docs/memory-implementation-guide.md"
echo "   - Examples: docs/memory-integration-examples.md"
echo ""
echo -e "${GREEN}✨ Memory system ready to use!${NC}"
