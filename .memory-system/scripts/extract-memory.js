#!/usr/bin/env node

/**
 * Memory Extraction System for Ralph Loop
 *
 * Critical Features:
 * - Secret detection (prevents credential leaks)
 * - Branch-aware storage
 * - Schema versioning
 * - Configurable confidence decay
 * - Atomic writes (corruption prevention)
 * - Deduplication (Jaccard similarity)
 */

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

// ============================================================================
// CONFIGURATION
// ============================================================================

const MEMORY_DIR = process.env.MEMORY_DIR || '.memory';
const STATE_FILE = path.join(MEMORY_DIR, 'state.json');
const BACKUP_DIR = path.join(MEMORY_DIR, 'snapshots');

// Secret detection patterns (from Critical Analysis Step 9)
const SECRET_PATTERNS = [
  /api[_-]?key\s*[:=]\s*['"]?[a-zA-Z0-9_\-]{20,}/gi,
  /password\s*[:=]\s*['"]?[^\s'"]{8,}/gi,
  /bearer\s+[a-zA-Z0-9_\-\.]{20,}/gi,
  /token\s*[:=]\s*['"]?[a-zA-Z0-9_\-\.]{20,}/gi,
  /secret\s*[:=]\s*['"]?[a-zA-Z0-9_\-]{20,}/gi,
  /aws[_-]?access[_-]?key[_-]?id/gi,
  /-----BEGIN\s+(RSA\s+)?PRIVATE\s+KEY-----/gi,
];

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

/**
 * Load state.json with corruption handling
 */
function loadState() {
  try {
    if (!fs.existsSync(STATE_FILE)) {
      return createInitialState();
    }

    const content = fs.readFileSync(STATE_FILE, 'utf8');
    const state = JSON.parse(content);

    // Validate schema version
    if (!state.version || !state.metadata.schema_version) {
      console.warn('⚠️  State file missing version info, adding...');
      state.version = '1.0';
      state.metadata.schema_version = '1.0.0';
    }

    return state;
  } catch (error) {
    console.error('❌ Error loading state.json:', error.message);
    console.log('🔄 Attempting to restore from backup...');

    // Try to restore from most recent backup
    const backups = fs.readdirSync(BACKUP_DIR)
      .filter(f => f.startsWith('state-') && f.endsWith('.json'))
      .sort()
      .reverse();

    if (backups.length > 0) {
      const latestBackup = path.join(BACKUP_DIR, backups[0]);
      console.log(`📦 Restoring from ${backups[0]}`);
      const content = fs.readFileSync(latestBackup, 'utf8');
      return JSON.parse(content);
    }

    console.log('⚠️  No backups found, creating fresh state');
    return createInitialState();
  }
}

/**
 * Create initial state structure
 */
function createInitialState() {
  return {
    version: '1.0',
    memories: [],
    metadata: {
      total_memories: 0,
      last_consolidation: null,
      confidence_avg: 0,
      features_processed: [],
      schema_version: '1.0.0',
      created_at: new Date().toISOString()
    },
    config: {
      confidence_decay_enabled: false,
      confidence_decay_rate: 0.01,
      max_memories: 2000,
      deduplication_threshold: 0.8,
      secret_detection_enabled: true
    }
  };
}

/**
 * Save state with atomic writes and backup
 */
function saveState(state) {
  try {
    // Backup current state first
    if (fs.existsSync(STATE_FILE)) {
      const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
      const backupPath = path.join(BACKUP_DIR, `state-${timestamp}.json`);
      fs.copyFileSync(STATE_FILE, backupPath);

      // Keep only last 30 backups
      const backups = fs.readdirSync(BACKUP_DIR)
        .filter(f => f.startsWith('state-') && f.endsWith('.json'))
        .sort();

      if (backups.length > 30) {
        backups.slice(0, backups.length - 30).forEach(old => {
          fs.unlinkSync(path.join(BACKUP_DIR, old));
        });
      }
    }

    // Atomic write: temp file + rename
    const tempFile = STATE_FILE + '.tmp';
    fs.writeFileSync(tempFile, JSON.stringify(state, null, 2), 'utf8');
    fs.renameSync(tempFile, STATE_FILE);

    console.log('✅ State saved successfully');
  } catch (error) {
    console.error('❌ Error saving state:', error.message);
    throw error;
  }
}

/**
 * Generate unique memory ID
 */
function generateId() {
  return `mem-${Date.now()}-${crypto.randomBytes(4).toString('hex')}`;
}

/**
 * Get current git branch
 */
function getCurrentBranch() {
  try {
    const result = require('child_process')
      .execSync('git rev-parse --abbrev-ref HEAD', { encoding: 'utf8' });
    return result.trim();
  } catch (error) {
    return 'unknown';
  }
}

/**
 * Detect secrets in content (Critical: Step 9 mitigation)
 */
function detectSecrets(content) {
  const secrets = [];

  SECRET_PATTERNS.forEach((pattern, index) => {
    const matches = content.match(pattern);
    if (matches) {
      secrets.push({
        pattern: pattern.toString(),
        matches: matches.length,
        sample: matches[0].substring(0, 50) + '...'
      });
    }
  });

  return secrets;
}

/**
 * Sanitize content by removing detected secrets
 */
function sanitizeContent(content) {
  let sanitized = content;

  SECRET_PATTERNS.forEach(pattern => {
    sanitized = sanitized.replace(pattern, '[REDACTED]');
  });

  return sanitized;
}

/**
 * Calculate Jaccard similarity between two strings
 */
function jaccardSimilarity(str1, str2) {
  const tokens1 = new Set(str1.toLowerCase().split(/\s+/));
  const tokens2 = new Set(str2.toLowerCase().split(/\s+/));

  const intersection = new Set([...tokens1].filter(x => tokens2.has(x)));
  const union = new Set([...tokens1, ...tokens2]);

  return intersection.size / union.size;
}

/**
 * Check if memory is duplicate
 */
function isDuplicate(newMemory, existingMemories, threshold = 0.8) {
  return existingMemories.some(existing => {
    if (existing.category !== newMemory.category) return false;

    const similarity = jaccardSimilarity(
      newMemory.content,
      existing.content
    );

    return similarity > threshold;
  });
}

/**
 * Apply confidence decay to old memories
 */
function applyConfidenceDecay(state) {
  if (!state.config.confidence_decay_enabled) {
    console.log('ℹ️  Confidence decay is disabled');
    return;
  }

  const now = new Date();
  const decayRate = state.config.confidence_decay_rate;
  let decayedCount = 0;

  state.memories.forEach(memory => {
    const memoryDate = new Date(memory.source.timestamp);
    const daysOld = (now - memoryDate) / (1000 * 60 * 60 * 24);

    const decayFactor = Math.max(0.3, 1 - (daysOld * decayRate));
    const oldConfidence = memory.confidence;
    memory.confidence = Math.min(memory.confidence, decayFactor);

    if (memory.confidence < oldConfidence) {
      decayedCount++;
    }
  });

  // Remove memories with very low confidence
  const beforeCount = state.memories.length;
  state.memories = state.memories.filter(m => m.confidence >= 0.3);
  const removedCount = beforeCount - state.memories.length;

  console.log(`🔄 Confidence decay: ${decayedCount} memories decayed, ${removedCount} pruned`);
}

// ============================================================================
// EXTRACTION FUNCTIONS
// ============================================================================

class MemoryExtractor {
  constructor() {
    this.branch = getCurrentBranch();
  }

  /**
   * Extract memories from Interview phase (spec.md)
   */
  extractFromInterview(featureId, specContent) {
    const memories = [];

    // Check for secrets
    const secrets = detectSecrets(specContent);
    if (secrets.length > 0) {
      console.warn('⚠️  WARNING: Potential secrets detected in spec.md:');
      secrets.forEach(s => console.warn(`   - ${s.pattern}: ${s.matches} matches`));
      console.warn('   Content will be sanitized');
      specContent = sanitizeContent(specContent);
    }

    // Parse Technical Decisions table
    const decisionsMatch = specContent.match(/## Technical Decisions\n\n([\s\S]*?)(?=\n##|\n$)/);
    if (decisionsMatch) {
      const tableRows = decisionsMatch[1].split('\n').filter(line => line.includes('|'));

      tableRows.slice(2).forEach(row => {
        const cells = row.split('|').map(c => c.trim()).filter(Boolean);
        if (cells.length >= 4 && cells[3] !== 'TBD' && cells[3] !== '') {
          memories.push({
            id: generateId(),
            category: 'Decisions',
            content: `${featureId}: ${cells[2]} → ${cells[3]}. ${cells[4] || ''}`,
            confidence: 0.8,
            source: {
              feature: featureId,
              phase: 'Interview',
              branch: this.branch,
              timestamp: new Date().toISOString()
            },
            tags: [cells[1].toLowerCase().replace(/\s+/g, '-')],
            references: [`docs/features/${featureId}/spec.md`],
            supersedes: null
          });
        }
      });
    }

    return memories;
  }

  /**
   * Extract memories from Think Critically phase (analysis.md)
   */
  extractFromAnalysis(featureId, analysisContent) {
    const memories = [];

    // Extract assumptions
    const assumptionsMatch = analysisContent.match(/## (?:Step )?2:? (?:Implicit )?Assumptions?([\s\S]*?)(?=\n##|\n$)/i);
    if (assumptionsMatch) {
      // Parse assumption table
      const tableRows = assumptionsMatch[1].split('\n').filter(line => line.includes('|'));

      tableRows.slice(2).forEach(row => {
        const cells = row.split('|').map(c => c.trim()).filter(Boolean);
        if (cells.length >= 4 && cells[0]) {
          const confidence = cells[3].toLowerCase().includes('high') ? 0.9
                           : cells[3].toLowerCase().includes('medium') ? 0.7
                           : 0.5;

          memories.push({
            id: generateId(),
            category: 'Decisions',
            content: `${featureId}: Assumption - ${cells[1]}. Impact if wrong: ${cells[2]}`,
            confidence: confidence,
            source: {
              feature: featureId,
              phase: 'Analysis',
              branch: this.branch,
              timestamp: new Date().toISOString(),
              context: `Confidence: ${cells[3]}`
            },
            tags: ['assumption', 'analysis'],
            references: [`docs/features/${featureId}/analysis.md`],
            supersedes: null
          });
        }
      });
    }

    // Extract failure modes as gotchas
    const failuresMatch = analysisContent.match(/## (?:Step )?5:? (?:Failure[- ]?First )?(?:Failure )?Analysis([\s\S]*?)(?=\n##|\n$)/i);
    if (failuresMatch) {
      // Parse failure table
      const tableRows = failuresMatch[1].split('\n').filter(line => line.includes('|'));

      tableRows.slice(2).forEach(row => {
        const cells = row.split('|').map(c => c.trim()).filter(Boolean);
        if (cells.length >= 4 && cells[0]) {
          memories.push({
            id: generateId(),
            category: 'Gotchas',
            content: `${featureId}: ${cells[0]}. Detection: ${cells[3]}. Mitigation: ${cells[4] || 'TBD'}`,
            confidence: 0.85,
            source: {
              feature: featureId,
              phase: 'Analysis',
              branch: this.branch,
              timestamp: new Date().toISOString()
            },
            tags: ['failure-mode', 'risk', 'gotcha'],
            references: [`docs/features/${featureId}/analysis.md`],
            supersedes: null
          });
        }
      });
    }

    return memories;
  }

  /**
   * Extract memories from Plan phase (design.md)
   */
  extractFromPlan(featureId, designContent) {
    const memories = [];

    // Extract architecture decisions
    const archMatch = designContent.match(/## Architecture([\s\S]*?)(?=\n##|\n$)/i);
    if (archMatch) {
      const patterns = archMatch[1].split('\n').filter(line => line.trim().startsWith('-') || line.trim().startsWith('*'));

      patterns.forEach(pattern => {
        const content = pattern.replace(/^[-*]\s+/, '').trim();
        if (content && content.length > 10) {
          memories.push({
            id: generateId(),
            category: 'Architecture',
            content: `${featureId}: ${content}`,
            confidence: 0.9,
            source: {
              feature: featureId,
              phase: 'Plan',
              branch: this.branch,
              timestamp: new Date().toISOString()
            },
            tags: ['architecture', 'pattern', 'design'],
            references: [`docs/features/${featureId}/design.md`],
            supersedes: null
          });
        }
      });
    }

    return memories;
  }

  /**
   * Extract memories from Wrap-Up phase (wrap_up.md)
   */
  extractFromWrapUp(featureId, wrapUpContent) {
    const memories = [];

    // Extract learnings
    const learningsMatch = wrapUpContent.match(/## (?:Key )?Learnings?([\s\S]*?)(?=\n##|\n$)/i);
    if (learningsMatch) {
      const learnings = learningsMatch[1].split('\n').filter(line => line.trim().startsWith('-') || line.trim().startsWith('*'));

      learnings.forEach(learning => {
        const content = learning.replace(/^[-*]\s+/, '').trim();
        if (content && content.length > 10) {
          memories.push({
            id: generateId(),
            category: 'Progress',
            content: `${featureId}: ${content}`,
            confidence: 0.95,
            source: {
              feature: featureId,
              phase: 'WrapUp',
              branch: this.branch,
              timestamp: new Date().toISOString()
            },
            tags: ['learning', 'retrospective', 'completed'],
            references: [`docs/features/${featureId}/context/wrap_up.md`],
            supersedes: null
          });
        }
      });
    }

    // Extract gotchas
    const gotchasMatch = wrapUpContent.match(/## (?:Gotchas )?(?:Encountered|Found)([\s\S]*?)(?=\n##|\n$)/i);
    if (gotchasMatch) {
      const gotchas = gotchasMatch[1].split('\n').filter(line => line.trim().startsWith('-') || line.trim().startsWith('*'));

      gotchas.forEach(gotcha => {
        const content = gotcha.replace(/^[-*]\s+/, '').trim();
        if (content && content.length > 10) {
          memories.push({
            id: generateId(),
            category: 'Gotchas',
            content: `${featureId}: ${content}`,
            confidence: 0.98,
            source: {
              feature: featureId,
              phase: 'WrapUp',
              branch: this.branch,
              timestamp: new Date().toISOString()
            },
            tags: ['gotcha', 'production', 'validated'],
            references: [`docs/features/${featureId}/context/wrap_up.md`],
            supersedes: null
          });
        }
      });
    }

    return memories;
  }

  /**
   * Add memories to state with deduplication
   */
  addMemories(memories) {
    const state = loadState();
    const threshold = state.config.deduplication_threshold;

    let addedCount = 0;
    let duplicateCount = 0;

    memories.forEach(newMemory => {
      // Check for duplicates
      if (isDuplicate(newMemory, state.memories, threshold)) {
        duplicateCount++;
        console.log(`⏭️  Skipping duplicate: ${newMemory.content.substring(0, 60)}...`);
        return;
      }

      state.memories.push(newMemory);
      addedCount++;

      // Update features_processed
      if (!state.metadata.features_processed.includes(newMemory.source.feature)) {
        state.metadata.features_processed.push(newMemory.source.feature);
      }
    });

    // Update metadata
    state.metadata.total_memories = state.memories.length;
    state.metadata.last_consolidation = new Date().toISOString();
    state.metadata.confidence_avg =
      state.memories.reduce((sum, m) => sum + m.confidence, 0) / state.memories.length || 0;

    // Check max memories limit
    if (state.memories.length > state.config.max_memories) {
      console.warn(`⚠️  Memory limit exceeded (${state.memories.length} > ${state.config.max_memories})`);
      console.log('🧹 Pruning lowest confidence memories...');

      state.memories.sort((a, b) => b.confidence - a.confidence);
      state.memories = state.memories.slice(0, state.config.max_memories);
      state.metadata.total_memories = state.memories.length;
    }

    saveState(state);

    console.log(`✅ Added ${addedCount} memories (${duplicateCount} duplicates skipped)`);
    console.log(`📊 Total memories: ${state.metadata.total_memories}`);
    console.log(`📈 Avg confidence: ${state.metadata.confidence_avg.toFixed(2)}`);

    return state;
  }
}

// ============================================================================
// CLI INTERFACE
// ============================================================================

const [,, command, ...args] = process.argv;

const extractor = new MemoryExtractor();

try {
  switch (command) {
    case 'interview': {
      const [featureId, specPath] = args;
      if (!featureId || !specPath) {
        throw new Error('Usage: interview <featureId> <specPath>');
      }

      console.log(`\n📝 Extracting memories from Interview phase: ${featureId}`);
      const specContent = fs.readFileSync(specPath, 'utf8');
      const memories = extractor.extractFromInterview(featureId, specContent);
      extractor.addMemories(memories);
      break;
    }

    case 'analysis': {
      const [featureId, analysisPath] = args;
      if (!featureId || !analysisPath) {
        throw new Error('Usage: analysis <featureId> <analysisPath>');
      }

      console.log(`\n🧠 Extracting memories from Analysis phase: ${featureId}`);
      const analysisContent = fs.readFileSync(analysisPath, 'utf8');
      const memories = extractor.extractFromAnalysis(featureId, analysisContent);
      extractor.addMemories(memories);
      break;
    }

    case 'plan': {
      const [featureId, designPath] = args;
      if (!featureId || !designPath) {
        throw new Error('Usage: plan <featureId> <designPath>');
      }

      console.log(`\n🏗️  Extracting memories from Plan phase: ${featureId}`);
      const designContent = fs.readFileSync(designPath, 'utf8');
      const memories = extractor.extractFromPlan(featureId, designContent);
      extractor.addMemories(memories);
      break;
    }

    case 'wrapup': {
      const [featureId, wrapUpPath] = args;
      if (!featureId || !wrapUpPath) {
        throw new Error('Usage: wrapup <featureId> <wrapUpPath>');
      }

      console.log(`\n🎁 Extracting memories from WrapUp phase: ${featureId}`);
      const wrapUpContent = fs.readFileSync(wrapUpPath, 'utf8');
      const memories = extractor.extractFromWrapUp(featureId, wrapUpContent);
      extractor.addMemories(memories);
      break;
    }

    case 'decay': {
      console.log('\n🔄 Applying confidence decay...');
      const state = loadState();
      applyConfidenceDecay(state);
      saveState(state);
      break;
    }

    case 'stats': {
      const state = loadState();
      console.log('\n📊 Memory Statistics:');
      console.log(`   Total memories: ${state.metadata.total_memories}`);
      console.log(`   Avg confidence: ${state.metadata.confidence_avg.toFixed(2)}`);
      console.log(`   Features processed: ${state.metadata.features_processed.length}`);
      console.log(`   Last consolidation: ${state.metadata.last_consolidation || 'Never'}`);
      console.log(`   Schema version: ${state.metadata.schema_version}`);
      console.log('\n⚙️  Configuration:');
      console.log(`   Decay enabled: ${state.config.confidence_decay_enabled}`);
      console.log(`   Decay rate: ${state.config.confidence_decay_rate}/day`);
      console.log(`   Max memories: ${state.config.max_memories}`);
      console.log(`   Dedup threshold: ${state.config.deduplication_threshold}`);
      console.log(`   Secret detection: ${state.config.secret_detection_enabled}`);
      break;
    }

    default:
      console.log(`
Memory Extraction System for Ralph Loop

Usage: node extract-memory.js <command> <args>

Commands:
  interview <featureId> <specPath>       Extract from Interview phase
  analysis <featureId> <analysisPath>    Extract from Analysis phase
  plan <featureId> <designPath>          Extract from Plan phase
  wrapup <featureId> <wrapUpPath>        Extract from WrapUp phase
  decay                                  Apply confidence decay to all memories
  stats                                  Show memory statistics

Examples:
  node extract-memory.js interview FEAT-001 docs/features/FEAT-001/spec.md
  node extract-memory.js analysis FEAT-001 docs/features/FEAT-001/analysis.md
  node extract-memory.js decay
  node extract-memory.js stats
`);
  }
} catch (error) {
  console.error(`\n❌ Error: ${error.message}`);
  process.exit(1);
}
