---
description: Deep engineering analysis before implementation - challenges assumptions, identifies unknowns, prevents architectural mistakes (Phase 2 of 8-Phase Feature Cycle)
argument-hint: [topic or FEAT-XXX]
allowed-tools: Read, Write
---

# Think Critically

## Purpose

Rigorous pre-implementation analysis that simulates a paranoid staff engineer review. Prevents costly architectural mistakes by forcing systematic examination of assumptions, trade-offs, and failure modes **before** writing code.

**This is Phase 2 of the 8-Phase Feature Development Cycle.**

## Usage

```bash
# Analyze a feature before planning (most common - Phase 2)
/think-critically FEAT-001-auth

# Analyze a specific topic
/think-critically authentication approach for multi-tenant system

# Challenge assumptions on a PRD
/think-critically our database migration strategy

# Review a design decision
/think-critically using Redis vs PostgreSQL for sessions
```

## Instructions

1. **Read the skill file:**
   ```
   Read .claude/skills/thinking-critically/SKILL.md
   ```

2. **If analyzing a feature (FEAT-XXX):**
   ```bash
   # Read completed spec from Interview phase
   cat docs/features/$ARGUMENTS/spec.md 2>/dev/null

   # Read project context
   cat docs/project.md 2>/dev/null

   # Read architecture constraints
   cat docs/architecture/_index.md 2>/dev/null

   # Check Market Validation (from SaaS Validator)
   grep -A5 "Pain Level\|Market Validation" docs/features/$ARGUMENTS/spec.md 2>/dev/null
   ```

3. **Determine analysis depth:**

   | Condition | Steps to Execute | Reason |
   |-----------|-----------------|--------|
   | New feature + new system | All 11 steps | Maximum architectural risk |
   | New feature + existing patterns | 1-2-3-5-9-11 | Medium risk |
   | Small/clear scope feature | 1-2-5-11 | Low risk |
   | Bug fix/hotfix | Skip entirely | No architectural risk |

4. **Execute the 11-step protocol:**
   - Step 1: Problem Clarification & Constraints
   - Step 2: Implicit Assumptions Identification ← CRITICAL
   - Step 3: Design Space Exploration
   - Step 4: Trade-off Analysis
   - Step 5: Failure-First Analysis
   - Step 6: Boundaries & Invariants
   - Step 7: Observability & Control
   - Step 8: Reversibility & Entropy
   - Step 9: Adversarial Review (Paranoid Staff Engineer Mode)
   - Step 10: AI Delegation Assessment
   - Step 11: Decision Summary

5. **Output the analysis** in structured markdown format

6. **If analyzing FEAT-XXX:**
   - Save analysis to `docs/features/FEAT-XXX/analysis.md`
   - Update `docs/features/FEAT-XXX/status.md` → Phase: Critical Analysis ✅
   - Update `docs/features/FEAT-XXX/context/decisions.md` with key decisions
   - Update `docs/features/_index.md` with phase progress

## Key Rules

```
╔═══════════════════════════════════════════════════════════════════════════════╗
║  CRITICAL RULES                                                               ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║                                                                               ║
║  1. NEVER skip Step 2 (Assumptions) - most failures stem from here           ║
║                                                                               ║
║  2. If ANY assumption has Low confidence + High impact → STOP                ║
║     Validate with user before proceeding                                     ║
║                                                                               ║
║  3. Step 9 must be genuinely adversarial - attack your own design            ║
║                                                                               ║
║  4. All 11 steps for complex/critical features                               ║
║     Steps 1-2-5-11 for smaller features                                      ║
║                                                                               ║
║  5. In Ralph Loop: auto-PAUSE if confidence is Low in Step 11                ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
```

## Integration with Feature Cycle (8 Phases)

```
Interview → THINK CRITICALLY → Plan → Branch → Implement → PR → Merge → Wrap-Up
             ↑ Phase 2
             Best time to catch design flaws
             Feeds analysis.md → Plan reads it for design.md
```

## Ralph Loop Integration

When running autonomously via Ralph Loop:

```
Iteration 1: INTERVIEW → reads spec.md, pauses if TBD → emits INTERVIEW_COMPLETE
Iteration 2: THINK CRITICALLY → executes protocol → emits ANALYSIS_COMPLETE
             ⚠️ AUTO-PAUSE if:
             - Low confidence + High impact assumption found
             - Step 9 identifies critical red flag
             - Step 11 confidence level is "Low"
Iteration 3: PLAN → reads spec.md + analysis.md → generates design.md + tasks.md
```

## How Analysis Feeds Plan Phase

The Plan phase reads `analysis.md` in addition to `spec.md` to:
- Select recommended approach (from Step 11)
- Incorporate failure mitigations (from Step 5) into design
- Include invariants/boundaries (from Step 6) as validations
- Use AI delegation matrix (from Step 10) to decide Ralph automation scope
- Add observability requirements (from Step 7) to implementation tasks

## Example Output Summary

After running the full protocol, the Decision Summary should include:
- Recommended approach with rationale
- Key decisions made
- Short-term and long-term goals
- Remaining unknowns
- Security threat model
- Blast radius analysis
- Confidence level
- Red flags to watch
- Recommended next steps

## Argument
$ARGUMENTS
