# Feature Development Cycle (9 Phases: 8 Core + Phase 5.5 VERIFY)

## Objetivo

Este documento define el flujo de trabajo exacto para implementar cualquier feature. Siguiendo este ciclo se garantiza consistencia, trazabilidad y calidad.

**NUEVO:** Fase 5.5 (VERIFY) - Browser automation tests con agent-browser para validación frontend automática.

**NUEVO:** Multi-Agent System - Agentes especializados por fase con relay pattern y paralelización. Ver `docs/agents.md` para configuración de agentes del proyecto.

---

## Resumen Visual

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    FEATURE DEVELOPMENT CYCLE (9 PHASES)                      │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   1. INTERVIEW       2. THINK CRITICALLY    3. PLAN         4. BRANCH       │
│   ┌─────────┐       ┌─────────────┐       ┌─────────┐     ┌─────────┐     │
│   │ Preguntas│ ───► │ 11-Step     │ ───► │ Explorar │───► │ git     │     │
│   │ Decisiones│      │ Protocol    │       │ Diseñar │     │ checkout│     │
│   │ spec.md  │       │ analysis.md │       │ design.md│     │ -b      │     │
│   └─────────┘       └─────────────┘       └─────────┘     └─────────┘     │
│       │                    │                    │                │          │
│       ▼                    ▼                    ▼                ▼          │
│   📄 spec.md          📄 analysis.md       📄 design.md     🌿 branch     │
│   📄 status.md        📄 decisions.md      📄 tasks.md      📄 status.md  │
│                                                                    │        │
│                                                                    ▼        │
│   5. IMPLEMENT                                                              │
│   ┌──────────────────────────────────────────────────────────────┐          │
│   │ Código → Tests → Commits → Documentación viva                │          │
│   └──────────────────────────────────────────────────────────────┘          │
│       │                                                                      │
│       ▼                                                                      │
│   5.5 VERIFY ← NUEVO!                                                        │
│   ┌──────────────────────────────────────────────────────────────┐          │
│   │ agent-browser E2E → Screenshots → Security Filters            │          │
│   │ Auto-run si cambios tsx/jsx/css + test scripts existen        │          │
│   │ Bloquea PR si tests fallan                                    │          │
│   └──────────────────────────────────────────────────────────────┘          │
│       │                                                                      │
│       ▼                                                                      │
│   7. MERGE              6. PR (+ test results)  ◄──────────────             │
│   ┌─────────┐          ┌─────────┐                                          │
│   │ Review  │   ◄───   │ Push    │                                          │
│   │ Approve │          │ gh pr   │                                          │
│   │ Update  │          │ create  │                                          │
│   └─────────┘          └─────────┘                                          │
│       │                                                                      │
│       ▼                                                                      │
│   8. WRAP-UP                                                                 │
│   ┌─────────┐                                                                │
│   │ Context │                                                                │
│   │ Learnings│                                                               │
│   │ Cleanup │                                                                │
│   └─────────┘                                                                │
│       │                                                                      │
│       ▼                                                                      │
│   📄 status.md → 🟢 Complete                                                │
│   📄 wrap_up.md → Learnings captured                                        │
│   📄 _index.md UPDATED                                                      │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## ⚠️ REGLA CRÍTICA: DOCUMENTACIÓN VIVA

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    📋 DOCUMENTATION UPDATE RULES                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   La documentación NO se actualiza "al final". Se actualiza EN TIEMPO REAL. │
│                                                                              │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │ tasks.md - ACTUALIZAR EN CADA TASK                                  │   │
│   ├─────────────────────────────────────────────────────────────────────┤   │
│   │ ANTES de empezar task:    - [ ] Task 1  →  - [🟡] Task 1           │   │
│   │ DESPUÉS de completar:     - [🟡] Task 1  →  - [x] Task 1           │   │
│   │ Si hay problema:          - [🟡] Task 1  →  - [🔴] Task 1 (blocked)│   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │ status.md - ACTUALIZAR EN CADA CAMBIO DE FASE                       │   │
│   ├─────────────────────────────────────────────────────────────────────┤   │
│   │ Interview completado        → Phase: Interview ✅                   │   │
│   │ Analysis completado         → Phase: Critical Analysis ✅           │   │
│   │ Plan aprobado               → Phase: Plan ✅                        │   │
│   │ Branch creado               → Phase: Branch ✅, Current: Implement  │   │
│   │ Cada 3 tasks                → Progress: 3/10 tasks                  │   │
│   │ Blocker encontrado          → Blockers: [descripción]               │   │
│   │ PR creado                   → Phase: PR, Link: [url]                │   │
│   │ Merged                      → Status: 🟢 Complete                   │   │
│   │ Wrap-Up complete            → Learnings captured                    │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│   ⏰ COMMIT DOCS CADA 30 MINUTOS O CADA 3 TASKS (lo que pase primero)       │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Marcadores de Tasks

