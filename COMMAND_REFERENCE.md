# Memory-MCP Integration - Command Reference

Quick reference guide for using the Memory-MCP integration with Ralph Loop.

---

## 🚀 Installation

### First Time Setup

```bash
# Navigate to project
cd /path/to/your/project

# Run installer
bash .memory-system/install.sh
```

**What it does:**
- ✅ Creates `.memory/` directory structure
- ✅ Initializes `state.json` with default config
- ✅ Makes scripts executable
- ✅ Generates initial `CLAUDE.md`
- ✅ Configures `.gitignore`

**Time:** ~1 minute

---

## 📊 Memory Statistics

### View Current State

```bash
node .memory-system/scripts/extract-memory.js stats
```

**Output:**
```
📊 Memory Statistics:
   Total memories: 127
   Avg confidence: 0.87
   Features processed: 3
   Last consolidation: 2025-02-02T19:30:00Z
   Schema version: 1.0.0

⚙️  Configuration:
   Decay enabled: false
   Decay rate: 0.01/day
   Max memories: 2000
   Dedup threshold: 0.8
   Secret detection: true
```

---

## 🧠 Extract Memories

### Interview Phase (spec.md)

```bash
node .memory-system/scripts/extract-memory.js interview \
  FEAT-001-auth \
  docs/features/FEAT-001-auth/spec.md
```

**Extracts:**
- Technical decisions from table
- Architectural choices
- Design constraints

**Time:** ~200ms

---

### Analysis Phase (analysis.md)

```bash
node .memory-system/scripts/extract-memory.js analysis \
  FEAT-001-auth \
  docs/features/FEAT-001-auth/analysis.md
```

**Extracts:**
- Assumptions with confidence levels
- Failure modes and mitigations
- Risk analysis

**Time:** ~300ms

---

### Plan Phase (design.md)

```bash
node .memory-system/scripts/extract-memory.js plan \
  FEAT-001-auth \
  docs/features/FEAT-001-auth/design.md
```

**Extracts:**
- Architecture patterns
- Design decisions
- Component structure

**Time:** ~200ms

---

### Wrap-Up Phase (wrap_up.md)

```bash
node .memory-system/scripts/extract-memory.js wrapup \
  FEAT-001-auth \
  docs/features/FEAT-001-auth/context/wrap_up.md
```

**Extracts:**
- Key learnings
- Gotchas encountered
- Production insights

**Time:** ~200ms

---

## 📄 Generate CLAUDE.md

### Create/Update Context File

```bash
node .memory-system/scripts/consolidate-claude-md.js
```

**What it does:**
- Reads all memories from `state.json`
- Prioritizes by confidence + recency
- Generates `CLAUDE.md` (<150 lines)
- Creates backup of previous version

**Output:** `CLAUDE.md` at project root

**Time:** ~100ms

---

## 🔄 Confidence Decay

### Apply Time-Based Decay

```bash
node .memory-system/scripts/extract-memory.js decay
```

**What it does:**
- Reduces confidence of old memories (1%/day by default)
- Removes memories below 0.3 confidence
- Updates state.json

**When to use:** Weekly maintenance

**Note:** Decay is **disabled by default**. Enable in config:

```bash
# Edit .memory/state.json
{
  "config": {
    "confidence_decay_enabled": true
  }
}
```

---

## 🔍 Search & Query

### View All Memories

```bash
cat .memory/state.json | jq '.memories'
```

### Filter by Category

```bash
# Decisions
cat .memory/state.json | jq '.memories[] | select(.category == "Decisions")'

# Gotchas
cat .memory/state.json | jq '.memories[] | select(.category == "Gotchas")'

# Architecture
cat .memory/state.json | jq '.memories[] | select(.category == "Architecture")'
```

### Filter by Feature

```bash
cat .memory/state.json | jq '.memories[] | select(.source.feature == "FEAT-001-auth")'
```

### Filter by Phase

```bash
cat .memory/state.json | jq '.memories[] | select(.source.phase == "Analysis")'
```

### High Confidence Only

```bash
cat .memory/state.json | jq '.memories[] | select(.confidence >= 0.9)'
```

---

## 🛠️ Configuration

### View Current Config

```bash
cat .memory/state.json | jq '.config'
```

### Modify Settings

```bash
# Open in editor
nano .memory/state.json
# or
code .memory/state.json
```

