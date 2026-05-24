#!/usr/bin/env node
// Patches integrations.routes.js to import and spread plugin routes.
// Usage: node patch-routes.js /path/to/integrations.routes.js
const fs = require('fs');
const path = process.argv[2];
if (!path) { process.stderr.write('Usage: node patch-routes.js <file>\n'); process.exit(1); }

let src = fs.readFileSync(path, 'utf8');

if (src.includes('plugin-routes')) {
  process.stdout.write("  ✓ integrations.routes.js já patchado\n");
  process.exit(0);
}

const IMPORT_SENTINEL = "import Shopify from './Shopify.vue';";
if (!src.includes(IMPORT_SENTINEL)) {
  process.stderr.write('ERROR: import sentinel not found in ' + path + '\n');
  process.exit(1);
}
src = src.replace(IMPORT_SENTINEL, IMPORT_SENTINEL + '\n' + "import pluginRoutes from './plugin-routes.js';");

const CATCHALL_BEFORE = "        {\n          path: ':integration_id',";
if (!src.includes(CATCHALL_BEFORE)) {
  process.stderr.write('ERROR: catch-all route not found in ' + path + '\n');
  process.exit(1);
}
src = src.replace(CATCHALL_BEFORE, "        ...pluginRoutes,\n        {\n          path: ':integration_id',");

fs.writeFileSync(path, src);
process.stdout.write("  ✓ integrations.routes.js patchado\n");
