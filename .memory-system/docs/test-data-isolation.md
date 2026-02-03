# Test Data Isolation Pattern

**Purpose:** Prevent test conflicts when running browser automation for multiple features in parallel.

---

## Problem Statement

When multiple features execute browser tests simultaneously:
- **User conflicts**: Features compete for same test user (test@example.com)
- **State pollution**: Feature A's data affects Feature B's assertions
- **Database race conditions**: Parallel creates/deletes collide
- **Session conflicts**: Shared cookies/localStorage leak between tests

**Impact**: Flaky tests, false negatives, parallel execution failures.

---

## Solution: Per-Feature Test Isolation

### Strategy 1: Isolated Test Users (RECOMMENDED)

**Pattern:**
```bash
# Each feature gets dedicated test user
FEATURE_ID="FEAT-001-login"
TEST_EMAIL="feat-001-test@example.com"
TEST_PASSWORD="test-feat-001-password"
```

**Benefits:**
- ✅ Zero user conflicts
- ✅ Independent sessions
- ✅ Easy to debug (grep logs by email)
- ✅ Parallelizable

**Implementation:**

```bash
# docs/features/FEAT-XXX/tests/test-config.json
{
  "feature_id": "FEAT-001-login",
  "test_user": {
    "email": "feat-001-test@example.com",
    "password": "test-feat-001-password",
    "role": "user"
  }
}
```

**Setup Script:**
```bash
# .memory-system/scripts/setup-test-user.sh
#!/bin/bash
# Creates isolated test user for feature

FEATURE_ID=$1
TEST_EMAIL="$(echo $FEATURE_ID | tr '[:upper:]' '[:lower:]')-test@example.com"
TEST_PASSWORD="test-$FEATURE_ID-password"

# Create user via API or direct DB insert
curl -X POST http://localhost:3000/api/test/users \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$TEST_EMAIL\",
    \"password\": \"$TEST_PASSWORD\",
    \"role\": \"test_user\",
    \"feature_tag\": \"$FEATURE_ID\"
  }"

echo "✅ Test user created: $TEST_EMAIL"
```

**Cleanup Script:**
```bash
# .memory-system/scripts/cleanup-test-user.sh
#!/bin/bash
# Removes test user after tests complete

FEATURE_ID=$1
TEST_EMAIL="$(echo $FEATURE_ID | tr '[:upper:]' '[:lower:]')-test@example.com"

curl -X DELETE "http://localhost:3000/api/test/users?email=$TEST_EMAIL"
echo "🗑️  Test user deleted: $TEST_EMAIL"
```

---

### Strategy 2: Database Snapshots (Advanced)

**Pattern:**
```bash
# Before test: Create snapshot
docker exec postgres pg_dump testdb > snapshot-feat-001.sql

# Run tests
bash docs/features/FEAT-001/tests/e2e-flow.sh

# After test: Restore snapshot
docker exec postgres psql testdb < snapshot-feat-001.sql
```

**Benefits:**
- ✅ Perfect isolation
- ✅ Repeatable state
- ✅ Fast rollback

**Drawbacks:**
- ❌ Slower (dump/restore overhead)
- ❌ Requires Docker/DB access
- ❌ Not suitable for cloud DBs

**Use when:** Testing data migrations, schema changes, or destructive operations.

---

### Strategy 3: Mock APIs (Maximum Isolation)

**Pattern:**
```bash
# Start mock server per feature
docker run -d --name feat-001-mock \
  -p 9001:9000 \
  mockserver/mockserver

# Point test to mock
agent-browser --session "feat-001" open "http://localhost:3000?api=http://localhost:9001"
```

**Benefits:**
- ✅ Zero DB dependency
- ✅ Predictable responses
- ✅ Fast execution
- ✅ Offline testing

**Drawbacks:**
- ❌ Doesn't test real API
- ❌ Mock drift from production
- ❌ Extra infrastructure

**Use when:** Testing frontend logic without backend, or when backend is unstable.

---

## Integration with Ralph Loop

### Phase 5.5 (VERIFY) - Test Setup

```bash
# ralph-feature.sh (Phase 5.5)

verify_frontend() {
  local FEATURE_ID=$1

  # 1. Setup isolated test user
  echo "🔧 Setting up test isolation..."
  bash .memory-system/scripts/setup-test-user.sh "$FEATURE_ID"

  # 2. Load test config
  local CONFIG="docs/features/$FEATURE_ID/tests/test-config.json"
  export TEST_EMAIL=$(jq -r '.test_user.email' "$CONFIG")
  export TEST_PASSWORD=$(jq -r '.test_user.password' "$CONFIG")

  # 3. Run tests with isolated session
  local SESSION="ralph-$FEATURE_ID"
  bash "docs/features/$FEATURE_ID/tests/e2e-flow.sh" --session "$SESSION"

  # 4. Cleanup
  bash .memory-system/scripts/cleanup-test-user.sh "$FEATURE_ID"
}
```

---

## Test Configuration Schema

**docs/features/FEAT-XXX/tests/test-config.json**

