#!/bin/bash
# Roda todos os smoke tests das partes concluídas, em ordem.
# Para na primeira falha — não acumula débito.
#
# Uso:
#   COMPLETED_PARTS="p2 p3" bash bin/smoke-test.sh
#   COMPLETED_PARTS="p2 p3 p4" bash bin/smoke-test.sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")/smoke" && pwd)"
COMPLETED_PARTS="${COMPLETED_PARTS:-p2 p3}"

echo "=== Smoke test cumulativo ==="
echo "Partes a validar: $COMPLETED_PARTS"
echo ""

FAILED=0
for part in $COMPLETED_PARTS; do
  file=$(ls "$SCRIPT_DIR/${part}-"*.sh 2>/dev/null | head -1)
  if [ -z "$file" ]; then
    echo "⚠  $part — script não encontrado, pulando"
    continue
  fi
  echo "→ $part"
  if bash "$file"; then
    echo "  ✅ $part OK"
  else
    echo "  ❌ $part FALHOU"
    FAILED=1
    break
  fi
  echo ""
done

if [ "$FAILED" -eq 0 ]; then
  echo "✅ Todas as partes anteriores passam"
else
  exit 1
fi