| Marcador | Significado | Cuándo usar |
|----------|-------------|-------------|
| `- [ ]` | Pendiente | Task no iniciada |
| `- [🟡]` | En progreso | ANTES de empezar la task |
| `- [x]` | Completada | DESPUÉS de completar |
| `- [🔴]` | Bloqueada | Hay un impedimento |
| `- [⏭️]` | Saltada | Decidido no hacer (con nota) |

---

## Fase 1: INTERVIEW (Especificación)

### Propósito
Capturar TODAS las decisiones técnicas y de producto ANTES de escribir código.

### Cómo Iniciar
```
"Interview me about FEAT-XXX"
/interview FEAT-XXX
```

### Proceso

1. **Claude hace preguntas estructuradas** (máx 3-4 por turno):
   - UI/UX decisions
   - Comportamiento del sistema
   - Edge cases
   - Límites y restricciones
   - Integraciones
   - **Market Validation** (Pain Level 7+? - SaaS Validator)

2. **El usuario responde con opciones claras**:
   - ✅ BIEN: "Import desde .env (DATABASE_URL format)"
   - ✅ BIEN: "Retry 3x automático + notificación"
   - ❌ MAL: "No sé, lo que tú creas"

3. **Claude actualiza spec.md** con cada decisión en formato tabla

### 📄 Documentos actualizados
- `spec.md` → Decisiones documentadas
- `status.md` → Phase: Interview ✅

---

## Fase 2: THINK CRITICALLY (Análisis Crítico) ← NUEVA

### Propósito
Análisis riguroso pre-implementación que simula una revisión de un staff engineer paranoico. Previene errores arquitectónicos costosos.

### Cómo Iniciar
```
/think-critically FEAT-XXX
```

### Proceso

1. Lee spec.md completado (output de Interview)
2. Determina profundidad de análisis (ver reglas de abreviación)
3. Ejecuta protocolo de 11 pasos (o abreviado)
4. Genera analysis.md

### Reglas de Abreviación Automática

| Condición | Pasos | Razón |
|-----------|-------|-------|
| Feature nueva + sistema nuevo | Los 11 pasos | Máximo riesgo arquitectónico |
| Feature nueva + patrones existentes | 1-2-3-5-9-11 | Riesgo medio |
| Feature pequeña/clara | 1-2-5-11 | Riesgo bajo |
| Bug fix / hotfix | Saltar completamente | Sin riesgo arquitectónico |

### Los 11 Pasos

```
 1. Clarificación del Problema    - ¿Qué estamos resolviendo exactamente?
 2. Asunciones Implícitas ⚠️      - ¿Qué asumimos que es verdad?
 3. Espacio de Diseño             - ¿Qué enfoques existen?
 4. Análisis de Trade-offs        - ¿Qué estamos intercambiando?
 5. Análisis de Fallos            - ¿Qué se romperá y cómo?
 6. Límites e Invariantes         - ¿Qué debe ser siempre verdad?
 7. Observabilidad                - ¿Cómo sabremos si funciona?
 8. Reversibilidad                - ¿Podemos deshacer esto?
 9. Revisión Adversarial 🔴       - Ataca tu propio diseño
10. Delegación IA                 - ¿Qué puede automatizar la IA?
11. Resumen de Decisión           - Síntesis final + nivel de confianza
```

### ⚠️ Condiciones de Pausa

El análisis PAUSA automáticamente si:
1. **Step 2:** Asunción con confianza Baja + impacto Alto → requiere validación
2. **Step 9:** Red flag crítico identificado → requiere decisión humana
3. **Step 11:** Nivel de confianza = "Bajo" → no puede proceder a Plan

