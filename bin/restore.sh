#!/bin/bash
# Restaura snapshot de banco de um snapshot anterior.
# Uso: bin/restore.sh part-4-pre
# ATENÇÃO: restaura apenas as tabelas do plugin (não o banco inteiro).
set -e

PART="${1:?Uso: $0 part-N-pre}"
SNAP_DIR="/opt/apps/chatwoot-whatsapp-lite/snapshots/$PART"

[ -d "$SNAP_DIR" ] || { echo "❌ Snapshot $PART não encontrado em $SNAP_DIR"; exit 1; }
[ -f "$SNAP_DIR/db.sql" ] || { echo "❌ db.sql não encontrado em $SNAP_DIR"; exit 1; }

echo "→ Restaurando snapshot $PART"
echo "  ⚠ Isso vai APAGAR e RECRIAR os registros das tabelas do plugin."
read -r -p "  Confirmar? [s/N] " confirm
[ "$confirm" = "s" ] || { echo "Cancelado."; exit 0; }

# Limpa tabelas do plugin antes de restaurar
docker exec -i postgres psql -U opp4s -d chatwoot <<'SQL'
  TRUNCATE whatsapp_lite_channels CASCADE;
SQL

# Restaura dados
docker cp "$SNAP_DIR/db.sql" postgres:/tmp/restore.sql
docker exec postgres psql -U opp4s -d chatwoot -f /tmp/restore.sql

echo "✅ Snapshot $PART restaurado"
echo "  Git hash do snapshot: $(cat "$SNAP_DIR/git-hash.txt" 2>/dev/null || echo 'desconhecido')"
