# Memory-MCP Implementation Guide

## Quick Start

This guide provides step-by-step instructions to integrate Memory-MCP with Ralph Loop.

---

## Prerequisites

- Node.js 18+ installed
- Git configured
- Claude Code CLI installed
- Ralph Loop project set up

---

## Step 1: Install Memory-MCP

### 1.1 Clone Memory-MCP Repository

```bash
# Navigate to your Ralph Loop project
cd /path/to/ralph-loop-project

# Clone Memory-MCP into a subdirectory
git clone https://github.com/yuvalsuede/memory-mcp.git .memory-system
cd .memory-system

# Install dependencies
npm install

# Build the project
npm run build
```

### 1.2 Create Memory Storage Directory

```bash
# Return to project root
cd ..

# Create memory storage
mkdir -p .memory
mkdir -p .memory/snapshots

# Create initial state
cat > .memory/state.json << 'EOF'
{
  "memories": [],
  "metadata": {
    "total_memories": 0,
    "last_consolidation": null,
    "confidence_avg": 0,
    "features_processed": []
  }
}
EOF
```

### 1.3 Configure MCP Server

```bash
# Update Claude Code config
mkdir -p ~/.claude
cat > ~/.claude/claude_desktop_config.json << 'EOF'
{
  "mcpServers": {
    "memory": {
      "command": "node",
      "args": ["/path/to/your/project/.memory-system/build/index.js"],
      "env": {
        "MEMORY_DIR": "/path/to/your/project/.memory"
      }
    }
  }
}
EOF
```

**Important**: Replace `/path/to/your/project` with actual path.

---

## Step 2: Create Memory Extraction Scripts

### 2.1 Create Extraction Script

