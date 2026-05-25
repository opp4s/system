#!/bin/sh
# Verifica se o bundle JS compilado contém as mudanças de frontend p10-p13
# Executar APÓS deploy, antes de declarar qualquer parte de frontend completa
set -e

pass=0; fail=0

check() {
  if [ "$1" = "true" ]; then echo "  ✅ $2"; pass=$((pass+1)); else echo "  ❌ $2"; fail=$((fail+1)); fi
}

echo "=== p13: Frontend bundle integrity ==="

# Helper: return true if string found in any dashboard bundle
bundle_has() {
  docker exec chatwoot-web sh -c \
    "grep -ql '$1' /app/public/vite/assets/dashboard-*.js 2>/dev/null && echo true || echo false"
}

# 1. Bundle contém 'canDisconnect' (exclusivo do statusConfig p13)
check "$(bundle_has 'canDisconnect')" "Bundle contém 'canDisconnect' (statusConfig p13 compilado)"

# 2. Bundle contém label PT-BR 'Aguardando conex' (de qr_pending)
check "$(bundle_has 'Aguardando conex')" "Bundle contém 'Aguardando conexão' (label PT-BR de qr_pending)"

# 3. Bundle contém endpoint /whatsapp_lite/disconnect (URL do POST disconnect)
check "$(bundle_has 'whatsapp_lite/disconnect')" \
  "Bundle contém URL '/whatsapp_lite/disconnect' (Index.vue p13 compilado)"

# 4. Bundle contém TAMBÉM /whatsapp_lite/instances (DELETE hard delete)
check "$(bundle_has 'whatsapp_lite/instances')" \
  "Bundle contém URL '/whatsapp_lite/instances' (deleteInstance compilado)"

# 5. Backend: POST /disconnect responde 404 para inexistente
TOKEN=$(docker exec chatwoot-web bundle exec rails runner \
  'u = User.where.not(access_token: nil).first; t = u.access_token; puts t.respond_to?(:token) ? t.token : t' 2>/dev/null | tail -1)
HTTP=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
  "https://chat.opp4s.com/api/v1/accounts/1/whatsapp_lite/disconnect" \
  -H "api_access_token: $TOKEN" -H "Content-Type: application/json" \
  -d '{"instance_id":"nonexistent-integrity-check"}')
check "$([ "$HTTP" = "404" ] && echo true || echo false)" \
  "Backend POST /disconnect → 404 para inexistente (era: $HTTP)"

echo ""
echo "=== Resultado: $pass ✅  $fail ❌ ==="
echo ""
if [ "$fail" -gt 0 ]; then
  echo "  ⚠ Bundle desatualizado — fazer rebuild da imagem Docker antes de declarar frontend OK"
fi
[ "$fail" -eq 0 ] && exit 0 || exit 1
