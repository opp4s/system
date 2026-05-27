#!/bin/sh
# apply.sh — aplica Funnels Plugin ao source do Chatwoot (build-time)
# Uso: CHATWOOT_SRC=/app sh /plugin/patches/apply.sh
set -e

PLUGIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CW_SRC="${CHATWOOT_SRC:-/app}"

echo "→ Aplicando Funnels Plugin em $CW_SRC"

# 1. Vue components
FUNNELS_DEST="$CW_SRC/app/javascript/dashboard/routes/dashboard/funnels"
mkdir -p "$FUNNELS_DEST/components" "$FUNNELS_DEST/store"
cp -r "$PLUGIN_DIR/app/javascript/dashboard/routes/dashboard/funnels/"* "$FUNNELS_DEST/"
echo "  ✓ Vue components copiados"

# 2. Patch dashboard.routes.js
ROUTES_FILE="$CW_SRC/app/javascript/dashboard/routes/dashboard/dashboard.routes.js"
node "$PLUGIN_DIR/patches/patch-dashboard-routes.js" "$ROUTES_FILE"

# 3. Patch Sidebar.vue
SIDEBAR_FILE="$CW_SRC/app/javascript/dashboard/components-next/sidebar/Sidebar.vue"
node "$PLUGIN_DIR/patches/patch-sidebar.js" "$SIDEBAR_FILE"

# 4. Patch Vuex store (encontra o index principal)
STORE_FILE="$CW_SRC/app/javascript/dashboard/store/index.js"
if [ -f "$STORE_FILE" ]; then
  node "$PLUGIN_DIR/patches/patch-store.js" "$STORE_FILE"
else
  echo "  ⚠ store/index.js não encontrado em $STORE_FILE — pulando"
fi

# 5. Patch i18n locale files
node "$PLUGIN_DIR/patches/patch-i18n.js" "$CW_SRC" "$PLUGIN_DIR"

echo "✅ Funnels Plugin aplicado em $CW_SRC"
