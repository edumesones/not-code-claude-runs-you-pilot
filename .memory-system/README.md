# Memory System for Ralph Loop

Self-contained memory extraction and consolidation system.

## Quick Start

```bash
# Install (run once)
bash .memory-system/install.sh

# Extract memories from a phase
node .memory-system/scripts/extract-memory.js interview FEAT-001 docs/features/FEAT-001/spec.md
node .memory-system/scripts/extract-memory.js analysis FEAT-001 docs/features/FEAT-001/analysis.md
node .memory-system/scripts/extract-memory.js plan FEAT-001 docs/features/FEAT-001/design.md
node .memory-system/scripts/extract-memory.js wrapup FEAT-001 docs/features/FEAT-001/context/wrap_up.md

# Generate CLAUDE.md
node .memory-system/scripts/consolidate-claude-md.js

# View statistics
node .memory-system/scripts/extract-memory.js stats

# Apply confidence decay (optional)
node .memory-system/scripts/extract-memory.js decay
```

## Features

### ✅ Implemented (Critical Analysis Mitigations)

1. **Secret Detection** (Step 9 - Critical)
   - Regex patterns for API keys, passwords, tokens
   - Auto-sanitization with [REDACTED]
   - Pre-commit warnings

2. **Branch-Aware Storage** (Step 9 - Critical)
   - Memories tagged with source branch
   - Merge strategy: combine + deduplicate
   - No data loss on branch merges

3. **Schema Versioning** (Step 9 - Important)
   - Version field in state.json
   - Migration path enabled
   - Future-proof design

4. **Configurable Confidence Decay** (Step 11)
   - Default: OFF (unvalidated algorithm)
   - Configurable rate via config
   - Manual trigger via `decay` command

5. **Atomic Writes** (Step 5 - Critical)
   - Temp file + rename pattern
   - Corruption prevention
   - Auto-backup before writes

6. **Deduplication** (Step 6)
   - Jaccard similarity (0.8 threshold)
   - Configurable threshold
   - Prevents memory bloat

7. **Error Handling** (Step 5)
   - Try/catch on all operations
   - Graceful degradation
   - Auto-restore from backups

## File Structure

```
.memory-system/
├── scripts/
│   ├── extract-memory.js          Main extraction script
│   ├── consolidate-claude-md.js   CLAUDE.md generator
│   └── (future: query.js, merge.js)
├── logs/                           Extraction logs
├── install.sh                      Setup script
└── README.md                       This file

.memory/
├── state.json                      Complete memory store
├── snapshots/                      Daily backups (30 days retention)
│   ├── state-2025-02-02.json
│   └── ...
└── (future: indexes/, cache/)
```

## Configuration

Edit `.memory/state.json` → `config` section:

```json
{
  "config": {
    "confidence_decay_enabled": false,    // Start disabled
    "confidence_decay_rate": 0.01,        // 1%/day when enabled
    "max_memories": 2000,                 // Auto-prune beyond this
    "deduplication_threshold": 0.8,       // Jaccard similarity
    "secret_detection_enabled": true      // Always enabled
  }
}
```

## Memory Schema

```json
{
  "id": "mem-1234567890-a1b2c3d4",
  "category": "Decisions|Architecture|Patterns|Gotchas|Progress",
  "content": "FEAT-001: JWT + Redis for session storage",
  "confidence": 0.95,
  "source": {
    "feature": "FEAT-001-auth",
    "phase": "Interview",
    "branch": "feature/001-auth",
    "timestamp": "2025-02-02T19:30:00Z",
    "context": "Additional context"
  },
  "tags": ["auth", "redis", "jwt"],
  "references": ["docs/features/FEAT-001/spec.md"],
  "supersedes": null
}
```

## Integration with Ralph Loop

Memory extraction should be called after each phase completes.

### Example: ralph-feature.sh integration

```bash
# After Interview phase
if [ "$PHASE" = "interview" ]; then
  # ... existing interview code ...

  # Extract memories
  node .memory-system/scripts/extract-memory.js interview \
    "$FEATURE_ID" \
    "docs/features/$FEATURE_ID/spec.md" 2>&1 | tee -a .memory-system/logs/extract.log

  # Update CLAUDE.md
  node .memory-system/scripts/consolidate-claude-md.js 2>&1 | tee -a .memory-system/logs/consolidate.log

  # Commit memory updates
  git add .memory/state.json CLAUDE.md
  git commit -m "memory: Captured Interview phase for $FEATURE_ID" || true
fi
```

## Troubleshooting

### Memory not being extracted

```bash
# Check if files exist
ls -la docs/features/FEAT-001/spec.md

# Test extraction manually
node .memory-system/scripts/extract-memory.js interview FEAT-001 docs/features/FEAT-001/spec.md

# Check logs
cat .memory-system/logs/extract.log
```

### CLAUDE.md not generating

```bash
# Check state.json
cat .memory/state.json | head -20

# Test consolidation
node .memory-system/scripts/consolidate-claude-md.js

# Check for errors
echo $?
```

### Secrets detected warning

```bash
# Review the file for sensitive data
grep -i "api.*key\|password\|token" docs/features/FEAT-001/spec.md

# Content is automatically sanitized, but review manually
# Remove secrets from source file and re-extract
```

### State.json corrupted

```bash
# Restore from backup
cp .memory/snapshots/state-$(date +%Y-%m-%d).json .memory/state.json

# If no backup, recreate
rm .memory/state.json
bash .memory-system/install.sh
```

## Performance

- Extraction: ~100-500ms per phase
- Consolidation: ~50-200ms
- Query (planned): <2s for 2000 memories
- Storage: ~0.5MB per 1000 memories

## Security

- ✅ Secret detection enabled by default
- ✅ No code execution from memories
- ✅ Atomic writes (no partial data)
- ✅ Auto-backup before changes
- ⚠️  state.json should be in Git (decisions are valuable)
- ⚠️  snapshots/ should be .gitignored (noisy)

## Future Enhancements (Phase 2+)

- [ ] MCP server implementation
- [ ] Query tool (search, filter, synthesize)
- [ ] Branch merge tool (automated)
- [ ] Memory dashboard (visualization)
- [ ] Indexing (performance at scale)
- [ ] Cross-project memory sharing

## Version History

- **1.0.0** (2025-02-02)
  - Initial implementation
  - Secret detection
  - Branch-aware storage
  - Configurable decay
  - Schema versioning

---

For detailed documentation, see:
- [Integration Plan](../docs/memory-integration-plan.md)
- [Implementation Guide](../docs/memory-implementation-guide.md)
- [Critical Analysis](../docs/features/MEMORY-INTEGRATION/analysis.md)
