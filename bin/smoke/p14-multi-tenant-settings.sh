#!/bin/bash
# Parte 14 — Multi-tenant settings smoke test
set -e

PASS=0; FAIL=0
ok()   { echo "✅ $1"; PASS=$((PASS+1)); }
fail() { echo "❌ $1"; FAIL=$((FAIL+1)); }

TOKEN1=$(docker exec chatwoot-web bundle exec rails runner \
  'u = AccountUser.where(account_id: 1, role: "administrator").first&.user; t = u&.access_token; puts t.respond_to?(:token) ? t.token : t.to_s' \
  2>/dev/null | tail -1)

TOKEN2=$(docker exec chatwoot-web bundle exec rails runner \
  'u = AccountUser.where(account_id: 2, role: "administrator").first&.user; t = u&.access_token; puts t.respond_to?(:token) ? t.token : t.to_s' \
  2>/dev/null | tail -1)

BASE1="https://chat.opp4s.com/api/v1/accounts/1/whatsapp_lite"
BASE2="https://chat.opp4s.com/api/v1/accounts/2/whatsapp_lite"

echo "=== BACKEND: Settings API ==="

# Account 1 — already configured
R=$(curl -s "$BASE1/settings" -H "api_access_token: $TOKEN1")
echo "$R" | grep -q '"configured":true' && ok "Account 1 settings → configured:true" || fail "Account 1 settings → expected configured:true, got: $R"
echo "$R" | grep -q 'evolution.opp4s.com' && ok "Account 1 settings → evolution_api_url present" || fail "Account 1 settings → URL missing: $R"

# Account 2 — not configured
R=$(curl -s "$BASE2/settings" -H "api_access_token: $TOKEN2")
echo "$R" | grep -q '"configured":false' && ok "Account 2 settings → configured:false" || fail "Account 2 settings → expected configured:false, got: $R"

# No auth → 401
CODE=$(curl -s -o /dev/null -w "%{http_code}" "$BASE1/settings")
[ "$CODE" = "401" ] && ok "No auth → 401" || fail "No auth → expected 401, got $CODE"

# POST settings with missing fields → 422
R=$(curl -s -w "\nHTTP:%{http_code}" -X POST "$BASE1/settings" \
  -H "api_access_token: $TOKEN1" -H "Content-Type: application/json" \
  -d '{"evolution_api_url":"https://example.com"}')
echo "$R" | grep -q 'HTTP:422' && ok "POST settings missing fields → 422" || fail "POST settings missing fields → expected 422, got: $R"

# POST settings with bad URL → 422
R=$(curl -s -w "\nHTTP:%{http_code}" -X POST "$BASE1/settings" \
  -H "api_access_token: $TOKEN1" -H "Content-Type: application/json" \
  -d '{"evolution_api_url":"https://does-not-exist-xyz.invalid","evolution_api_key":"k","evolution_webhook_token":"t"}')
echo "$R" | grep -q 'HTTP:422' && ok "POST settings unreachable URL → 422" || fail "POST settings unreachable URL → expected 422, got: $R"

echo ""
echo "=== FRONTEND: Bundle integrity ==="

bundle_has() {
  docker exec chatwoot-web sh -c \
    "grep -ql '$1' /app/public/vite/assets/dashboard-*.js 2>/dev/null && echo true || echo false"
}

[ "$(bundle_has 'Configuração inicial')" = "true" ] && ok "SettingsForm component in bundle" || fail "SettingsForm NOT in bundle"
[ "$(bundle_has 'Token de webhook')" = "true" ]    && ok "webhook token field in bundle"   || fail "webhook token field NOT in bundle"
[ "$(bundle_has 'Carregando\.\.\.')" = "true" ]    && ok "loading spinner in bundle"       || fail "loading spinner NOT in bundle"
[ "$(bundle_has 'whatsapp_lite/settings')" = "true" ] && ok "settings route in bundle"    || fail "settings route NOT in bundle"
[ "$(bundle_has 'canDisconnect')" = "true" ]        && ok "ConnectionList statusConfig in bundle" || fail "ConnectionList NOT in bundle"

echo ""
echo "=== BACKEND: Connect with missing credentials (account 2) ==="

R=$(curl -s -w "\nHTTP:%{http_code}" -X POST "https://chat.opp4s.com/api/v1/accounts/2/whatsapp_lite/connect" \
  -H "api_access_token: $TOKEN2" -H "Content-Type: application/json" \
  -d '{"phone_number":"+5511999999999","method":"qr"}' 2>/dev/null || true)
# Account 2 has no Evolution credentials — must return 503 with actionable message
echo "$R" | grep -q 'HTTP:503' && ok "connect without credentials → 503" || fail "connect without credentials → expected 503, got: $(echo "$R" | tail -1)"
echo "$R" | grep -q 'Configure as credenciais' && ok "connect → message guides user to settings" || fail "connect → expected user-friendly message, got: $R"

echo ""
echo "=== RESULT ==="
echo "Passed: $PASS  Failed: $FAIL"
[ "$FAIL" -eq 0 ] && echo "✅ Parte 14 OK" || { echo "❌ Parte 14 FALHOU"; exit 1; }