**Available settings:**

| Setting | Default | Description |
|---------|---------|-------------|
| `confidence_decay_enabled` | `false` | Enable time-based confidence decay |
| `confidence_decay_rate` | `0.01` | Decay rate per day (1%) |
| `max_memories` | `2000` | Auto-prune beyond this limit |
| `deduplication_threshold` | `0.8` | Jaccard similarity for dedup (0-1) |
| `secret_detection_enabled` | `true` | Detect and sanitize secrets |

---

## 🔒 Secret Detection

### Check for Secrets

Automatic on extraction. Watch for warnings:

```
⚠️  WARNING: Potential secrets detected in spec.md:
   - /api[_-]?key\s*[:=]/gi: 2 matches
   Content will be sanitized
```

**Patterns detected:**
- `api_key`, `api-key`
- `password`
- `bearer` tokens
- `secret`
- `aws_access_key_id`
- Private keys

**Action taken:** Content sanitized with `[REDACTED]`

---

## 💾 Backup & Restore

### View Backups

```bash
ls -lh .memory/snapshots/
```

**Retention:** 30 days (auto-cleanup)

### Restore from Backup

```bash
# List available backups
ls .memory/snapshots/

# Restore specific backup
cp .memory/snapshots/state-2025-02-02T19-30-00Z.json .memory/state.json

# Regenerate CLAUDE.md
node .memory-system/scripts/consolidate-claude-md.js
```

---

## 🗑️ Maintenance

### Prune Low-Confidence Memories

```bash
# Manual prune (removes <0.3 confidence)
cat .memory/state.json | jq '.memories |= map(select(.confidence >= 0.3))' > .memory/state.tmp.json
mv .memory/state.tmp.json .memory/state.json

# Regenerate CLAUDE.md
node .memory-system/scripts/consolidate-claude-md.js
```

### Remove Specific Memory

```bash
# Find memory ID
cat .memory/state.json | jq '.memories[] | select(.content | contains("some text")) | .id'

# Remove by ID
MEMORY_ID="mem-1234567890-a1b2c3d4"
cat .memory/state.json | jq --arg id "$MEMORY_ID" '.memories |= map(select(.id != $id))' > .memory/state.tmp.json
mv .memory/state.tmp.json .memory/state.json
```

### Reset Everything

```bash
# WARNING: Deletes all memories
rm .memory/state.json
bash .memory-system/install.sh
```

---

## 🔗 Integration with Ralph Loop

### Manual Extraction (Per Phase)

```bash
# After Interview
node .memory-system/scripts/extract-memory.js interview $FEATURE_ID docs/features/$FEATURE_ID/spec.md
node .memory-system/scripts/consolidate-claude-md.js
git add .memory/state.json CLAUDE.md
git commit -m "memory: Captured Interview for $FEATURE_ID"

# After Analysis
node .memory-system/scripts/extract-memory.js analysis $FEATURE_ID docs/features/$FEATURE_ID/analysis.md
node .memory-system/scripts/consolidate-claude-md.js
git add .memory/state.json CLAUDE.md
git commit -m "memory: Captured Analysis for $FEATURE_ID"

# After Plan
node .memory-system/scripts/extract-memory.js plan $FEATURE_ID docs/features/$FEATURE_ID/design.md
node .memory-system/scripts/consolidate-claude-md.js
git add .memory/state.json CLAUDE.md
git commit -m "memory: Captured Plan for $FEATURE_ID"

# After Wrap-Up
node .memory-system/scripts/extract-memory.js wrapup $FEATURE_ID docs/features/$FEATURE_ID/context/wrap_up.md
node .memory-system/scripts/consolidate-claude-md.js
git add .memory/state.json CLAUDE.md
git commit -m "memory: Captured WrapUp for $FEATURE_ID"
```

### Automated Extraction (ralph-feature.sh)

Add to your `ralph-feature.sh` after each phase:

