#!/bin/sh
# Verifica se os arquivos patchados mudaram na nova versão do Chatwoot.
# Uso: sh check-upgrade-compat.sh /path/to/new-chatwoot-src
set -e

NEW_VERSION="${1:?Uso: $0 /path/to/new-chatwoot-src}"
HASHES_FILE="$(dirname "$0")/expected-hashes.txt"

if [ ! -f "$HASHES_FILE" ]; then
  echo "❌ expected-hashes.txt não encontrado — rodar update-hashes.sh primeiro" >&2
  exit 1
fi

ok=true
while IFS='|' read -r file expected_hash; do
  actual=$(sha256sum "$NEW_VERSION/$file" 2>/dev/null | awk '{print $1}')
  if [ "$actual" = "$expected_hash" ]; then
    echo "✅ $file"
  else
    echo "❌ $file MUDOU (esperado: ${expected_hash:0:12}... atual: ${actual:0:12}...)"
    echo "   → Verificar: chatwoot/patches/apply.sh"
    ok=false
  fi
done < "$HASHES_FILE"

if $ok; then
  echo "✅ Compatível — pode buildar"
else
  echo "❌ Ajustar apply.sh antes de buildar"
  exit 1
fi