Si todos los checks pasan → continúa automáticamente a Plan.

### Cómo analysis.md Alimenta al Plan

| Output del Análisis | Cómo lo usa Plan |
|--------------------|-----------------|
| Enfoque recomendado (Step 11) | Selecciona patrón de arquitectura |
| Mitigaciones de fallos (Step 5) | Agrega tasks de error handling |
| Invariantes (Step 6) | Se convierte en reglas de validación |
| Matriz de delegación IA (Step 10) | Decide scope de automatización |
| Requisitos de observabilidad (Step 7) | Agrega tasks de monitoreo |

### Multi-Agent Integration (Phase 2)

Si `docs/agents.md` existe y tiene A6 (architect) asignado a Phase 2:

1. El humano completa Steps 1-8 del protocolo de 11 pasos
2. El **agent-orchestrator** lanza A6 como Task sub-agent
3. A6 ejecuta Step 9 (Adversarial Review) con contexto limpio
4. A6 produce findings que se appendean a `analysis.md`
5. Si A6 detecta red flag crítico → AUTO-PAUSE

```
Human (Steps 1-8) → A6/architect (Step 9: Adversarial Review) → Human (Steps 10-11)
```

### 📄 Documentos actualizados
- `analysis.md` → Resultado del análisis (con Step 9 del agente A6)
- `context/decisions.md` → Decisiones clave
- `status.md` → Phase: Critical Analysis ✅

---

## Fase 3: PLAN (Diseño Técnico)

### Propósito
Diseñar la implementación ANTES de escribir código. Ahora informado por el análisis crítico.

### Cómo Iniciar
```
/plan implement FEAT-XXX
```

### Proceso

1. Claude entra en **modo plan** (solo lectura, NO edita código)
2. Lee **spec.md + analysis.md** (AMBOS son input obligatorio)
3. Exploración del codebase existente
4. Genera plan con archivos, orden, snippets
5. Usuario revisa y aprueba

### Multi-Agent Integration (Phase 3)

Si `docs/agents.md` existe y tiene A6 (architect) asignado a Phase 3:

1. `implementation-planner` genera `design.md` + `tasks.md`
2. El **agent-orchestrator** lanza A6 como Task sub-agent
3. A6 valida el diseño contra los findings de `analysis.md`
4. Si A6 verdict = "NEEDS REVISION" → re-run planner con feedback
5. Si A6 verdict = "APPROVED" → proceder a Phase 4

```
implementation-planner → A6/architect (Validation) → Proceed or Revise
```

### 📄 Documentos actualizados
- `design.md` → Arquitectura técnica (informada por analysis.md, validada por A6)
- `tasks.md` → Checklist ordenado con todas las tasks
- `status.md` → Phase: Plan ✅

---

## Fase 4: BRANCH (Preparación)

### ⚠️ REGLA CRÍTICA
```
╔═══════════════════════════════════════════════════════════════════════════╗
║  NUNCA EMPEZAR A CODEAR SIN CREAR LA RAMA PRIMERO                        ║
╚═══════════════════════════════════════════════════════════════════════════╝
```

### Proceso
```bash
git checkout main
git pull
git checkout -b feature/XXX-nombre-descriptivo
```

### Convención de Nombres
```
feature/001-auth           ✅ (número + descripción)
feature/002-db-connection  ✅
feat-001                   ❌ (muy corto)
nueva-feature              ❌ (no descriptivo)
```

### 📄 Documentos actualizados
- `status.md` → Phase: Branch ✅, Branch: feature/XXX-nombre

---

## Fase 5: IMPLEMENT (Desarrollo)

### Propósito
Implementar siguiendo el plan, con documentación viva.