```bash
# Function to extract and commit memories
extract_memories() {
  local PHASE=$1
  local FEATURE_ID=$2
  local FILE_PATH=$3

  echo "🧠 Extracting memories from $PHASE phase..."

  node .memory-system/scripts/extract-memory.js $PHASE "$FEATURE_ID" "$FILE_PATH" \
    2>&1 | tee -a .memory-system/logs/extract.log

  if [ $? -eq 0 ]; then
    node .memory-system/scripts/consolidate-claude-md.js \
      2>&1 | tee -a .memory-system/logs/consolidate.log

    git add .memory/state.json CLAUDE.md
    git commit -m "memory: Captured $PHASE phase for $FEATURE_ID" || true
  else
    echo "⚠️  Memory extraction failed (non-fatal)"
  fi
}

# Call after each phase
extract_memories "interview" "$FEATURE_ID" "docs/features/$FEATURE_ID/spec.md"
extract_memories "analysis" "$FEATURE_ID" "docs/features/$FEATURE_ID/analysis.md"
extract_memories "plan" "$FEATURE_ID" "docs/features/$FEATURE_ID/design.md"
extract_memories "wrapup" "$FEATURE_ID" "docs/features/$FEATURE_ID/context/wrap_up.md"
```

---

## 📈 Monitoring

### Check Memory Growth

```bash
# Memory count over time
git log --all --pretty=format:"%h %ai" -- .memory/state.json | while read hash date time tz; do
  COUNT=$(git show $hash:.memory/state.json | jq '.metadata.total_memories')
  echo "$date $time - $COUNT memories"
done
```

### Check CLAUDE.md Size

```bash
wc -l CLAUDE.md
# Should be < 150 lines
```

### Check Disk Usage

```bash
du -sh .memory/
# Should be < 10MB for typical projects
```

---

## 🐛 Troubleshooting

### Extraction Fails

```bash
# Check file exists
ls -la docs/features/FEAT-001/spec.md

# Test extraction manually
node .memory-system/scripts/extract-memory.js interview FEAT-001 docs/features/FEAT-001/spec.md

# Check for errors
cat .memory-system/logs/extract.log
```

### CLAUDE.md Not Generating

```bash
# Check state.json is valid
cat .memory/state.json | jq '.'

# Regenerate
node .memory-system/scripts/consolidate-claude-md.js

# Check for errors
echo $?
```

### State Corruption

```bash
# Restore from backup
cp .memory/snapshots/$(ls -t .memory/snapshots/ | head -1) .memory/state.json

# If no backup, reset
rm .memory/state.json
bash .memory-system/install.sh
```

### Git Conflicts

```bash
# In .memory/state.json or CLAUDE.md
# Accept both sides and run consolidation

git checkout --ours .memory/state.json
git checkout --theirs .memory/state.json.tmp
cat .memory/state.json .memory/state.json.tmp | jq -s '.[0].memories += .[1].memories | .[0]' > .memory/state.merged.json
mv .memory/state.merged.json .memory/state.json
rm .memory/state.json.tmp

# Regenerate CLAUDE.md
node .memory-system/scripts/consolidate-claude-md.js
```

---

## 🚫 What NOT to Do

❌ **Don't manually edit state.json memories** (use extraction)
❌ **Don't commit .memory/snapshots/** (too noisy)
❌ **Don't enable decay without testing** (may lose good patterns)
❌ **Don't skip extraction** (breaks context continuity)
❌ **Don't commit secrets to spec.md** (sanitized but risky)

---

## ✅ Best Practices

✅ **Extract after every phase** (consistency)
✅ **Commit memory updates** (traceability)
✅ **Review CLAUDE.md weekly** (quality check)
✅ **Backup before major changes** (safety)
✅ **Keep state.json in Git** (valuable data)
✅ **Monitor memory count** (prevent bloat)

---

## 📚 Additional Resources

- [Integration Plan](docs/memory-integration-plan.md) - Strategic overview
- [Implementation Guide](docs/memory-implementation-guide.md) - Detailed setup
- [Examples](docs/memory-integration-examples.md) - Real-world use cases
- [Critical Analysis](docs/features/MEMORY-INTEGRATION/analysis.md) - Technical analysis
- [System README](.memory-system/README.md) - Technical details

---

## 🆘 Getting Help

1. Check this command reference
2. Review [Troubleshooting](#-troubleshooting) section
3. Check logs: `.memory-system/logs/`
4. Open issue with:
   - Command that failed
   - Error message
   - Output of `node .memory-system/scripts/extract-memory.js stats`

---

**Version:** 1.0.0
**Last Updated:** 2025-02-02
**Compatibility:** Ralph Loop v1.0+
