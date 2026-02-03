# Memory-MCP + Ralph Loop Integration Plan

## Executive Summary

This document outlines the integration of **Memory-MCP** (persistent context system) with **Ralph Loop** (autonomous feature development system) to create a self-learning development environment that maintains context across sessions and features.

## The Problem

Ralph Loop currently faces context loss challenges:
- **Inter-session amnesia**: When Ralph pauses or restarts, it loses nuanced context
- **Cross-feature knowledge gap**: Patterns learned in FEAT-001 aren't available for FEAT-002
- **Architectural drift**: Decisions made early in the project get forgotten
- **Manual context loading**: Engineers must repeatedly explain project structure

## The Solution: Memory-MCP Integration

Memory-MCP provides a two-tier persistent memory system:
1. **CLAUDE.md** - Compact summary (~150 lines) auto-loaded at session start
2. **.memory/state.json** - Complete searchable memory store

### How Memory-MCP Captures Context

Memory-MCP uses Claude Code hooks that fire after each response, extracting:
- **Architecture** - System structure and tech stack
- **Decisions** - Why choices were made
- **Patterns** - Coding conventions
- **Gotchas** - Edge cases and pitfalls
- **Progress** - Task completion state
- **Context** - Business requirements

---

## Integration Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    RALPH LOOP + MEMORY-MCP INTEGRATION                       │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   ┌──────────────────────────────────────────────────────────────────┐      │
│   │                      CLAUDE.md (Auto-Loaded)                     │      │
│   │  ┌────────────────────────────────────────────────────────────┐  │      │
│   │  │ PROJECT CONTEXT                                            │  │      │
│   │  │ • Tech stack: Node.js + PostgreSQL + React               │  │      │
│   │  │ • Architecture: Microservices with event bus              │  │      │
│   │  │ • Current phase: FEAT-003 in implementation              │  │      │
│   │  ├────────────────────────────────────────────────────────────┤  │      │
│   │  │ KEY DECISIONS                                              │  │      │
│   │  │ • Auth: JWT + Redis (FEAT-001)                            │  │      │
│   │  │ • API: REST with OpenAPI spec (FEAT-002)                  │  │      │
│   │  │ • Testing: Jest + Testing Library                         │  │      │
│   │  ├────────────────────────────────────────────────────────────┤  │      │
│   │  │ PATTERNS                                                   │  │      │
│   │  │ • Services in src/services/ with dependency injection     │  │      │
│   │  │ • Controllers follow controller-service-repository        │  │      │
│   │  │ • Tests co-located with implementation                    │  │      │
│   │  ├────────────────────────────────────────────────────────────┤  │      │
│   │  │ GOTCHAS                                                    │  │      │
│   │  │ • Database connections must use connection pooling        │  │      │
│   │  │ • Redis keys need TTL to prevent memory leak              │  │      │
│   │  └────────────────────────────────────────────────────────────┘  │      │
│   └──────────────────────────────────────────────────────────────────┘      │
│                              │                                              │
│                              ▼                                              │
│   ┌──────────────────────────────────────────────────────────────────┐      │
│   │                    RALPH LOOP EXECUTION                          │      │
│   │                                                                  │      │
│   │   Phase 1: INTERVIEW    → Memory captures spec decisions        │      │
│   │   Phase 2: ANALYSIS     → Memory captures assumptions           │      │
│   │   Phase 3: PLAN         → Memory captures architecture          │      │
│   │   Phase 4: BRANCH       → Memory tracks branch info             │      │
│   │   Phase 5: IMPLEMENT    → Memory captures patterns + gotchas    │      │
│   │   Phase 6: PR           → Memory captures PR context            │      │
│   │   Phase 7: MERGE        → Memory updates progress               │      │
│   │   Phase 8: WRAP-UP      → Memory consolidates learnings         │      │
│   └──────────────────────────────────────────────────────────────────┘      │
│                              │                                              │
│                              ▼                                              │
│   ┌──────────────────────────────────────────────────────────────────┐      │
│   │              .memory/state.json (Complete Store)                 │      │
│   │  • 1,500+ memories with metadata                                 │      │
│   │  • Searchable via MCP tools                                      │      │
│   │  • Confidence decay over time                                    │      │
│   │  • Auto-deduplicated                                             │      │
│   └──────────────────────────────────────────────────────────────────┘      │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Integration Points

### 1. Phase 1: INTERVIEW

**Without Memory-MCP:**
- Ralph asks questions even if answered before
- No access to patterns from previous features
- Can't validate against existing architecture