### ⚠️ FLUJO OBLIGATORIO POR CADA TASK

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         POR CADA TASK                                        │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   1. ANTES DE EMPEZAR                                                       │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │ □ Actualizar tasks.md:  - [ ] Task N  →  - [🟡] Task N             │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                              │                                              │
│                              ▼                                              │
│   2. IMPLEMENTAR                                                            │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │ □ Escribir código                                                   │   │
│   │ □ Escribir tests (si aplica)                                        │   │
│   │ □ Verificar que funciona                                            │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                              │                                              │
│                              ▼                                              │
│   3. DESPUÉS DE COMPLETAR                                                   │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │ □ Actualizar tasks.md:  - [🟡] Task N  →  - [x] Task N             │   │
│   │ □ git add [archivos de esta task]                                   │   │
│   │ □ git commit -m "FEAT-XXX: Complete Task N - descripción"          │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                              │                                              │
│                              ▼                                              │
│   4. CHECKPOINT (cada 30 min o 3 tasks)                                     │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │ □ Actualizar status.md: Progress: X/Y tasks                         │   │
│   │ □ git push (backup remoto)                                          │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Orden de Implementación Típico
1. Utilidades/helpers primero
2. Modelos de datos
3. Lógica de negocio / servicios
4. API endpoints / UI
5. Integración con sistema existente
6. Tests

### Multi-Agent Integration (Phase 5)

Si `docs/agents.md` existe, Phase 5 se orquesta con múltiples agentes:

```
┌────────────────────────────────────────────────────────────────────────────┐
│ ORQUESTACIÓN MULTI-AGENT (Phase 5)                                         │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│   PARALELO (worktrees via fork-feature):                                  │
│   ┌────────────────────────────────────┐                                  │
│   │ A1 (implementor) → ejecuta tasks   │                                  │
│   │ A5 (test-writer)  → escribe tests  │  ← Dominios separados           │
│   └────────────────────────────────────┘                                  │
│                │                                                           │
│                ▼ (cada 3 tasks = checkpoint)                               │
│   RELAY SECUENCIAL (Task sub-agents):                                     │
│   ┌────────────────────────────────────┐                                  │
│   │ A2 (reviewer)     → review code    │                                  │
│   │ A3 (bug-detector) → scan bugs      │  ← Feedback a A1                │
│   └────────────────────────────────────┘                                  │
│                │                                                           │
│                ▼                                                            │
│   A1 aplica feedback → siguiente checkpoint → repetir                     │
│                                                                            │
│   OPCIONAL:                                                                │
│   A4 (doc-writer) → documenta componentes completados                     │
│                                                                            │
└────────────────────────────────────────────────────────────────────────────┘
```

**Protocolo de Checkpoint:**
1. A1 completa 3 tasks → commit + push
2. Orchestrator lanza A2 (reviewer) como Task → produce review report
3. Orchestrator lanza A3 (bug-detector) como Task → produce bug report
4. A1 recibe feedback → aplica fixes → continúa
5. Repetir hasta completar todas las tasks

**Sin `agents.md`:** Phase 5 funciona exactamente como antes (single-agent mode).

### 📄 Documentos actualizados (CONTINUAMENTE)
- `tasks.md` → Marcadores actualizados por cada task
- `status.md` → Progress actualizado cada 3 tasks (+ agent execution log)

---

## Fase 5.5: VERIFY (Browser Automation Tests) ← NUEVO

### Propósito
Validar automáticamente cambios frontend mediante browser automation antes de crear PR. Usa agent-browser (Anthropic CLI) para E2E testing.

### ¿Cuándo se ejecuta?
**Automático** cuando se detecta:
1. ✅ Cambios en archivos frontend (tsx/jsx/css/scss)
2. ✅ Scripts de test existen en `docs/features/FEAT-XXX/tests/`

Si NO hay cambios frontend o NO hay scripts → **SKIP** (no bloquea)

### Cómo Configurar Tests (Una vez por feature)

**1. Copiar templates:**
```bash
cp -r docs/features/_template/tests docs/features/FEAT-XXX/tests
```

**2. Configurar test-config.json:**
```json
{
  "feature_id": "FEAT-XXX",
  "base_url": "http://localhost:3000",
  "test_user": {
    "email": "feat-xxx-test@example.com",
    "password": "test-feat-xxx-password"
  }
}
```

**3. Personalizar e2e-flow.sh:**
```bash
# Cambiar URLs, selectores, assertions para tu feature
vim docs/features/FEAT-XXX/tests/e2e-flow.sh
```

### Qué hace Phase 5.5

