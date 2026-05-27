#!/usr/bin/env node
// Patches ConversationAction.vue to inject FunnelConversationSection in the sidebar.
// Fails gracefully if sentinels are not found.
const fs   = require('fs');
const path = require('path');

const cwSrc = process.argv[2];
if (!cwSrc) {
  process.stderr.write('Usage: node patch-conversation-detail.js <chatwoot_src>\n');
  process.exit(1);
}

const TARGET = path.join(
  cwSrc,
  'app/javascript/dashboard/routes/dashboard/conversation/ConversationAction.vue'
);

if (!fs.existsSync(TARGET)) {
  process.stdout.write('  ⚠ ConversationAction.vue não encontrado — patch ignorado\n');
  process.exit(0);
}

let src = fs.readFileSync(TARGET, 'utf8');

if (src.includes('ConversationFunnelSection')) {
  process.stdout.write('  ✓ ConversationAction.vue já patchado\n');
  process.exit(0);
}

// ── 1. Inject import ──────────────────────────────────────────────────────────
const IMPORT_SENTINEL = "import ConversationLabels from './labels/LabelBox.vue';";
if (!src.includes(IMPORT_SENTINEL)) {
  process.stdout.write('  ⚠ Import sentinel não encontrado em ConversationAction.vue — patch ignorado\n');
  process.exit(0);
}
src = src.replace(
  IMPORT_SENTINEL,
  IMPORT_SENTINEL + '\n' +
  "import ConversationFunnelSection from '../funnels/components/ConversationFunnelSection.vue';"
);

// ── 2. Register component ─────────────────────────────────────────────────────
const COMP_SENTINEL = 'ConversationLabels,';
if (!src.includes(COMP_SENTINEL)) {
  process.stdout.write('  ⚠ Component sentinel não encontrado — patch ignorado\n');
  process.exit(0);
}
src = src.replace(
  COMP_SENTINEL,
  COMP_SENTINEL + '\n    ConversationFunnelSection,'
);

// ── 3. Inject template tag ────────────────────────────────────────────────────
// Insert BEFORE <ConversationLabels> so it appears above the labels section
const TPL_SENTINEL = '<ConversationLabels :conversation-id="conversationId" />';
if (!src.includes(TPL_SENTINEL)) {
  process.stdout.write('  ⚠ Template sentinel não encontrado — patch ignorado\n');
  process.exit(0);
}
src = src.replace(
  TPL_SENTINEL,
  '<ConversationFunnelSection :conversation-id="conversationId" />\n    ' + TPL_SENTINEL
);

fs.writeFileSync(TARGET, src);
process.stdout.write('  ✓ ConversationAction.vue patchado com FunnelConversationSection\n');
