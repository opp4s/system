#!/usr/bin/env node
// Patches store/index.js to register funnels Vuex module.
const fs = require('fs');
const path = process.argv[2];
if (!path) { process.stderr.write('Usage: node patch-store.js <file>\n'); process.exit(1); }

let src = fs.readFileSync(path, 'utf8');

if (src.includes('funnels')) {
  process.stdout.write('  ✓ store/index.js já patchado\n');
  process.exit(0);
}

// Insert import after the last import line (before createStore)
const IMPORT_SENTINEL = "import { createStore } from 'vuex';";
if (!src.includes(IMPORT_SENTINEL)) {
  process.stderr.write('ERROR: vuex import sentinel not found\n');
  process.exit(1);
}
src = src.replace(
  IMPORT_SENTINEL,
  IMPORT_SENTINEL +
  "\nimport funnels from '../routes/dashboard/funnels/store/index';"
);

// Add funnels to modules object — insert before closing `},` of modules
const MODULES_END = '    captainCustomTools,\n  },';
if (!src.includes(MODULES_END)) {
  process.stderr.write('ERROR: modules end sentinel not found\n');
  process.exit(1);
}
src = src.replace(
  MODULES_END,
  '    captainCustomTools,\n    funnels,\n  },'
);

fs.writeFileSync(path, src);
process.stdout.write('  ✓ store/index.js patchado\n');
