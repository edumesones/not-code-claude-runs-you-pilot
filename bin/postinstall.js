#!/usr/bin/env node

/**
 * Post-install script for ralph-spec-agent-mem
 *
 * Shows welcome message and installation instructions
 */

const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  cyan: '\x1b[36m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m'
};

function colorize(text, color) {
  return `${color}${text}${colors.reset}`;
}

console.log();
console.log(colorize('╔══════════════════════════════════════════════════════════════╗', colors.cyan));
console.log(colorize('║                                                              ║', colors.cyan));
console.log(colorize('║       ✅ ralph-spec-agent-mem installed successfully!        ║', colors.cyan));
console.log(colorize('║                                                              ║', colors.cyan));
console.log(colorize('╚══════════════════════════════════════════════════════════════╝', colors.cyan));
console.log();

console.log(colorize('🚀 Quick Start:', colors.bright));
console.log();
console.log('  Run the interactive installer:');
console.log(colorize('    ralph-spec-agent-mem', colors.green));
console.log();
console.log('  Or use with npx:');
console.log(colorize('    npx ralph-spec-agent-mem', colors.green));
console.log();

console.log(colorize('📦 Installation Options:', colors.bright));
console.log('  • Global: Available in ALL projects');
console.log('  • Project: Only in current project');
console.log('  • Both: Recommended for best experience');
console.log();

console.log(colorize('📚 What is Ralph Loop?', colors.blue));
console.log('  Autonomous 9-phase feature development:');
console.log('    1. Interview → 2. Think Critically → 3. Plan');
console.log('    4. Branch → 5. Implement → 5.5 Verify (E2E)');
console.log('    6. PR → 7. Merge → 8. Wrap-Up');
console.log();

console.log(colorize('🔗 Documentation:', colors.blue));
console.log('  https://github.com/edumesones/not-code-claude-runs-you-pilot');
console.log();

console.log(colorize('💡 Need help?', colors.yellow));
console.log(colorize('    ralph-spec-agent-mem --help', colors.yellow));
console.log();
