#!/bin/sh
# Parte 12 — Estados + UX: smoke test
set -e

BASE_URL="${CHATWOOT_URL:-https://chat.opp4s.com}"
ACCOUNT_ID="${ACCOUNT_ID:-1}"

TOKEN=$(docker exec chatwoot-web bundle exec rails runner \
  'u = User.where.not(access_token: nil).first; t = u.access_token; puts t.respond_to?(:token) ? t.token : t' 2>/dev/null | tail -1)

WEBHOOK_TOKEN=$(docker exec chatwoot-web bundle exec rails runner \
  "puts Account.find($ACCOUNT_ID).settings.dig('whatsapp_lite', 'evolution_webhook_token')" 2>/dev/null | tail -1)

BASE="$BASE_URL/api/v1/accounts/$ACCOUNT_ID/whatsapp_lite"
INSTANCE="cw-${ACCOUNT_ID}-smoke-p12"
pass=0; fail=0

check() {
  if [ "$1" = "true" ]; then echo "  ✅ $2"; pass=$((pass+1)); else echo "  ❌ $2"; fail=$((fail+1)); fi
}

# Setup: create test channel
docker exec chatwoot-web bundle exec rails runner "
  unless WhatsappLiteChannel.find_by(instance_id: '$INSTANCE')
    ch_api = Channel::Api.create!(account_id: $ACCOUNT_ID)
    inbox  = Inbox.create!(account_id: $ACCOUNT_ID, name: 'P12 Smoke', channel: ch_api)
    WhatsappLiteChannel.create!(account_id: $ACCOUNT_ID, inbox: inbox, instance_id: '$INSTANCE', phone_number: '+5511000000000', status: :auto_disconnected)
    puts 'created'
  else
    puts 'exists'
  end
" 2>/dev/null | tail -1 > /dev/null

echo "=== Parte 12: Estados + UX ==="

# 1. 5 enum states
STATES=$(docker exec chatwoot-web bundle exec rails runner \
  'puts WhatsappLiteChannel.statuses.keys.sort.join(",")' 2>/dev/null | tail -1)
check "$([ "$STATES" = "auto_disconnected,connected,deleted,qr_pending,user_disconnected" ] && echo true || echo false)" \
  "5 estados no enum: $STATES"

# 2. deleted_at column
HAS_COL=$(docker exec chatwoot-web bundle exec rails runner \
  'puts WhatsappLiteChannel.column_names.include?("deleted_at")' 2>/dev/null | tail -1)
check "$HAS_COL" "deleted_at column existe"

# 3. 8 routes
ROUTE_COUNT=$(docker exec chatwoot-web bundle exec rails routes 2>/dev/null | grep -c whatsapp_lite)
check "$([ "$ROUTE_COUNT" -ge 8 ] && echo true || echo false)" "$ROUTE_COUNT rotas (≥8 esperado)"

# 4. Integration concern loaded
CONCERN=$(docker exec chatwoot-web bundle exec rails runner \
  'puts Integrations::App.ancestors.map(&:to_s).include?("WhatsappLite::IntegrationAppConcern")' 2>/dev/null | tail -1)
check "$CONCERN" "IntegrationAppConcern carregado"

# 5. enabled? returns true (has visible channels)
ENABLED=$(docker exec chatwoot-web bundle exec rails runner \
  "app = Integrations::App.all.find { |a| a.id == 'whatsapp_lite' }; puts app.enabled?(Account.find($ACCOUNT_ID))" 2>/dev/null | tail -1)
check "$ENABLED" "enabled?(account) = true"

# 6. POST /disconnect
HTTP=$(curl -s -o /tmp/p12-disc.json -w "%{http_code}" -X POST "$BASE/disconnect" \
  -H "api_access_token: $TOKEN" -H "Content-Type: application/json" \
  -d "{\"instance_id\": \"$INSTANCE\"}")
STATUS=$(docker exec chatwoot-web bundle exec rails runner \
  "puts WhatsappLiteChannel.find_by(instance_id: '$INSTANCE')&.status" 2>/dev/null | tail -1)
check "$([ "$HTTP" = "200" ] && [ "$STATUS" = "user_disconnected" ] && echo true || echo false)" \
  "POST /disconnect → 200, status=user_disconnected"

# 7. Webhook guard: close event should NOT overwrite user_disconnected
curl -s -X POST "$BASE/webhook/$INSTANCE" \
  -H "X-Evolution-Token: $WEBHOOK_TOKEN" -H "Content-Type: application/json" \
  -d '{"event":"connection.update","data":{"state":"close"}}' > /dev/null
STATUS2=$(docker exec chatwoot-web bundle exec rails runner \
  "puts WhatsappLiteChannel.find_by(instance_id: '$INSTANCE')&.status" 2>/dev/null | tail -1)
check "$([ "$STATUS2" = "user_disconnected" ] && echo true || echo false)" \
  "Webhook guard: user_disconnected não sobrescrito"

# 8. Hard-delete via DELETE /instances (channel + inbox removidos)
HTTP=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE \
  "$BASE/instances?instance_id=$INSTANCE" -H "api_access_token: $TOKEN")
GONE=$(docker exec chatwoot-web bundle exec rails runner \
  "puts WhatsappLiteChannel.find_by(instance_id: '$INSTANCE').nil? ? 'DELETED' : 'EXISTS'" 2>/dev/null | tail -1)
check "$([ "$HTTP" = "200" ] && [ "$GONE" = "DELETED" ] && echo true || echo false)" \
  "DELETE /instances → hard-delete, channel removido"

# 9. Hard-deleted não aparece no GET /instances
FOUND=$(curl -s "$BASE/instances" -H "api_access_token: $TOKEN" | \
  python3 -c "import sys,json; data=json.load(sys.stdin); print(any(d['instance_id']=='$INSTANCE' for d in data))")
check "$([ "$FOUND" = "False" ] && echo true || echo false)" \
  "Hard-deleted excluído do GET /instances"

# Cleanup
docker exec chatwoot-web bundle exec rails runner "
  ch = WhatsappLiteChannel.find_by(instance_id: '$INSTANCE')
  if ch
    ch.inbox&.destroy rescue nil
    ch.destroy rescue nil
  end
" 2>/dev/null > /dev/null

echo ""
echo "=== Resultado: $pass ✅  $fail ❌ ==="
[ "$fail" -eq 0 ] && exit 0 || exit 1