**With Memory-MCP:**
- Auto-fills spec.md with known patterns
- Suggests decisions based on previous features
- Warns about inconsistencies with architecture

**Memory Capture:**
```yaml
category: Decisions
content: "FEAT-003: Dashboard uses React Query for server state (consistent with FEAT-002)"
confidence: High
phase: Interview
```

---

### 2. Phase 2: THINK CRITICALLY (Analysis)

**Without Memory-MCP:**
- Analysis starts from scratch each time
- Can't reference previous gotchas
- No learning from past mistakes

**With Memory-MCP:**
- Loads relevant gotchas from similar features
- References previous assumptions that failed
- Suggests mitigations based on history

**Memory Capture:**
```yaml
category: Gotchas
content: "Database queries without indexes caused 2s latency in FEAT-001. Always index foreign keys."
confidence: High
phase: Analysis
source: FEAT-001-auth
```

---

### 3. Phase 3: PLAN (Design)

**Without Memory-MCP:**
- Can't enforce consistent architecture
- Might violate established patterns
- No access to reusable components

**With Memory-MCP:**
- Validates against architectural decisions
- Suggests existing utilities/services
- Ensures pattern consistency

**Memory Capture:**
```yaml
category: Architecture
content: "Services follow dependency injection pattern. Use src/services/BaseService.ts as template."
confidence: High
phase: Plan
```

---

### 4. Phase 5: IMPLEMENT

**Without Memory-MCP:**
- Might repeat solved problems
- Can't reference working examples
- No access to debugging insights

**With Memory-MCP:**
- Loads similar implementations
- References debugging solutions
- Suggests optimization patterns

**Memory Capture:**
```yaml
category: Patterns
content: "Error handling: Use ServiceError class with error codes. See src/errors/ServiceError.ts"
confidence: High
phase: Implement
```

---

### 5. Phase 8: WRAP-UP

**Without Memory-MCP:**
- Learnings stay in wrap_up.md
- Not automatically available next time
- Manual knowledge transfer needed

**With Memory-MCP:**
- Auto-consolidates learnings to CLAUDE.md
- Extracts reusable patterns
- Updates confidence scores

**Memory Capture:**
```yaml
category: Progress
content: "FEAT-003 completed. Dashboard component reusable. Performance optimized with virtualization."
confidence: High
phase: WrapUp
```

---

## Implementation Roadmap

### Phase 1: Core Integration (Week 1)

**Goal:** Memory-MCP captures Ralph Loop execution

**Tasks:**
1. Install Memory-MCP in Ralph Loop project
2. Configure hooks to fire after each phase
3. Define memory extraction rules per phase
4. Test with single feature loop

**Deliverables:**
- `.memory/` directory with state.json
- CLAUDE.md generated from first feature
- Memory dashboard showing captured context

---

### Phase 2: Smart Context Loading (Week 2)

**Goal:** Ralph uses memory to enhance decisions

**Tasks:**
1. Modify Interview phase to query .memory/decisions
2. Enhance Analysis phase with .memory/gotchas
3. Update Plan phase to validate against .memory/architecture
4. Implement pattern suggestions in Implementation phase

**Deliverables:**
- Ralph queries memory before each phase
- Decision suggestions in spec.md
- Pattern recommendations in design.md

---

### Phase 3: Cross-Feature Learning (Week 3)

**Goal:** Features learn from each other

**Tasks:**
1. Tag memories with feature ID
2. Implement similarity matching (FEAT-002 similar to FEAT-005)
3. Auto-suggest reusable components
4. Track pattern evolution over time

**Deliverables:**
- Feature similarity graph
- Reusable component catalog
- Pattern evolution timeline

---

### Phase 4: Self-Improving Loop (Week 4)

**Goal:** Ralph learns from successes and failures

**Tasks:**
1. Track feature completion metrics
2. Correlate decisions with outcomes
3. Boost confidence for successful patterns
4. Decay confidence for problematic patterns
5. Generate improvement suggestions

**Deliverables:**
- Feature success metrics dashboard
- Pattern confidence scores
- Auto-generated improvement suggestions

---

## Technical Implementation

### 1. Memory-MCP Installation

```bash
# Clone Memory-MCP
git clone https://github.com/yuvalsuede/memory-mcp.git .memory-mcp

# Install dependencies
cd .memory-mcp && npm install

# Configure MCP server
echo '{
  "mcpServers": {
    "memory": {
      "command": "node",
      "args": [".memory-mcp/build/index.js"],
      "env": {
        "MEMORY_DIR": ".memory"
      }
    }
  }
}' > ~/.claude/config.json
```