```bash
# Create scripts directory
mkdir -p .memory-system/scripts

# Create extraction script
cat > .memory-system/scripts/extract-memory.js << 'EOF'
#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

/**
 * Extract memories from Ralph Loop phase output
 */
class MemoryExtractor {
  constructor(memoryDir) {
    this.memoryDir = memoryDir;
    this.stateFile = path.join(memoryDir, 'state.json');
  }

  loadState() {
    if (!fs.existsSync(this.stateFile)) {
      return {
        memories: [],
        metadata: {
          total_memories: 0,
          last_consolidation: null,
          confidence_avg: 0,
          features_processed: []
        }
      };
    }
    return JSON.parse(fs.readFileSync(this.stateFile, 'utf8'));
  }

  saveState(state) {
    fs.writeFileSync(this.stateFile, JSON.stringify(state, null, 2));
  }

  generateId() {
    return `mem-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
  }

  /**
   * Extract memories from Interview phase
   */
  extractFromInterview(featureId, specContent) {
    const memories = [];

    // Parse Technical Decisions table from spec.md
    const decisionsMatch = specContent.match(/## Technical Decisions\n\n([\s\S]*?)(?=\n##|\n$)/);
    if (decisionsMatch) {
      const tableRows = decisionsMatch[1].split('\n').filter(line => line.includes('|'));

      tableRows.slice(2).forEach(row => { // Skip header and separator
        const cells = row.split('|').map(c => c.trim()).filter(Boolean);
        if (cells.length >= 4 && cells[3] !== 'TBD') {
          memories.push({
            id: this.generateId(),
            category: 'Decisions',
            content: `${featureId}: ${cells[2]} → ${cells[3]}. ${cells[4] || ''}`,
            confidence: 0.8,
            source: {
              feature: featureId,
              phase: 'Interview',
              timestamp: new Date().toISOString()
            },
            tags: [cells[1].toLowerCase()],
            references: [`docs/features/${featureId}/spec.md`],
            supersedes: null
          });
        }
      });
    }

    return memories;
  }

  /**
   * Extract memories from Think Critically phase
   */
  extractFromAnalysis(featureId, analysisContent) {
    const memories = [];

    // Extract assumptions
    const assumptionsMatch = analysisContent.match(/## Step 2: Assumptions([\s\S]*?)(?=\n##|\n$)/);
    if (assumptionsMatch) {
      const assumptionBlocks = assumptionsMatch[1].split(/\n\d+\.\s+/).filter(Boolean);

      assumptionBlocks.forEach(block => {
        const contentMatch = block.match(/\*\*Assumption:\*\*\s+(.*?)\n/);
        const impactMatch = block.match(/\*\*Impact:\*\*\s+(.*?)\n/);
        const confidenceMatch = block.match(/\*\*Confidence:\*\*\s+(.*?)\n/);

        if (contentMatch) {
          memories.push({
            id: this.generateId(),
            category: 'Decisions',
            content: `${featureId}: Assumption - ${contentMatch[1]}`,
            confidence: confidenceMatch[1] === 'High' ? 0.9 : confidenceMatch[1] === 'Medium' ? 0.7 : 0.5,
            source: {
              feature: featureId,
              phase: 'Analysis',
              timestamp: new Date().toISOString(),
              context: impactMatch ? impactMatch[1] : ''
            },
            tags: ['assumption', 'analysis'],
            references: [`docs/features/${featureId}/analysis.md`],
            supersedes: null
          });
        }
      });
    }

    // Extract failure modes as gotchas
    const failuresMatch = analysisContent.match(/## Step 5: Failure Analysis([\s\S]*?)(?=\n##|\n$)/);
    if (failuresMatch) {
      const failureBlocks = failuresMatch[1].split(/\n\d+\.\s+/).filter(Boolean);

      failureBlocks.forEach(block => {
        const scenarioMatch = block.match(/\*\*Scenario:\*\*\s+(.*?)\n/);
        const mitigationMatch = block.match(/\*\*Mitigation:\*\*\s+(.*?)\n/);

        if (scenarioMatch) {
          memories.push({
            id: this.generateId(),
            category: 'Gotchas',
            content: `${featureId}: ${scenarioMatch[1]}. Mitigation: ${mitigationMatch ? mitigationMatch[1] : 'None'}`,
            confidence: 0.85,
            source: {
              feature: featureId,
              phase: 'Analysis',
              timestamp: new Date().toISOString()
            },
            tags: ['failure-mode', 'risk'],
            references: [`docs/features/${featureId}/analysis.md`],
            supersedes: null
          });
        }
      });
    }

    return memories;
  }

  /**
   * Extract memories from Plan phase
   */
  extractFromPlan(featureId, designContent) {
    const memories = [];

    // Extract architecture decisions
    const archMatch = designContent.match(/## Architecture([\s\S]*?)(?=\n##|\n$)/);
    if (archMatch) {
      const patterns = archMatch[1].split('\n').filter(line => line.trim().startsWith('-'));

      patterns.forEach(pattern => {
        const content = pattern.replace(/^-\s+/, '').trim();
        if (content) {
          memories.push({
            id: this.generateId(),
            category: 'Architecture',
            content: `${featureId}: ${content}`,
            confidence: 0.9,
            source: {
              feature: featureId,
              phase: 'Plan',
              timestamp: new Date().toISOString()
            },
            tags: ['architecture', 'pattern'],
            references: [`docs/features/${featureId}/design.md`],
            supersedes: null
          });
        }
      });
    }

    return memories;
  }

  /**
   * Extract memories from Implement phase
   */
  extractFromImplementation(featureId, tasksContent, commitMessages) {
    const memories = [];

    // Extract patterns from commit messages
    const patternRegex = /feat|fix|refactor|perf|style|test/gi;
    commitMessages.forEach(msg => {
      if (patternRegex.test(msg)) {
        memories.push({
          id: this.generateId(),
          category: 'Patterns',
          content: `${featureId}: ${msg}`,
          confidence: 0.7,
          source: {
            feature: featureId,
            phase: 'Implement',
            timestamp: new Date().toISOString()
          },
          tags: ['implementation', 'commit'],
          references: [],
          supersedes: null
        });
      }
    });

    return memories;
  }

  /**
   * Extract memories from Wrap-Up phase
   */
  extractFromWrapUp(featureId, wrapUpContent) {
    const memories = [];

    // Extract learnings
    const learningsMatch = wrapUpContent.match(/## Key Learnings([\s\S]*?)(?=\n##|\n$)/);
    if (learningsMatch) {
      const learnings = learningsMatch[1].split('\n').filter(line => line.trim().startsWith('-'));

      learnings.forEach(learning => {
        const content = learning.replace(/^-\s+/, '').trim();
        if (content) {
          memories.push({
            id: this.generateId(),
            category: 'Progress',
            content: `${featureId}: ${content}`,
            confidence: 0.95,
            source: {
              feature: featureId,
              phase: 'WrapUp',
              timestamp: new Date().toISOString()
            },
            tags: ['learning', 'retrospective'],
            references: [`docs/features/${featureId}/context/wrap_up.md`],
            supersedes: null
          });
        }
      });
    }

    // Extract gotchas
    const gotchasMatch = wrapUpContent.match(/## Gotchas Encountered([\s\S]*?)(?=\n##|\n$)/);
    if (gotchasMatch) {
      const gotchas = gotchasMatch[1].split('\n').filter(line => line.trim().startsWith('-'));

      gotchas.forEach(gotcha => {
        const content = gotcha.replace(/^-\s+/, '').trim();
        if (content) {
          memories.push({
            id: this.generateId(),
            category: 'Gotchas',
            content: `${featureId}: ${content}`,
            confidence: 0.98,
            source: {
              feature: featureId,
              phase: 'WrapUp',
              timestamp: new Date().toISOString()
            },
            tags: ['gotcha', 'production'],
            references: [`docs/features/${featureId}/context/wrap_up.md`],
            supersedes: null
          });
        }
      });
    }

    return memories;
  }

  /**
   * Add memories to state
   */
  addMemories(memories) {
    const state = this.loadState();

    // Deduplicate using Jaccard similarity
    memories.forEach(newMemory => {
      const isDuplicate = state.memories.some(existing => {
        const similarity = this.jaccardSimilarity(
          newMemory.content.toLowerCase(),
          existing.content.toLowerCase()
        );
        return similarity > 0.8;
      });

      if (!isDuplicate) {
        state.memories.push(newMemory);

        // Update features_processed
        if (!state.metadata.features_processed.includes(newMemory.source.feature)) {
          state.metadata.features_processed.push(newMemory.source.feature);
        }
      }
    });

    // Update metadata
    state.metadata.total_memories = state.memories.length;
    state.metadata.last_consolidation = new Date().toISOString();
    state.metadata.confidence_avg =
      state.memories.reduce((sum, m) => sum + m.confidence, 0) / state.memories.length;

    this.saveState(state);
    return state;
  }

  /**
   * Calculate Jaccard similarity between two strings
   */
  jaccardSimilarity(str1, str2) {
    const set1 = new Set(str1.split(/\s+/));
    const set2 = new Set(str2.split(/\s+/));

    const intersection = new Set([...set1].filter(x => set2.has(x)));
    const union = new Set([...set1, ...set2]);

    return intersection.size / union.size;
  }

  /**
   * Decay confidence over time
   */
  decayConfidence(daysOld) {
    const decayRate = 0.01; // 1% per day
    return Math.max(0.3, 1 - (daysOld * decayRate));
  }

  /**
   * Apply confidence decay to all memories
   */
  applyDecay() {
    const state = this.loadState();
    const now = new Date();

    state.memories.forEach(memory => {
      const memoryDate = new Date(memory.source.timestamp);
      const daysOld = (now - memoryDate) / (1000 * 60 * 60 * 24);

      const decayFactor = this.decayConfidence(daysOld);
      memory.confidence = Math.min(memory.confidence, decayFactor);
    });

    // Remove memories with very low confidence
    state.memories = state.memories.filter(m => m.confidence > 0.3);

    this.saveState(state);
  }
}

// CLI Interface
const [,, command, ...args] = process.argv;

const extractor = new MemoryExtractor(process.env.MEMORY_DIR || '.memory');

switch (command) {
  case 'interview':
    const [featureId, specPath] = args;
    const specContent = fs.readFileSync(specPath, 'utf8');
    const interviewMemories = extractor.extractFromInterview(featureId, specContent);
    const state1 = extractor.addMemories(interviewMemories);
    console.log(`Extracted ${interviewMemories.length} memories from Interview phase`);
    break;

  case 'analysis':
    const [featureId2, analysisPath] = args;
    const analysisContent = fs.readFileSync(analysisPath, 'utf8');
    const analysisMemories = extractor.extractFromAnalysis(featureId2, analysisContent);
    const state2 = extractor.addMemories(analysisMemories);
    console.log(`Extracted ${analysisMemories.length} memories from Analysis phase`);
    break;

  case 'plan':
    const [featureId3, designPath] = args;
    const designContent = fs.readFileSync(designPath, 'utf8');
    const planMemories = extractor.extractFromPlan(featureId3, designContent);
    const state3 = extractor.addMemories(planMemories);
    console.log(`Extracted ${planMemories.length} memories from Plan phase`);
    break;

  case 'wrapup':
    const [featureId4, wrapUpPath] = args;
    const wrapUpContent = fs.readFileSync(wrapUpPath, 'utf8');
    const wrapUpMemories = extractor.extractFromWrapUp(featureId4, wrapUpContent);
    const state4 = extractor.addMemories(wrapUpMemories);
    console.log(`Extracted ${wrapUpMemories.length} memories from WrapUp phase`);
    break;

  case 'decay':
    extractor.applyDecay();
    console.log('Applied confidence decay to all memories');
    break;

  default:
    console.log('Usage: extract-memory.js <command> <args>');
    console.log('Commands:');
    console.log('  interview <featureId> <specPath>');
    console.log('  analysis <featureId> <analysisPath>');
    console.log('  plan <featureId> <designPath>');
    console.log('  wrapup <featureId> <wrapUpPath>');
    console.log('  decay');
}
EOF

# Make executable
chmod +x .memory-system/scripts/extract-memory.js
```

### 2.2 Create Consolidation Script

```bash
cat > .memory-system/scripts/consolidate-claude-md.js << 'EOF'
#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

/**
 * Consolidate memories into CLAUDE.md
 */
class ClaudeMdGenerator {
  constructor(memoryDir, maxLines = 150) {
    this.memoryDir = memoryDir;
    this.maxLines = maxLines;
    this.stateFile = path.join(memoryDir, 'state.json');
  }

  loadState() {
    return JSON.parse(fs.readFileSync(this.stateFile, 'utf8'));
  }

  /**
   * Generate CLAUDE.md from memories
   */
  generate() {
    const state = this.loadState();
    const memories = state.memories;

    // Group by category
    const byCategory = memories.reduce((acc, memory) => {
      if (!acc[memory.category]) acc[memory.category] = [];
      acc[memory.category].push(memory);
      return acc;
    }, {});

    // Sort by confidence
    Object.keys(byCategory).forEach(category => {
      byCategory[category].sort((a, b) => b.confidence - a.confidence);
    });

    let output = [];
    output.push('# Project Context (Auto-Generated by Memory-MCP)');
    output.push('');
    output.push(`> Last updated: ${new Date().toISOString()}`);
    output.push(`> Features: ${state.metadata.features_processed.length} | Memories: ${state.metadata.total_memories}`);
    output.push('');

    // Add top memories by category
    const categoriesToInclude = ['Architecture', 'Decisions', 'Patterns', 'Gotchas', 'Progress'];

    categoriesToInclude.forEach(category => {
      if (byCategory[category] && byCategory[category].length > 0) {
        output.push(`## ${category}`);
        output.push('');

        // Take top N memories
        const topMemories = byCategory[category].slice(0, 10);
        topMemories.forEach(memory => {
          const confidenceEmoji = memory.confidence > 0.9 ? '✅' : memory.confidence > 0.7 ? '🟡' : '⚠️';
          output.push(`- ${confidenceEmoji} ${memory.content.replace(/^FEAT-\d+-[^:]+:\s*/, '')}`);

          if (memory.references && memory.references.length > 0) {
            output.push(`  - _Source: ${memory.references[0]}_`);
          }
        });
        output.push('');
      }
    });

    // Add feature progress
    output.push('## Current Progress');
    output.push('');
    state.metadata.features_processed.forEach(featureId => {
      const featureMemories = memories.filter(m => m.source.feature === featureId);
      const hasWrapUp = featureMemories.some(m => m.source.phase === 'WrapUp');
      const status = hasWrapUp ? '✅' : '🟡';
      output.push(`- ${status} ${featureId}`);
    });
    output.push('');

    output.push('---');
    output.push('');
    output.push('*For detailed memories, query `.memory/state.json` via MCP tools*');

    const content = output.join('\n');

    // Trim to max lines if needed
    const lines = content.split('\n');
    if (lines.length > this.maxLines) {
      return lines.slice(0, this.maxLines).join('\n') + '\n\n_...truncated..._';
    }

    return content;
  }

  /**
   * Write CLAUDE.md to project root
   */
  writeToClaude() {
    const content = this.generate();
    const outputPath = path.join(process.cwd(), 'CLAUDE.md');
    fs.writeFileSync(outputPath, content, 'utf8');
    console.log(`Generated CLAUDE.md (${content.split('\n').length} lines)`);
  }
}

// CLI Interface
const generator = new ClaudeMdGenerator(process.env.MEMORY_DIR || '.memory', 150);
generator.writeToClaude();
EOF

chmod +x .memory-system/scripts/consolidate-claude-md.js
```

---

## Step 3: Integrate with Ralph Loop

### 3.1 Modify ralph-feature.sh

Add memory extraction after each phase:

```bash
# Add after Interview phase
if [ "$PHASE" = "interview" ]; then
  # ... existing interview code ...

  # Extract memories
  node .memory-system/scripts/extract-memory.js interview \
    "$FEATURE_ID" \
    "docs/features/$FEATURE_ID/spec.md"

  # Update CLAUDE.md
  node .memory-system/scripts/consolidate-claude-md.js

  # Commit memory updates
  git add .memory/ CLAUDE.md
  git commit -m "memory: Captured Interview phase for $FEATURE_ID"
fi

# Add after Think Critically phase
if [ "$PHASE" = "analysis" ]; then
  # ... existing analysis code ...

  node .memory-system/scripts/extract-memory.js analysis \
    "$FEATURE_ID" \
    "docs/features/$FEATURE_ID/analysis.md"

  node .memory-system/scripts/consolidate-claude-md.js

  git add .memory/ CLAUDE.md
  git commit -m "memory: Captured Analysis phase for $FEATURE_ID"
fi

# Add after Plan phase
if [ "$PHASE" = "plan" ]; then
  # ... existing plan code ...

  node .memory-system/scripts/extract-memory.js plan \
    "$FEATURE_ID" \
    "docs/features/$FEATURE_ID/design.md"

  node .memory-system/scripts/consolidate-claude-md.js

  git add .memory/ CLAUDE.md
  git commit -m "memory: Captured Plan phase for $FEATURE_ID"
fi

# Add after Wrap-Up phase
if [ "$PHASE" = "wrapup" ]; then
  # ... existing wrapup code ...

  node .memory-system/scripts/extract-memory.js wrapup \
    "$FEATURE_ID" \
    "docs/features/$FEATURE_ID/context/wrap_up.md"

  node .memory-system/scripts/consolidate-claude-md.js

  git add .memory/ CLAUDE.md
  git commit -m "memory: Captured WrapUp phase for $FEATURE_ID"

  # Apply confidence decay
  node .memory-system/scripts/extract-memory.js decay
fi
```

### 3.2 Add Memory Context to Claude Prompts

Before each phase, load relevant memories:

```bash
# Add before calling Claude for each phase
MEMORY_CONTEXT=$(mcp-cli call memory/search "{
  \"query\": \"phase:${PHASE} category:Decisions\",
  \"limit\": 5
}" 2>/dev/null || echo "")

# Include in Claude prompt
PROMPT="<memory-context>
${MEMORY_CONTEXT}
</memory-context>

Execute ${PHASE} phase for ${FEATURE_ID}..."
```

---

## Step 4: Testing the Integration

### 4.1 Test with Single Feature

```bash
# Create test feature
mkdir -p docs/features/FEAT-TEST-memory/context
cp docs/features/_template/* docs/features/FEAT-TEST-memory/

# Run Ralph Loop
./ralph-feature.sh FEAT-TEST-memory 10

# Check memory state
cat .memory/state.json | jq '.metadata'

# Check CLAUDE.md
cat CLAUDE.md
```

### 4.2 Verify Memory Extraction

```bash
# After Interview phase
node .memory-system/scripts/extract-memory.js interview \
  FEAT-TEST-memory \
  docs/features/FEAT-TEST-memory/spec.md

# Check extracted memories
cat .memory/state.json | jq '.memories[] | select(.source.phase == "Interview")'
```

### 4.3 Test Memory Search

```bash
# Search for decisions
mcp-cli call memory/search '{"query": "category:Decisions", "limit": 5}'

# Search by feature
mcp-cli call memory/search '{"query": "feature:FEAT-TEST-memory", "limit": 10}'

# Search by phase
mcp-cli call memory/search '{"query": "phase:Interview", "limit": 5}'
```

---

## Step 5: Daily Operations

### 5.1 View Memory Dashboard

```bash
# Check memory statistics
cat .memory/state.json | jq '.metadata'

# List all features processed
cat .memory/state.json | jq '.metadata.features_processed[]'

# Count memories by category
cat .memory/state.json | jq '.memories | group_by(.category) | map({category: .[0].category, count: length})'
```

### 5.2 Apply Confidence Decay

```bash
# Run weekly to decay old memories
node .memory-system/scripts/extract-memory.js decay

# Update CLAUDE.md
node .memory-system/scripts/consolidate-claude-md.js
```

### 5.3 Backup Memory State

```bash
# Create daily backup
cp .memory/state.json .memory/snapshots/state-$(date +%Y%m%d).json

# Keep last 30 days
find .memory/snapshots -name "state-*.json" -mtime +30 -delete
```

---

## Step 6: Advanced Features

### 6.1 Memory Search MCP Tool

Create `.memory-system/mcp-tools/search.js`:

```javascript
/**
 * MCP Tool: memory/search
 * Search memories by query
 */
async function search({ query, limit = 10 }) {
  const state = JSON.parse(fs.readFileSync('.memory/state.json', 'utf8'));

  // Parse query
  const filters = {};
  query.split(' ').forEach(term => {
    const [key, value] = term.split(':');
    if (value) filters[key] = value;
  });

  // Filter memories
  let results = state.memories;

  if (filters.category) {
    results = results.filter(m => m.category === filters.category);
  }

  if (filters.phase) {
    results = results.filter(m => m.source.phase === filters.phase);
  }

  if (filters.feature) {
    results = results.filter(m => m.source.feature.includes(filters.feature));
  }

  // Sort by confidence
  results.sort((a, b) => b.confidence - a.confidence);

  // Limit results
  results = results.slice(0, limit);

  return {
    total: results.length,
    memories: results.map(m => ({
      category: m.category,
      content: m.content,
      confidence: m.confidence,
      source: m.source
    }))
  };
}

module.exports = { search };
```

### 6.2 Memory Synthesis Tool

Create `.memory-system/mcp-tools/synthesize.js`:

```javascript
/**
 * MCP Tool: memory/synthesize
 * Generate summary from memories
 */
async function synthesize({ topic, features = [] }) {
  const state = JSON.parse(fs.readFileSync('.memory/state.json', 'utf8'));

  // Filter by features if provided
  let memories = state.memories;
  if (features.length > 0) {
    memories = memories.filter(m => features.includes(m.source.feature));
  }

  // Filter by topic (keyword search in content)
  const topicLower = topic.toLowerCase();
  memories = memories.filter(m =>
    m.content.toLowerCase().includes(topicLower) ||
    m.tags.some(tag => tag.includes(topicLower))
  );

  // Group by category
  const byCategory = memories.reduce((acc, m) => {
    if (!acc[m.category]) acc[m.category] = [];
    acc[m.category].push(m);
    return acc;
  }, {});

  // Generate summary
  let summary = `# Synthesis: ${topic}\n\n`;
  summary += `Found ${memories.length} relevant memories across ${Object.keys(byCategory).length} categories.\n\n`;

  Object.entries(byCategory).forEach(([category, mems]) => {
    summary += `## ${category} (${mems.length})\n\n`;
    mems.slice(0, 5).forEach(m => {
      summary += `- ${m.content}\n`;
      summary += `  - Confidence: ${(m.confidence * 100).toFixed(0)}%\n`;
      summary += `  - Source: ${m.source.feature} (${m.source.phase})\n\n`;
    });
  });

  return { summary };
}

module.exports = { synthesize };
```

---

## Troubleshooting

### Issue 1: Memory not being extracted

**Symptoms**: `.memory/state.json` is empty

**Solution:**
```bash
# Check if extraction script is executable
ls -l .memory-system/scripts/extract-memory.js

# Make executable if needed
chmod +x .memory-system/scripts/extract-memory.js

# Test manually
node .memory-system/scripts/extract-memory.js interview FEAT-001 docs/features/FEAT-001/spec.md
```

### Issue 2: CLAUDE.md not updating

**Symptoms**: CLAUDE.md is outdated

**Solution:**
```bash
# Regenerate CLAUDE.md
node .memory-system/scripts/consolidate-claude-md.js

# Check if there are memories
cat .memory/state.json | jq '.memories | length'
```

### Issue 3: MCP tools not working

**Symptoms**: `mcp-cli call memory/search` fails

**Solution:**
```bash
# Check MCP server config
cat ~/.claude/claude_desktop_config.json

# Restart Claude Code
# Then test connection
mcp-cli servers
```

---

## Metrics to Track

After integration, monitor:

1. **Memory Growth**
   - Memories per feature
   - Categories distribution
   - Average confidence score

2. **Context Quality**
   - CLAUDE.md line count
   - Memories referenced per phase
   - Decision auto-fill rate

3. **Time Savings**
   - Interview duration (should decrease)
   - Analysis depth (gotchas found from memory)
   - Implementation speed (patterns suggested)

---

## Next Steps

1. Run first feature with memory integration
2. Review extracted memories for quality
3. Tune confidence thresholds
4. Add more extraction patterns
5. Build memory visualization dashboard

---

*Guide Version: 1.0*
*Last Updated: 2025-01-23*
