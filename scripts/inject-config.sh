#!/bin/bash
# Injects WhatsApp Lite runtime config into a running Chatwoot container
# Run this after starting your Chatwoot container
# Usage: CONTAINER=chatwoot-web WA_API_BASE=https://... ./inject-config.sh

set -e

CONTAINER="${CONTAINER:-chatwoot-web}"
WA_API_BASE="${WA_API_BASE:?WA_API_BASE is required}"

SNIPPET="window.whatsappLiteConfig={apiBase:'${WA_API_BASE}'};"
CONFIG_FILE="/app/public/dashboard/custom-scripts.js"

docker exec "$CONTAINER" sh -c "
  if [ -f '$CONFIG_FILE' ] && grep -q 'whatsappLiteConfig' '$CONFIG_FILE'; then
    sed -i \"s|window.whatsappLiteConfig=.*|${SNIPPET}|\" '$CONFIG_FILE'
  else
    echo '${SNIPPET}' >> '$CONFIG_FILE'
  fi
  echo 'WhatsApp Lite config injected'
"