1. **Detecta cambios frontend** (git diff últimos 5 commits)
2. **Crea test results directory**
3. **Ejecuta e2e-flow.sh** (test principal)
4. **Ejecuta e2e-smoke.sh** (opcional, no bloquea)
5. **Captura screenshots** en cada paso + failures
6. **Ejecuta security filters** (redacta secrets antes de commit)
7. **Genera test-report.md**
8. **Bloquea PR si tests fallan** ❌

### Test Results Structure

```
docs/features/FEAT-XXX/test-results/
├── screenshots/
│   ├── step-01-login-page.png
│   ├── step-02-feature-page.png
│   └── step-03-item-created.png
├── videos/                              (opcional)
├── console-logs.txt                     (filtrado)
├── network-logs.json                    (filtrado)
└── test-report.md
```

### Security Filters (Automático)

Antes de commit, todos los test results pasan por security filters:
- **Detecta:** API keys, tokens, passwords, AWS credentials, private keys, DB URLs
- **Redacta:** Reemplaza con `[REDACTED-API-KEY]`, `[REDACTED-TOKEN]`, etc.
- **Pre-commit hook:** Bloquea commit si secrets detectados después de filtrado

```bash
# Instalado automáticamente en setup
bash .memory-system/scripts/install-git-hooks.sh
```

### Manual Testing

```bash
# Ejecutar tests manualmente
cd docs/features/FEAT-XXX/tests
bash e2e-flow.sh

# Filtrar secrets
bash ../../../.memory-system/scripts/security-filters.sh filter-all \
  ../test-results/

# Commit (con pre-commit hook activo)
git add test-results/
git commit -m "FEAT-XXX: Add test results"
```

### Troubleshooting

**Tests fallan pero UI funciona manualmente:**
- Verificar que localhost:3000 esté corriendo
- Revisar selectores en e2e-flow.sh (pueden haber cambiado)
- Checkear console-logs.txt para errores JS

**Pre-commit hook bloquea commit:**
```bash
# Ver qué secrets detectó
bash .memory-system/scripts/security-filters.sh scan \
  docs/features/FEAT-XXX/test-results/console-logs.txt

# Filtrar y reintentar
bash .memory-system/scripts/security-filters.sh filter-all \
  docs/features/FEAT-XXX/test-results/
git add docs/features/FEAT-XXX/test-results/
git commit -m "FEAT-XXX: Add filtered test results"
```

**Quiero skip Phase 5.5:**
- No crear `docs/features/FEAT-XXX/tests/` directory
- Se detectará automáticamente y se saltará

### Multi-Agent Integration (Phase 5.5)

Si `docs/agents.md` existe con A3 y A5 asignados a Phase 5.5:

```
Tests fallan → A3 (bug-detector: root cause analysis) → A5 (test-writer: fix tests)
              └→ Si bug en producción: relay back a A1 (implementor)
```

### 📄 Documentos actualizados
- `test-results/test-report.md` → Test results
- `test-results/screenshots/` → Visual evidence
- `status.md` → Phase: Verify ✅

---

## Fase 6: PR (Pull Request)

### Proceso

```bash
# 1. Verificar estado
git status
git diff --stat --no-pager

# 2. Asegurar todo commiteado (incluyendo test results si Phase 5.5 corrió)
git add .
git commit -m "FEAT-XXX: Final adjustments"

# 3. Push
git push -u origin feature/XXX-nombre

# 4. Crear PR (incluir test results si aplica)
gh pr create --title "FEAT-XXX: Nombre Descriptivo" --body "..." --base main
```

### PR Body Incluye Test Results (Automático)

Si Phase 5.5 (VERIFY) corrió, el PR automáticamente incluye:

```markdown
## Test Results

# Test Report: FEAT-XXX
**Status:** ✅ PASSED
**Date:** 2025-02-03

## Screenshots
- step-01-login-page.png
- step-02-feature-page.png
- step-03-item-created.png

## Console Logs (filtered)
[Secrets redacted]
```

### Multi-Agent Integration (Phase 6)

Si `docs/agents.md` existe con A2 y A4 asignados a Phase 6:

```
A2 (reviewer: final review) → A4 (doc-writer: PR description) → gh pr create
```

