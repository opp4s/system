#!/bin/sh
# Atualiza expected-hashes.txt com os hashes dos arquivos patchados.
# Uso: sh update-hashes.sh /path/to/chatwoot-src
set -e

NEW_VERSION="${1:?Uso: $0 /path/to/chatwoot-src}"
HASHES_FILE="$(dirname "$0")/expected-hashes.txt"

FILES="
app/javascript/dashboard/routes/dashboard/settings/integrations/integrations.routes.js
"

> "$HASHES_FILE"
for f in $FILES; do
  full="$NEW_VERSION/$f"
  if [ ! -f "$full" ]; then
    echo "ERRO: $full não encontrado" >&2
    exit 1
  fi
  hash=$(sha256sum "$full" | awk '{print $1}')
  printf '%s|%s\n' "$f" "$hash" >> "$HASHES_FILE"
  echo "  hashed: $f"
done
echo "✅ expected-hashes.txt atualizado em $HASHES_FILE"
