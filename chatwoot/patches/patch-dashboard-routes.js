#!/usr/bin/env node
// Patches dashboard.routes.js to include funnels routes.
const fs = require('fs');
const path = process.argv[2];
if (!path) { process.stderr.write('Usage: node patch-dashboard-routes.js <file>\n'); process.exit(1); }

let src = fs.readFileSync(path, 'utf8');

if (src.includes('funnels.routes')) {
  process.stdout.write('  ✓ dashboard.routes.js já patchado\n');
  process.exit(0);
}

const IMPORT_SENTINEL = "import AppContainer from './Dashboard.vue';";
if (!src.includes(IMPORT_SENTINEL)) {
  process.stderr.write('ERROR: import sentinel not found in ' + path + '\n');
  process.exit(1);
}
src = src.replace(
  IMPORT_SENTINEL,
  IMPORT_SENTINEL + '\n' + "import funnelsRoutes from './funnels/funnels.routes';"
);

const CHILDREN_SENTINEL = '...campaignsRoutes.routes,';
if (!src.includes(CHILDREN_SENTINEL)) {
  process.stderr.write('ERROR: children sentinel not found in ' + path + '\n');
  process.exit(1);
}
src = src.replace(
  CHILDREN_SENTINEL,
  CHILDREN_SENTINEL + '\n        ...funnelsRoutes.routes,'
);

fs.writeFileSync(path, src);
process.stdout.write('  ✓ dashboard.routes.js patchado\n');
