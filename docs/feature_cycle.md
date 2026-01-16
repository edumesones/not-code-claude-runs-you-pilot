# Feature Development Cycle

## Objetivo

Este documento define el flujo de trabajo exacto para implementar cualquier feature. Siguiendo este ciclo se garantiza consistencia, trazabilidad y calidad.

---

## Resumen Visual

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        FEATURE DEVELOPMENT CYCLE                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   1. INTERVIEW          2. PLAN            3. BRANCH         4. IMPLEMENT   │
│   ┌─────────┐          ┌─────────┐        ┌─────────┐       ┌─────────┐    │
│   │ Preguntas│   ───►  │ Explorar │  ───► │ git     │ ───►  │ Código  │    │
│   │ Decisiones│        │ Diseñar │        │ checkout│       │ Tests   │    │
│   │ spec.md  │         │ Plan.md │        │ -b      │       │ Commits │    │
│   └─────────┘          └─────────┘        └─────────┘       └─────────┘    │
│       │                    │                                      │         │
│       ▼                    ▼                                      ▼         │
│   📄 spec.md           📄 design.md                          📄 tasks.md   │
│   📄 status.md         📄 tasks.md                           📄 status.md  │
│   UPDATED              CREATED                                LIVE UPDATES │
│                                                                    │        │
│                                                                    ▼        │
│   6. MERGE              5. PR              ◄────────────────────────        │
│   ┌─────────┐          ┌─────────┐                                          │
│   │ Review  │   ◄───   │ Push    │                                          │
│   │ Approve │          │ gh pr   │                                          │
│   │ Update  │          │ create  │                                          │
│   └─────────┘          └─────────┘                                          │
│       │                                                                      │
│       ▼                                                                      │
│   📄 status.md → 🟢 Complete                                                │
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
│   │ Interview completado  → Phase: Interview ✅                         │   │
│   │ Plan aprobado         → Phase: Plan ✅                              │   │
│   │ Branch creado         → Phase: Branch ✅, Current: Implement        │   │
│   │ Cada 3 tasks          → Progress: 3/10 tasks                        │   │
│   │ Blocker encontrado    → Blockers: [descripción]                     │   │
│   │ PR creado             → Phase: PR, Link: [url]                      │   │
│   │ Merged                → Status: 🟢 Complete                         │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │ _index.md (dashboard) - ACTUALIZAR EN CAMBIO DE STATUS              │   │
│   ├─────────────────────────────────────────────────────────────────────┤   │
│   │ Feature empieza       → ⚪ Pending  →  🟡 In Progress               │   │
│   │ PR creado             → 🟡 In Progress  →  🔵 In Review             │   │
│   │ Merged                → 🔵 In Review  →  🟢 Complete                │   │
│   │ Bloqueado             → 🟡 In Progress  →  🔴 Blocked               │   │
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
```

### Proceso

1. **Claude hace preguntas estructuradas** (máx 3-4 por turno):
   - UI/UX decisions
   - Comportamiento del sistema
   - Edge cases
   - Límites y restricciones
   - Integraciones

2. **El usuario responde con opciones claras**:
   - ✅ BIEN: "Import desde .env (DATABASE_URL format)"
   - ✅ BIEN: "Retry 3x automático + notificación"
   - ❌ MAL: "No sé, lo que tú creas"

3. **Claude actualiza spec.md** con cada decisión en formato tabla

### 📄 Documentos actualizados
- `spec.md` → Decisiones documentadas
- `status.md` → Phase: Interview ✅

---

## Fase 2: PLAN (Diseño Técnico)

### Propósito
Diseñar la implementación ANTES de escribir código.

### Cómo Iniciar
```
/plan implement FEAT-XXX
```

### Proceso

1. Claude entra en **modo plan** (solo lectura, NO edita código)
2. Exploración del codebase existente
3. Genera plan con archivos, orden, snippets
4. Usuario revisa y aprueba

### 📄 Documentos actualizados
- `design.md` → Arquitectura técnica
- `tasks.md` → Checklist ordenado con todas las tasks
- `status.md` → Phase: Plan ✅

---

## Fase 3: BRANCH (Preparación)

### ⚠️ REGLA CRÍTICA
```
╔═══════════════════════════════════════════════════════════════╗
║  NUNCA EMPEZAR A CODEAR SIN CREAR LA RAMA PRIMERO            ║
╚═══════════════════════════════════════════════════════════════╝
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

## Fase 4: IMPLEMENT (Desarrollo)

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
│   │ □ (Opcional) Actualizar status.md: "Working on: Task N"            │   │
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

### Reglas de Implementación

