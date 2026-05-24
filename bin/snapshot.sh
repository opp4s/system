#!/bin/bash
# Salva snapshot do estado de ambiente antes de iniciar uma parte.
# Uso: bin/snapshot.sh part-4-pre
set -e

PART="${1:?Uso: $0 part-N-pre}"
SNAP_DIR="/opt/apps/chatwoot-whatsapp-lite/snapshots/$PART"
mkdir -p "$SNAP_DIR"

echo "→ Snapshot $PART"

# Dump das tabelas relevantes do plugin
docker exec postgres pg_dump -U opp4s -d chatwoot \
  --data-only \
  --table=whatsapp_lite_channels \
  --table=inboxes \
  --table=channels_api \
  --table=conversations \
  --table=contacts \
  --table=contact_inboxes \
  2>/dev/null > "$SNAP_DIR/db.sql" || echo "  ⚠ dump parcial (tabela pode não existir ainda)"

# account_settings da conta 1
docker exec chatwoot-web bundle exec rails runner \
  'puts Account.find(1).settings.to_json' \
  2>/dev/null | tail -1 > "$SNAP_DIR/account_1_settings.json" || true

# Estado dos containers
docker compose \
  -f /opt/apps/chatwoot/docker-compose.yml \
  -f /opt/apps/chatwoot/docker-compose.override.yml \
  ps > "$SNAP_DIR/containers.txt" 2>/dev/null || true

# Git hash atual
git -C /opt/apps/chatwoot-whatsapp-lite rev-parse HEAD > "$SNAP_DIR/git-hash.txt" 2>/dev/null || true

echo "✅ Snapshot salvo em $SNAP_DIR"
echo ""
ls "$SNAP_DIR"