1. A2 revisa el diff completo desde base branch → final review report
2. Si A2 encuentra issues críticos → de vuelta a Phase 5
3. A4 genera PR description con change summary + test results
4. PR se crea con la descripción de A4

### 📄 Documentos actualizados
- `status.md` → Phase: PR ✅, PR: #123 [url]
- `_index.md` → Status: 🔵 In Review

---

## Fase 7: MERGE (Cierre)

### Proceso

1. **Review** del PR
2. **Aprobar y Merge** en GitHub
3. **Actualizar documentación final**
4. **Limpiar**:
   ```bash
   git checkout main
   git pull
   git branch -d feature/XXX-nombre
   ```

### 📄 Documentos actualizados
- `status.md` → Status: 🟢 Complete, Merged: [date]
- `_index.md` → Status: 🟢 Complete

---

## Fase 8: WRAP-UP (Cierre de Contexto) ← NUEVA

### Propósito
Capturar aprendizajes, cerrar contexto, y documentar decisiones para futuras sesiones.

### Proceso

1. Revisar todas las decisiones tomadas durante implementación
2. Documentar lo que funcionó y lo que no
3. Registrar deuda técnica creada
4. Actualizar context files para futuras features

### Multi-Agent Integration (Phase 8)

Si `docs/agents.md` existe con A4 y A6 asignados a Phase 8:

```
A4 (doc-writer: wrap_up.md) → A6 (architect: architectural learnings) → merge into wrap_up.md
```

1. A4 genera `wrap_up.md` con learnings de implementación
2. A6 captura learnings arquitectónicos y evolución de patrones
3. Se appendean los findings de A6 a `wrap_up.md`

### 📄 Documentos actualizados
- `context/wrap_up.md` → Aprendizajes capturados (con learnings de A4 + A6)
- `context/decisions.md` → Decisiones finales consolidadas
- `status.md` → Phase: Wrap-Up ✅
- `_index.md` → 🟢 Complete

---

## Estructura de Archivos por Feature

```
docs/features/FEAT-XXX/
├── spec.md                ← Phase 1: Interview
├── analysis.md            ← Phase 2: Think Critically
├── design.md              ← Phase 3: Plan
├── tasks.md               ← Phase 3: Plan
├── tests.md               ← Phase 5: Implement
├── status.md              ← Updated each phase
├── tests/                 ← Phase 5.5: VERIFY
│   ├── helpers.sh         │   Reusable test functions
│   ├── e2e-flow.sh        │   Main E2E test
│   ├── e2e-smoke.sh       │   Quick smoke tests
│   └── test-config.json   │   Test configuration
├── test-results/          ← Generated by Phase 5.5
│   ├── screenshots/       │   Visual evidence
│   ├── videos/            │   (optional)
│   ├── console-logs.txt   │   Filtered
│   ├── network-logs.json  │   Filtered
│   └── test-report.md     │   Test summary
└── context/
    ├── session_log.md     ← Includes agent orchestration logs
    ├── decisions.md       ← Enriched by Think Critically
    ├── blockers.md
    └── wrap_up.md         ← Phase 8: Wrap-Up

docs/                       ← Project-level (NEW: Multi-Agent)
├── agents.md              ← Agent registry & phase assignments
└── agents/
    └── {agent-id}/
        ├── RULES.md       ← Agent rules & boundaries
        └── harness.md     ← Self-verification test harness
```

---

## Checklist Rápido

```
□ INTERVIEW
  □ Preguntas hechas
  □ Decisiones en spec.md
  □ Market Validation (Pain Level 7+)
  □ status.md → Phase: Interview ✅

□ THINK CRITICALLY                    ← NUEVO
  □ Profundidad determinada
  □ Protocolo ejecutado
  □ analysis.md generado
  □ Sin red flags críticos
  □ Confidence level ≥ Medium
  □ status.md → Phase: Critical Analysis ✅

□ PLAN
  □ spec.md + analysis.md leídos (AMBOS)
  □ Codebase explorado
  □ design.md creado
  □ tasks.md con checklist
  □ status.md → Phase: Plan ✅

□ BRANCH
  □ git checkout -b feature/XXX
  □ status.md → Branch creado

□ IMPLEMENT
  □ Por cada task:
    □ Marcar 🟡 antes
    □ Implementar
    □ Marcar ✅ después
    □ Commit
  □ Push cada 30 min
  □ status.md actualizado

□ VERIFY                              ← NUEVO
  □ Tests configurados (si frontend feature)
  □ e2e-flow.sh personalizado
  □ test-config.json completado
  □ Browser tests ejecutados
  □ Security filters aplicados
  □ test-report.md generado
  □ status.md → Verify ✅

□ PR
  □ Todo commiteado (+ test results)
  □ gh pr create (incluye test report)
  □ status.md → PR link

□ MERGE
  □ Review aprobado
  □ Merged
  □ status.md → 🟢 Complete
  □ _index.md actualizado
  □ Rama local borrada

□ WRAP-UP                             ← NUEVO
  □ Learnings capturados
  □ Deuda técnica documentada
  □ context/wrap_up.md completado
  □ status.md → Wrap-Up ✅
```