```json
{
  "feature_id": "FEAT-001-login",
  "isolation_strategy": "isolated_user",
  "test_user": {
    "email": "feat-001-test@example.com",
    "password": "test-feat-001-password",
    "role": "user",
    "auto_create": true,
    "auto_cleanup": true
  },
  "database": {
    "snapshot_enabled": false,
    "snapshot_path": "./test-results/db-snapshot.sql"
  },
  "mock_api": {
    "enabled": false,
    "port": 9001,
    "config_path": "./test-results/mock-config.json"
  }
}
```

---

## Best Practices

### DO ✅
- **Use feature-scoped test users** (feat-xxx-test@example.com)
- **Clean up after tests** (delete test users, reset state)
- **Tag test data** (add `feature_tag: FEAT-XXX` to DB records)
- **Unique session names** (ralph-FEAT-XXX)
- **Environment variables** for credentials (never hardcode)

### DON'T ❌
- **Share test users** across features (causes conflicts)
- **Use production data** in tests (security risk)
- **Leave test data** in DB after completion (pollution)
- **Hardcode credentials** in test scripts (use config files + env vars)
- **Run tests on same port** (use dynamic port allocation)

---

## Troubleshooting

### Issue: "User already exists"
**Cause:** Previous test didn't clean up
**Fix:**
```bash
bash .memory-system/scripts/cleanup-test-user.sh FEAT-XXX
```

### Issue: "Session conflict"
**Cause:** Two features using same session name
**Fix:** Ensure session name includes feature ID:
```bash
SESSION="ralph-$FEATURE_ID"  # ✅ Good
SESSION="ralph-test"          # ❌ Bad
```

### Issue: "Stale data in test"
**Cause:** DB state from previous run
**Fix:** Enable database snapshots:
```json
{
  "database": {
    "snapshot_enabled": true
  }
}
```

---

## Examples

### Example 1: Simple Login Test (Isolated User)

**test-config.json:**
```json
{
  "feature_id": "FEAT-001-login",
  "isolation_strategy": "isolated_user",
  "test_user": {
    "email": "feat-001-test@example.com",
    "password": "test-feat-001-password"
  }
}
```

**e2e-flow.sh:**
```bash
#!/bin/bash
FEATURE_ID="FEAT-001-login"
SESSION="ralph-$FEATURE_ID"

# Load config
TEST_EMAIL=$(jq -r '.test_user.email' tests/test-config.json)
TEST_PASSWORD=$(jq -r '.test_user.password' tests/test-config.json)

# Run test
agent-browser --session "$SESSION" open "http://localhost:3000/login"
agent-browser --session "$SESSION" fill "input[type='email']" "$TEST_EMAIL"
agent-browser --session "$SESSION" fill "input[type='password']" "$TEST_PASSWORD"
agent-browser --session "$SESSION" click "button[type='submit']"
```

---

### Example 2: CRUD Test (DB Snapshot)

**test-config.json:**
```json
{
  "feature_id": "FEAT-002-crud",
  "isolation_strategy": "db_snapshot",
  "database": {
    "snapshot_enabled": true,
    "snapshot_path": "./test-results/db-snapshot.sql"
  }
}
```

**e2e-flow.sh:**
```bash
#!/bin/bash
FEATURE_ID="FEAT-002-crud"

# Create snapshot
docker exec postgres pg_dump testdb > ./test-results/db-snapshot.sql

# Run test
agent-browser --session "ralph-$FEATURE_ID" open "http://localhost:3000/items"
# ... test actions ...

# Restore snapshot
docker exec postgres psql testdb < ./test-results/db-snapshot.sql
```

---

## Security Considerations

### Credentials Management
- **NEVER commit** test credentials to git
- **Use .env files** + .gitignore
- **Rotate test passwords** regularly (monthly)
- **Limit test user permissions** (read-only where possible)

### Secret Detection
All test configs are scanned by security-filters.sh:
```bash
bash .memory-system/scripts/security-filters.sh scan docs/features/FEAT-XXX/tests/test-config.json
```

**Blocked patterns:**
- Real API keys (length >20 chars)
- Production passwords
- AWS credentials
- Private keys

**Allowed patterns:**
- Short test passwords (<20 chars)
- localhost URLs
- Feature-scoped test emails

---

## Summary

**Recommended Strategy by Feature Type:**

| Feature Type | Strategy | Rationale |
|--------------|----------|-----------|
| Login/Auth | Isolated User | Simple, no DB pollution |
| CRUD | Isolated User | Independent records per feature |
| Data Migration | DB Snapshot | Repeatable state required |
| Frontend-only | Mock API | No backend dependency |
| Multi-user flows | Isolated Users (multiple) | Each user = separate feature tag |

**Default:** Start with **Isolated User** strategy. Upgrade to DB Snapshot only if tests become flaky.

---

**Next Steps:**
1. Create test user setup/cleanup scripts
2. Add test-config.json template to feature scaffold
3. Update ralph-feature.sh to call setup-test-user.sh in Phase 5.5
4. Document in Ralph Loop Guide

---

**References:**
- Playwright best practices: https://playwright.dev/docs/best-practices
- Test isolation patterns: https://martinfowler.com/articles/database-testing.html
