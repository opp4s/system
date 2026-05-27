#!/usr/bin/env node
// Patches Sidebar.vue to add Funnels menu item with dynamic per-funnel submenu.
const fs = require('fs');
const path = process.argv[2];
if (!path) { process.stderr.write('Usage: node patch-sidebar.js <file>\n'); process.exit(1); }

let src = fs.readFileSync(path, 'utf8');

if (src.includes('funnels_index')) {
  process.stdout.write('  ✓ Sidebar.vue já patchado\n');
  process.exit(0);
}

// ── 1. Inject funnelGroups computed before menuItems ──────────────────────────
// Uses the `store` and `accountScopedRoute` already in scope in Sidebar.vue setup.
// Does NOT call useStore() again (composables can't be called inside computed callbacks).
const MENU_ITEMS_SENTINEL = 'const menuItems = computed(() => {';
if (!src.includes(MENU_ITEMS_SENTINEL)) {
  process.stderr.write('ERROR: menuItems sentinel not found in Sidebar.vue\n');
  process.exit(1);
}

const FUNNELS_COMPUTED = `// ── Funnels plugin ──────────────────────────────────────────────────────────
const funnelGroups = computed(() => {
  const funnels = store.getters['funnels/allFunnels'] || [];
  if (funnels.length === 0) {
    return [{
      name: 'funnels-all',
      label: 'Todos os funis',
      to: accountScopedRoute('funnels_index'),
      activeOn: ['funnels_index', 'funnels_card_detail'],
    }];
  }
  return funnels.map(f => ({
    name: \`funnels-\${f.id}\`,
    label: f.name,
    to: accountScopedRoute('funnels_index', {}, { funnel: f.id }),
    activeOn: ['funnels_index', 'funnels_card_detail'],
  }));
});

`;

src = src.replace(MENU_ITEMS_SENTINEL, FUNNELS_COMPUTED + MENU_ITEMS_SENTINEL);

// ── 2. Insert Funnels group before Settings group in menuItems ─────────────────
const SETTINGS_SENTINEL = "    {\n      name: 'Settings',\n      label: t('SIDEBAR.SETTINGS'),";
if (!src.includes(SETTINGS_SENTINEL)) {
  process.stderr.write('ERROR: Settings sentinel not found in Sidebar.vue\n');
  process.exit(1);
}

const FUNNELS_GROUP = `    {
      name: 'Funnels',
      label: 'Funis',
      icon: 'i-lucide-kanban',
      children: funnelGroups.value,
    },
`;

src = src.replace(SETTINGS_SENTINEL, FUNNELS_GROUP + SETTINGS_SENTINEL);

// ── 3. Trigger fetchFunnelsIfNeeded on sidebar mount ──────────────────────────
// onMounted is already imported in Sidebar.vue. We append a call after the
// existing onMounted block by finding the `useSidebarKeyboardShortcuts` call
// which is the last setup-level call before computed vars start.
const MOUNT_SENTINEL = 'useSidebarKeyboardShortcuts(toggleShortcutModalFn);';
if (!src.includes(MOUNT_SENTINEL)) {
  process.stderr.write('ERROR: useSidebarKeyboardShortcuts sentinel not found\n');
  process.exit(1);
}

const FUNNELS_INIT = `useSidebarKeyboardShortcuts(toggleShortcutModalFn);

// Funnels plugin: load funnels list for sidebar (no-op if already loaded)
onMounted(() => {
  store.dispatch('funnels/fetchFunnelsIfNeeded');
});`;

src = src.replace(MOUNT_SENTINEL, FUNNELS_INIT);

fs.writeFileSync(path, src);
process.stdout.write('  ✓ Sidebar.vue patchado (funnelGroups + onMounted fetch)\n');