| ✅ HACER | ❌ NO HACER |
|----------|-------------|
| Un archivo/módulo a la vez | Implementar todo de golpe |
| Commit después de cada task | Commits gigantes |
| Tests para cada módulo nuevo | Saltarse los tests |
| Seguir patrones existentes | Inventar nuevos patrones |
| Actualizar docs en tiempo real | Dejar docs para el final |

### 📄 Documentos actualizados (CONTINUAMENTE)
- `tasks.md` → Marcadores actualizados por cada task
- `status.md` → Progress actualizado cada 3 tasks

---

## Fase 5: PR (Pull Request)

### Proceso

```bash
# 1. Verificar estado
git status
git diff --stat --no-pager

# 2. Asegurar todo commiteado
git add .
git commit -m "FEAT-XXX: Final adjustments"

# 3. Push
git push -u origin feature/XXX-nombre

# 4. Crear PR
gh pr create --title "FEAT-XXX: Nombre Descriptivo" --body "$(cat <<'EOF'
## Summary
[1-3 bullets de qué hace]

## Features
- [x] Feature 1
- [x] Feature 2

## Files Changed
**New:** src/module/...
**Modified:** src/main.py

## Tests
- X unit tests ✅
- Y integration tests ✅

## Checklist
- [x] Tests passing
- [x] Docs updated
- [x] No console.logs / prints
EOF
)" --base main
```

### 📄 Documentos actualizados
- `status.md` → Phase: PR ✅, PR: #123 [url]
- `_index.md` → Status: 🔵 In Review

---

## Fase 6: MERGE (Cierre)

### Proceso

1. **Review** del PR
2. **Aprobar y Merge** en GitHub
3. **Actualizar documentación final**:
   ```
   "Update FEAT-XXX status to complete and update dashboard"
   ```
4. **Limpiar**:
   ```bash
   git checkout main
   git pull
   git branch -d feature/XXX-nombre
   ```

### 📄 Documentos actualizados
- `status.md` → Status: 🟢 Complete, Merged: [date]
- `_index.md` → Status: 🟢 Complete
- `tests.md` → Results documentados

---

## Trabajo en Paralelo (Fork)

### Cuándo usar Fork
- Feature grande que se puede dividir (backend + frontend)
- Quieres acelerar desarrollo
- Tasks independientes que no se pisan

### Cómo funciona

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         PARALLEL WORK WITH FORK                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   Terminal Principal (tú)                                                   │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │ Orquesta, revisa, hace tareas que no se pueden paralelizar          │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│        │                                                                     │
│        ├──► /fork-feature FEAT-001 backend                                  │
│        │    ┌─────────────────────────────────────────────────────────┐     │
│        │    │ Nueva terminal con contexto de FEAT-001                 │     │
│        │    │ Solo trabaja en tasks de Backend                        │     │
│        │    │ Actualiza tasks.md en tiempo real                       │     │
│        │    └─────────────────────────────────────────────────────────┘     │
│        │                                                                     │
│        └──► /fork-feature FEAT-001 frontend                                 │
│             ┌─────────────────────────────────────────────────────────┐     │
│             │ Nueva terminal con contexto de FEAT-001                 │     │
│             │ Solo trabaja en tasks de Frontend                       │     │
│             │ Actualiza tasks.md en tiempo real                       │     │
│             └─────────────────────────────────────────────────────────┘     │
│                                                                              │
│   ⚠️  IMPORTANTE: Ambos trabajan en MISMA RAMA                              │
│   ⚠️  Hacer git pull frecuente para evitar conflictos                       │
│   ⚠️  Cada fork actualiza SU SECCIÓN de tasks.md                            │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Comandos Fork
```bash
# Fork para backend
/fork-feature FEAT-001-auth backend

# Fork para frontend  
/fork-feature FEAT-001-auth frontend

# Fork para tests
/fork-feature FEAT-001-auth tests
```

---

## Checklist Rápido

```
□ INTERVIEW
  □ Preguntas hechas
  □ Decisiones en spec.md
  □ status.md → Phase: Interview ✅

□ PLAN  
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

□ PR
  □ Todo commiteado
  □ gh pr create
  □ status.md → PR link

□ MERGE
  □ Review aprobado
  □ Merged
  □ status.md → 🟢 Complete
  □ _index.md actualizado
  □ Rama local borrada
```

---

## Anti-Patterns

| ❌ Anti-Pattern | ✅ Correcto |
|----------------|-------------|
| Codear sin interview | Interview primero |
| Codear sin rama | Rama antes de código |
| Codear sin plan | Plan primero |
| Actualizar docs al final | Docs en tiempo real |
| Commits gigantes | Commit por task |
| Ignorar tests | Tests obligatorios |
| Fork sin contexto | Fork con /fork-feature |

---

*Última actualización: {date}*