---

## Anti-Patterns

| ❌ Anti-Pattern | ✅ Correcto |
|----------------|-------------|
| Codear sin interview | Interview primero |
| Planear sin análisis crítico | Think Critically antes de Plan |
| Codear sin rama | Rama antes de código |
| Codear sin plan | Plan primero |
| Actualizar docs al final | Docs en tiempo real |
| Commits gigantes | Commit por task |
| Ignorar tests | Tests obligatorios |
| No capturar learnings | Wrap-Up al final |
| Ignorar red flags del análisis | Resolver antes de implementar |
| Proceder con confianza baja | Validar asunciones primero |
| Un agente hace todo | Agentes especializados por rol |
| Agentes sin RULES.md | Cada agente con reglas y límites claros |
| Ignorar feedback de agentes | Aplicar feedback del reviewer y bug-detector |

---

## Multi-Agent System

### Concepto

El sistema multi-agente permite que agentes especializados colaboren dentro de cada fase:

- **Relay Pattern**: Agentes se pasan trabajo en cadena (A1 → A2 → A3 → A1)
- **Paralelización**: Agentes con dominios independientes trabajan en paralelo (worktrees)
- **Contexto limpio**: Cada agente opera con su propio "headspace" enfocado
- **Andamiaje > Modelo**: RULES.md + harness.md dan al agente las herramientas para auto-verificarse

### Configuración

1. **Durante `/new-project`**: El skill `agent-designer` deriva agentes de las características del proyecto
2. **Archivo `docs/agents.md`**: Define qué agentes hay, cuándo activan, y cómo ejecutan
3. **Directorio `docs/agents/{id}/`**: Contiene RULES.md (reglas) y harness.md (auto-verificación) por agente
4. **Backward compatible**: Si no existe `agents.md`, todo funciona como antes (single-agent mode)

### Modelos de Ejecución

| Modelo | Cuándo | Mecanismo |
|--------|--------|-----------|
| **Task sub-agent** | Agentes dentro de una fase (reviewer, bug-detector) | Claude `Task` tool con RULES.md como prompt |
| **Worktree** | Implementación paralela (backend + frontend) | `fork-feature` skill |
| **Secuencial** | Relay simple de 2 agentes | Misma sesión, prompts secuenciales |

### Para Proyectos Existentes

Proyectos sin `agents.md` pueden activar multi-agent en cualquier momento:
```
/design-agents
```

---

## Flujo Completo End-to-End

```bash
# Phase 0: Setup (una vez por proyecto)
/project-interview
/saas-validate project      # Gate: Pain Level 7+?
/architecture
/mvp
# NEW: Agent Design (automático en /new-project, o manual):
/design-agents               # Deriva agentes → agents.md + RULES.md

# Per-Feature Cycle (multi-agent si agents.md existe)
/interview FEAT-001-auth
/think-critically FEAT-001-auth    # Steps 1-8 human + Step 9 A6/architect
/plan implement FEAT-001-auth      # Planner + A6 validation
git checkout -b feature/001-auth
# Implement: A1 + A5 parallel, A2 + A3 relay at checkpoints
# VERIFY: A3 + A5 if tests fail (automático si frontend changes)
/git pr                             # A2 final review + A4 PR description
# Review + merge (human)
/wrap-up FEAT-001-auth             # A4 + A6 learnings
```

---

*Última actualización: {date}*
