#!/bin/bash
# Parte 15 — Hub-and-spoke multi-tenant smoke test
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

echo "=== AccountHelpers via rails runner ==="

docker exec chatwoot-web bundle exec rails runner '
  require Rails.root.join("lib", "whatsapp_lite", "account_helpers")
  a1 = Account.find(1)
  a2 = Account.find(2)
  puts WhatsappLite::AccountHelpers.primary?(a1) ? "primary(1)=true" : "primary(1)=WRONG"
  puts WhatsappLite::AccountHelpers.primary?(a2) ? "primary(2)=WRONG" : "primary(2)=false"
  c = WhatsappLite::AccountHelpers.credentials_for(a2)
  puts c["evolution_api_url"].present? ? "creds_from_primary=ok" : "creds_from_primary=EMPTY"
' 2>/dev/null | tail -3 | while read line; do
  echo "$line" | grep -q "WRONG\|EMPTY" && fail "AccountHelpers: $line" || ok "AccountHelpers: $line"
done

echo ""
echo "=== GET /settings — is_primary_account field ==="

R1=$(curl -s "$BASE1/settings" -H "api_access_token: $TOKEN1")
echo "$R1" | grep -q '"is_primary_account":true' && ok "Account 1 GET settings → is_primary_account:true" || fail "Account 1 GET settings → expected is_primary_account:true, got: $R1"
echo "$R1" | grep -q '"configured":true' && ok "Account 1 GET settings → configured:true" || fail "Account 1 settings → expected configured:true"
echo "$R1" | grep -q 'evolution.opp4s.com' && ok "Account 1 GET settings → URL visible" || fail "Account 1 settings → URL not visible"

R2=$(curl -s "$BASE2/settings" -H "api_access_token: $TOKEN2")
echo "$R2" | grep -q '"is_primary_account":false' && ok "Account 2 GET settings → is_primary_account:false" || fail "Account 2 GET settings → expected is_primary_account:false, got: $R2"
echo "$R2" | grep -q '"configured":true' && ok "Account 2 GET settings → configured:true (inherits from primary)" || fail "Account 2 settings → expected configured:true (inherited), got: $R2"
echo "$R2" | grep -qv 'evolution_api_url.*https' && ok "Account 2 GET settings → URL not exposed" || fail "Account 2 settings → URL should be null for secondary"

echo ""
echo "=== POST /settings blocked for secondary ==="

R=$(curl -s -w "\nHTTP:%{http_code}" -X POST "$BASE2/settings" \
  -H "api_access_token: $TOKEN2" -H "Content-Type: application/json" \
  -d '{"evolution_api_url":"https://evil.example","evolution_api_key":"x","evolution_webhook_token":"y"}')
echo "$R" | grep -q 'HTTP:403' && ok "Account 2 POST settings → 403 forbidden" || fail "Account 2 POST settings → expected 403, got: $(echo "$R" | tail -1)"
echo "$R" | grep -q 'conta principal' && ok "Account 2 POST settings → actionable error message" || fail "Account 2 POST settings → missing friendly message"

echo ""
echo "=== Instance isolation ==="

# Account 1 instances list — must not contain account 2 channels
R=$(curl -s "$BASE1/instances" -H "api_access_token: $TOKEN1")
echo "$R" | python3 -c "
import sys, json
data = json.load(sys.stdin)
bad = [i for i in data if 'cw-2-' in i.get('instance_id','')]
print('CROSS_ACCOUNT' if bad else 'ISOLATED')
" 2>/dev/null | grep -q 'ISOLATED' && ok "Account 1 instances → no account-2 channels visible" || fail "Account 1 instances → LEAK: account-2 channels visible"

# Account 2 instances list — must not contain account 1 channels
R=$(curl -s "$BASE2/instances" -H "api_access_token: $TOKEN2")
echo "$R" | python3 -c "
import sys, json
data = json.load(sys.stdin)
bad = [i for i in data if 'cw-1-' in i.get('instance_id','')]
print('CROSS_ACCOUNT' if bad else 'ISOLATED')
" 2>/dev/null | grep -q 'ISOLATED' && ok "Account 2 instances → no account-1 channels visible" || fail "Account 2 instances → LEAK: account-1 channels visible"

echo ""
echo "=== Frontend bundle integrity ==="

bundle_has() {
  docker exec chatwoot-web sh -c \
    "grep -ql '$1' /app/public/vite/assets/dashboard-*.js 2>/dev/null && echo true || echo false"
}

[ "$(bundle_has 'is_primary_account')" = "true" ]                   && ok "bundle: is_primary_account check" || fail "bundle: is_primary_account NOT found"
[ "$(bundle_has 'conta principal)')" = "true" ]                     && ok "bundle: primary-only label in form"  || fail "bundle: primary-only label NOT found"
[ "$(bundle_has 'administrador da plataforma')" = "true" ]          && ok "bundle: secondary waiting message" || fail "bundle: secondary message NOT found"
[ "$(bundle_has 'showCancel')" = "true" ]                            && ok "bundle: cancel button in form"    || fail "bundle: cancel button NOT found"

echo ""
echo "=== Boot log ==="
docker logs chatwoot-web 2>&1 | grep -q "Primary account ID: 1" && ok "boot log: Primary account ID: 1" || fail "boot log: Primary account ID not logged"

echo ""
echo "=== RESULT ==="
echo "Passed: $PASS  Failed: $FAIL"
[ "$FAIL" -eq 0 ] && echo "✅ Parte 15 OK" || { echo "❌ Parte 15 FALHOU"; exit 1; }