### 2. Hook Configuration

Create `.claude/hooks/post-response.sh`:

```bash
#!/bin/bash
# Fires after each Claude response

RESPONSE="$1"
FEATURE_ID="$2"
PHASE="$3"

# Extract memory using Memory-MCP
node .memory-mcp/extract.js \
  --response "$RESPONSE" \
  --feature "$FEATURE_ID" \
  --phase "$PHASE" \
  --output .memory/state.json

# Update CLAUDE.md
node .memory-mcp/consolidate.js \
  --input .memory/state.json \
  --output CLAUDE.md \
  --max-lines 150
```

### 3. Ralph Loop Modifications

**Before each phase:**
```bash
# Query relevant memories
MEMORIES=$(mcp-cli call memory/search "{
  \"query\": \"phase:${PHASE} feature:${FEATURE_ID}\",
  \"limit\": 10
}")

# Inject into Claude prompt
PROMPT="<memory-context>
${MEMORIES}
</memory-context>

Execute ${PHASE} phase for ${FEATURE_ID}..."
```

**After each phase:**
```bash
# Trigger memory extraction hook
.claude/hooks/post-response.sh "$RESPONSE" "$FEATURE_ID" "$PHASE"

# Commit memory updates
git add .memory/ CLAUDE.md
git commit -m "memory: Update context after ${PHASE} phase"
```

---

## Memory Schema

### state.json Structure

```json
{
  "memories": [
    {
      "id": "mem-001",
      "category": "Architecture",
      "content": "Services use dependency injection pattern",
      "confidence": 0.95,
      "source": {
        "feature": "FEAT-001-auth",
        "phase": "Plan",
        "timestamp": "2025-01-23T14:30:00Z"
      },
      "tags": ["pattern", "service", "di"],
      "references": ["src/services/BaseService.ts"],
      "supersedes": null
    },
    {
      "id": "mem-002",
      "category": "Gotchas",
      "content": "Redis keys need TTL to prevent memory leak",
      "confidence": 0.98,
      "source": {
        "feature": "FEAT-001-auth",
        "phase": "Implement",
        "timestamp": "2025-01-23T15:45:00Z",
        "context": "Found during session management implementation"
      },
      "tags": ["redis", "memory-leak", "ttl"],
      "references": ["src/services/SessionService.ts:42"],
      "supersedes": null
    }
  ],
  "metadata": {
    "total_memories": 127,
    "last_consolidation": "2025-01-23T16:00:00Z",
    "confidence_avg": 0.87,
    "features_processed": ["FEAT-001-auth", "FEAT-002-api"]
  }
}
```

### CLAUDE.md Template

```markdown
# Project Context (Auto-Generated)

> Last updated: 2025-01-23T16:00:00Z | Features: 2 | Memories: 127

## Tech Stack

- **Backend**: Node.js 20 + Express 4.18
- **Database**: PostgreSQL 15 + Prisma ORM
- **Frontend**: React 18 + TypeScript 5.3
- **State**: React Query + Zustand
- **Testing**: Jest + Testing Library

## Architecture

- **Pattern**: Microservices with event-driven communication
- **Structure**: Controller → Service → Repository
- **Auth**: JWT tokens + Redis sessions
- **API**: RESTful with OpenAPI 3.1 spec

## Key Decisions

### Authentication (FEAT-001)
- **Session Storage**: JWT + Redis (24h expiry)
- **Why**: Balances security with performance, allows token revocation
- **Gotcha**: Redis keys MUST have TTL to prevent memory leak

### API Design (FEAT-002)
- **Format**: JSON envelope with metadata
- **Why**: Consistent error handling and pagination
- **Pattern**: All endpoints return `{ data, meta, error }`

## Coding Patterns

### Services
```typescript
// src/services/BaseService.ts
export abstract class BaseService {
  constructor(protected readonly db: PrismaClient) {}
  abstract validate(data: unknown): boolean
}
```
- All services extend BaseService
- Use dependency injection
- Validate input with Zod schemas

### Error Handling
```typescript
// src/errors/ServiceError.ts
throw new ServiceError('AUTH001', 'Invalid token', 401)
```
- Custom error codes (DOMAIN + number)
- HTTP status included
- Logged with structured context

## Gotchas

1. **Database Queries**: Always add indexes on foreign keys (2s latency in FEAT-001 without)
2. **Redis Sessions**: Set TTL or risk memory leak
3. **API Pagination**: Use cursor-based for large datasets (offset fails at scale)
4. **React Query**: Stale time 5 min to reduce re-fetches

## Current Progress

- ✅ FEAT-001-auth (Merged 2025-01-22)
- ✅ FEAT-002-api (Merged 2025-01-23)
- 🟡 FEAT-003-dashboard (In Progress - Implement phase)
- ⚪ FEAT-004-analytics (Pending)

## Reusable Components

- `src/components/DataTable.tsx` - Virtualized table with sorting/filtering
- `src/hooks/useAuth.ts` - Authentication state management
- `src/utils/logger.ts` - Structured logging with context

---

*For detailed memories, query `.memory/state.json` via MCP tools*
```

