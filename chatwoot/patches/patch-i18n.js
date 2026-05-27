#!/usr/bin/env node
// Patches Chatwoot i18n locale files to include Funnels plugin strings.
// Runs at Docker build time. Tolerates missing files gracefully.
const fs   = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const cwSrc     = process.argv[2];
const pluginDir = process.argv[3];
if (!cwSrc || !pluginDir) {
  process.stderr.write('Usage: node patch-i18n.js <CW_SRC> <PLUGIN_DIR>\n');
  process.exit(1);
}

const LOCALE_MAP = {
  'pt_BR': path.join(pluginDir, 'app/javascript/dashboard/routes/dashboard/funnels/i18n/pt_BR.json'),
  'en':    path.join(pluginDir, 'app/javascript/dashboard/routes/dashboard/funnels/i18n/en.json'),
};

// Known paths in order of likelihood across Chatwoot versions
const CANDIDATES = [
  'app/javascript/shared/i18n/locale/{lang}.json',
  'app/javascript/dashboard/i18n/locale/{lang}.json',
  'app/javascript/i18n/locale/{lang}.json',
];

function findLocaleFile(lang) {
  for (const tpl of CANDIDATES) {
    const full = path.join(cwSrc, tpl.replace('{lang}', lang));
    if (fs.existsSync(full)) return full;
  }
  // Fallback: search the tree
  try {
    const result = execSync(
      `find "${cwSrc}/app/javascript" -name "${lang}.json" 2>/dev/null`
    ).toString().trim();
    const lines = result.split('\n').filter(Boolean);
    // Prefer the largest file (most likely to be the full locale)
    if (lines.length) {
      return lines.sort((a, b) => fs.statSync(b).size - fs.statSync(a).size)[0];
    }
  } catch {}
  return null;
}

let patched = 0;

for (const [lang, msgFile] of Object.entries(LOCALE_MAP)) {
  if (!fs.existsSync(msgFile)) {
    process.stdout.write(`  ⚠ Funnels i18n source not found: ${msgFile}\n`);
    continue;
  }

  const target = findLocaleFile(lang);
  if (!target) {
    process.stdout.write(`  ⚠ Chatwoot locale file not found for "${lang}" — skipping\n`);
    continue;
  }

  if (fs.readFileSync(target, 'utf8').includes('"funnels"')) {
    process.stdout.write(`  ✓ ${lang}.json já patchado\n`);
    patched++;
    continue;
  }

  const funnelsMessages = JSON.parse(fs.readFileSync(msgFile, 'utf8'));
  const existing        = JSON.parse(fs.readFileSync(target,  'utf8'));
  existing.funnels      = funnelsMessages;
  fs.writeFileSync(target, JSON.stringify(existing, null, 2));
  process.stdout.write(`  ✓ ${lang}.json patchado em ${target}\n`);
  patched++;
}

if (patched === 0) {
  process.stdout.write('  ⚠ Nenhum arquivo de locale foi patchado\n');
}
