#!/bin/sh
# apply.sh — aplica WhatsApp Lite ao source do Chatwoot (build-time)
# Uso: CHATWOOT_SRC=/tmp/build sh /plugin/patches/apply.sh
set -e

PLUGIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CW_SRC="${CHATWOOT_SRC:-/tmp/build}"

echo "→ Aplicando WhatsApp Lite em $CW_SRC"

# 1. Vue components
DEST="$CW_SRC/app/javascript/dashboard/routes/dashboard/settings/integrations"
mkdir -p "$DEST/WhatsappLite"
cp -r "$PLUGIN_DIR/app/javascript/dashboard/routes/dashboard/settings/integrations/WhatsappLite/"* \
  "$DEST/WhatsappLite/"
cp "$PLUGIN_DIR/app/javascript/dashboard/routes/dashboard/settings/integrations/plugin-routes.js" \
  "$DEST/plugin-routes.js"
echo "  ✓ Vue components copiados"

# 2. Patch integrations.routes.js — import + spread (Node.js for multiline match)
ROUTES_FILE="$DEST/integrations.routes.js"

node "$PLUGIN_DIR/patches/patch-routes.js" "$ROUTES_FILE"

# 3. whatsapp_lite.yml (sem action:)
cp "$PLUGIN_DIR/config/integration/whatsapp_lite.yml" \
   "$CW_SRC/config/integration/whatsapp_lite.yml"
echo "  ✓ whatsapp_lite.yml copiado"

# 4. Logo
LOGO_DEST="$CW_SRC/public/dashboard/images/integrations"
mkdir -p "$LOGO_DEST"
if [ -f "/assets/whatsapp_lite.png" ]; then
  cp "/assets/whatsapp_lite.png" "$LOGO_DEST/whatsapp_lite.png"
  cp "/assets/whatsapp_lite.png" "$LOGO_DEST/whatsapp_lite-dark.png"
  echo "  ✓ logo copiado"
else
  echo "  ⚠ logo não encontrado em /assets/whatsapp_lite.png"
fi

echo "✅ WhatsApp Lite aplicado em $CW_SRC"