---

## MCP Tools for Memory Access

### 1. memory/search

Search memories by query:

```bash
mcp-cli call memory/search '{
  "query": "phase:Plan category:Architecture",
  "limit": 5
}'
```

### 2. memory/synthesize

Generate summary from memories:

```bash
mcp-cli call memory/synthesize '{
  "topic": "authentication patterns",
  "features": ["FEAT-001-auth", "FEAT-005-sso"]
}'
```

### 3. memory/consolidate

Update CLAUDE.md from state.json:

```bash
mcp-cli call memory/consolidate '{
  "input": ".memory/state.json",
  "output": "CLAUDE.md",
  "max_lines": 150
}'
```

---

## Benefits of Integration

### For Ralph Loop

1. **Smarter Interviews**: Auto-fill decisions based on patterns
2. **Better Analysis**: Reference previous gotchas and failures
3. **Consistent Planning**: Validate against established architecture
4. **Faster Implementation**: Suggest similar implementations
5. **Richer Wrap-Up**: Auto-consolidate learnings to CLAUDE.md

### For Engineers

1. **Zero onboarding**: New sessions auto-load context
2. **Pattern discovery**: Find reusable solutions
3. **Architectural consistency**: Automatic validation
4. **Knowledge retention**: Nothing is lost between sessions
5. **Cross-feature learning**: Insights from one feature help others

### For Projects

1. **Living documentation**: CLAUDE.md always up-to-date
2. **Technical debt tracking**: Confidence decay highlights stale patterns
3. **Decision history**: Why choices were made
4. **Pattern evolution**: See how conventions change over time
5. **Quality metrics**: Track what works and what doesn't

---

## Metrics and Success Criteria

### Phase 1 Success (Core Integration)

- [ ] Memory-MCP captures 80%+ of decisions per phase
- [ ] CLAUDE.md generated with <150 lines
- [ ] .memory/state.json contains structured memories
- [ ] Zero manual intervention needed

### Phase 2 Success (Smart Context)

- [ ] Ralph queries memory before each phase
- [ ] 50%+ of spec decisions auto-suggested
- [ ] Analysis phase references previous gotchas
- [ ] Plan phase validates against architecture

### Phase 3 Success (Cross-Feature Learning)

- [ ] Similar features identified automatically
- [ ] Reusable components suggested
- [ ] Pattern consistency >85% across features

### Phase 4 Success (Self-Improvement)

- [ ] Confidence scores correlate with success rate
- [ ] Failed patterns decay confidence
- [ ] Successful patterns boost confidence
- [ ] Auto-generated improvement suggestions

---

## Risk Mitigation

### Risk 1: Memory Bloat

**Problem**: state.json grows unbounded

**Mitigation:**
- Auto-prune memories with confidence <0.3
- Archive superseded decisions
- Limit CLAUDE.md to 150 lines
- Consolidate similar memories

### Risk 2: Context Poisoning

**Problem**: Bad patterns get reinforced

**Mitigation:**
- Confidence decay over time
- Manual review of high-impact decisions
- Rollback capability for memory updates
- Human override for critical patterns

### Risk 3: Performance Impact

**Problem**: Memory queries slow down Ralph

**Mitigation:**
- Index state.json for fast search
- Cache frequent queries
- Limit memory search to 10 results
- Async memory updates (don't block phases)

---

## Next Steps

1. **Review this plan** with team
2. **Set up Memory-MCP** in development environment
3. **Run pilot** with single feature (FEAT-003)
4. **Measure impact** on spec quality and implementation speed
5. **Iterate** based on learnings
6. **Roll out** to production Ralph Loop

---

## References

- [Memory-MCP GitHub](https://github.com/yuvalsuede/memory-mcp)
- [Ralph Loop Documentation](./ralph-feature-loop.md)
- [Feature Development Cycle](./feature_cycle.md)
- [Claude Code Hooks](https://docs.claude.com/hooks)

---

*Document Version: 1.0*
*Last Updated: 2025-01-23*
*Author: Integration Planning Team*
