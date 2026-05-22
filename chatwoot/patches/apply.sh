#!/bin/bash
# Applies WhatsApp Lite plugin to a Chatwoot source tree
# Usage: CHATWOOT_SRC=/path/to/chatwoot ./apply.sh

set -e

PLUGIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CW_SRC="${CHATWOOT_SRC:-/chatwoot}"

echo "→ Applying WhatsApp Lite to $CW_SRC"

# 1. Copy Vue components
DEST="$CW_SRC/app/javascript/dashboard/routes/dashboard/settings/integrations/WhatsappLite"
mkdir -p "$DEST"
cp -r "$PLUGIN_DIR/app/javascript/dashboard/routes/dashboard/settings/integrations/WhatsappLite/"* "$DEST/"
echo "  ✓ Vue components copied"

# 2. Append integration to apps.yml
APPS_YML="$CW_SRC/config/integration/apps.yml"
if ! grep -q "whatsapp_lite:" "$APPS_YML"; then
  echo "" >> "$APPS_YML"
  cat "$PLUGIN_DIR/config/integration/whatsapp_lite.yml" >> "$APPS_YML"
  echo "  ✓ apps.yml updated"
fi

# 3. Append translations to en.yml and pt_BR.yml
patch_locale() {
  local main_file="$1"
  local patch_file="$2"
  local lang_key="$3"
  if ! grep -q "whatsapp_lite:" "$main_file" 2>/dev/null; then
    python3 - "$main_file" "$patch_file" "$lang_key" <<'PYEOF'
import sys

main_file = sys.argv[1]
patch_file = sys.argv[2]
lang_key = sys.argv[3]

with open(patch_file) as f:
    lines = f.readlines()

patch_content = ""
in_block = False
for line in lines:
    if "integration_apps:" in line:
        in_block = True
        continue
    if in_block:
        patch_content += line

with open(main_file) as f:
    content = f.read()

content = content.replace("\n  openai:", patch_content + "\n  openai:")

with open(main_file, "w") as f:
    f.write(content)
PYEOF
    echo "  ✓ $lang_key updated"
  fi
}

patch_locale "$CW_SRC/config/locales/en.yml"    "$PLUGIN_DIR/config/locales/whatsapp_lite.en.yml"    "en"
patch_locale "$CW_SRC/config/locales/pt_BR.yml" "$PLUGIN_DIR/config/locales/whatsapp_lite.pt_BR.yml" "pt_BR"

# 4. Register route in integrations.routes.js
ROUTES="$CW_SRC/app/javascript/dashboard/routes/dashboard/settings/integrations/integrations.routes.js"
if ! grep -q "whatsapp_lite" "$ROUTES"; then
  python3 - "$ROUTES" <<'PYEOF'
import sys, re

with open(sys.argv[1]) as f:
    content = f.read()

# Add import
content = content.replace(
    "import Shopify from './Shopify.vue';",
    "import Shopify from './Shopify.vue';\nimport WhatsappLite from './WhatsappLite/Index.vue';"
)

# Add route before the catch-all :integration_id route
new_route = """        {
          path: 'whatsapp_lite',
          name: 'settings_integrations_whatsapp_lite',
          component: WhatsappLite,
          meta: {
            featureFlag: FEATURE_FLAGS.INTEGRATIONS,
            permissions: ['administrator'],
          },
        },
"""
content = content.replace(
    "        {\n          path: ':integration_id',",
    new_route + "        {\n          path: ':integration_id',"
)

with open(sys.argv[1], "w") as f:
    f.write(content)
PYEOF
  echo "  ✓ routes registered"
fi

# 5. Copy logo
LOGO_DEST="$CW_SRC/public/dashboard/images/integrations"
mkdir -p "$LOGO_DEST"
if [ -f "$PLUGIN_DIR/../assets/whatsapp_lite.png" ]; then
  cp "$PLUGIN_DIR/../assets/whatsapp_lite.png" "$LOGO_DEST/whatsapp_lite.png"
  cp "$PLUGIN_DIR/../assets/whatsapp_lite.png" "$LOGO_DEST/whatsapp_lite-dark.png"
  echo "  ✓ logo copied"
fi

echo ""
echo "✅ WhatsApp Lite applied successfully!"
echo "   Run 'yarn build' in $CW_SRC to compile assets."
