#!/bin/sh
# Parte 13 — Final UX fixes: smoke test
set -e

BASE_URL="${CHATWOOT_URL:-https://chat.opp4s.com}"
ACCOUNT_ID="${ACCOUNT_ID:-1}"

TOKEN=$(docker exec chatwoot-web bundle exec rails runner \
  'u = User.where.not(access_token: nil).first; t = u.access_token; puts t.respond_to?(:token) ? t.token : t' 2>/dev/null | tail -1)

WEBHOOK_TOKEN=$(docker exec chatwoot-web bundle exec rails runner \
  "puts Account.find($ACCOUNT_ID).settings.dig('whatsapp_lite', 'evolution_webhook_token')" 2>/dev/null | tail -1)

BASE="$BASE_URL/api/v1/accounts/$ACCOUNT_ID/whatsapp_lite"
pass=0; fail=0

check() {
  if [ "$1" = "true" ]; then echo "  ✅ $2"; pass=$((pass+1)); else echo "  ❌ $2"; fail=$((fail+1)); fi
}

echo "=== Parte 13: Correções finais UX + Inbox ==="

# 1. Disconnect endpoint returns 404 for non-existent instance
HTTP=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE/disconnect" \
  -H "api_access_token: $TOKEN" -H "Content-Type: application/json" \
  -d '{"instance_id":"non-existent-p13"}')
check "$([ "$HTTP" = "404" ] && echo true || echo false)" \
  "POST /disconnect → 404 para instância inexistente (era: $HTTP)"

# 2. DELETE /instances removes channel + inbox (hard delete always)
docker exec chatwoot-web bundle exec rails runner "
  unless WhatsappLiteChannel.find_by(instance_id: 'smoke-p13-delete')
    ch_api = Channel::Api.create!(account_id: $ACCOUNT_ID)
    inbox  = Inbox.create!(account_id: $ACCOUNT_ID, name: 'Smoke P13 Delete', channel: ch_api)
    WhatsappLiteChannel.create!(account_id: $ACCOUNT_ID, inbox: inbox, instance_id: 'smoke-p13-delete', phone_number: '+5511900000013')
  end
" 2>/dev/null > /dev/null

HTTP=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE \
  "$BASE/instances?instance_id=smoke-p13-delete" -H "api_access_token: $TOKEN")

CHANNEL_GONE=$(docker exec chatwoot-web bundle exec rails runner \
  'puts WhatsappLiteChannel.exists?(instance_id: "smoke-p13-delete") ? "false" : "true"' 2>/dev/null | tail -1)
INBOX_GONE=$(docker exec chatwoot-web bundle exec rails runner \
  'puts Inbox.exists?(name: "Smoke P13 Delete") ? "false" : "true"' 2>/dev/null | tail -1)

check "$([ "$HTTP" = "200" ] && echo true || echo false)" \
  "DELETE /instances → HTTP 200"
check "$CHANNEL_GONE" \
  "DELETE /instances → channel destruído"
check "$INBOX_GONE" \
  "DELETE /instances → inbox destruída (hard delete padrão)"

# 3. No orphaned channels with status :deleted in DB
DELETED_COUNT=$(docker exec chatwoot-web bundle exec rails runner \
  'puts WhatsappLiteChannel.where(status: :deleted).count' 2>/dev/null | tail -1)
check "$([ "$DELETED_COUNT" = "0" ] && echo true || echo false)" \
  "$DELETED_COUNT channels em status :deleted (esperado: 0)"

# 4. Webhook guard still works (user_disconnected not overwritten)
docker exec chatwoot-web bundle exec rails runner "
  unless WhatsappLiteChannel.find_by(instance_id: 'smoke-p13-guard')
    ch_api = Channel::Api.create!(account_id: $ACCOUNT_ID)
    inbox  = Inbox.create!(account_id: $ACCOUNT_ID, name: 'Smoke P13 Guard', channel: ch_api)
    WhatsappLiteChannel.create!(account_id: $ACCOUNT_ID, inbox: inbox, instance_id: 'smoke-p13-guard', phone_number: '+5511900000099', status: :user_disconnected)
  else
    WhatsappLiteChannel.find_by(instance_id: 'smoke-p13-guard')&.update!(status: :user_disconnected)
  end
" 2>/dev/null > /dev/null

curl -s -X POST "$BASE/webhook/smoke-p13-guard" \
  -H "X-Evolution-Token: $WEBHOOK_TOKEN" -H "Content-Type: application/json" \
  -d '{"event":"connection.update","data":{"state":"close"}}' > /dev/null

STATUS=$(docker exec chatwoot-web bundle exec rails runner \
  'puts WhatsappLiteChannel.find_by(instance_id: "smoke-p13-guard")&.status' 2>/dev/null | tail -1)
check "$([ "$STATUS" = "user_disconnected" ] && echo true || echo false)" \
  "Webhook guard: user_disconnected não sobrescrito por Evolution close"

# 5. GET /instances excludes deleted-status channels (backward compat)
docker exec chatwoot-web bundle exec rails runner "
  ch = WhatsappLiteChannel.find_by(instance_id: 'smoke-p13-guard')
  if ch
    # Manually set to deleted status to test visible scope
    ch.update_columns(status: 4)
  end
" 2>/dev/null > /dev/null

FOUND=$(curl -s "$BASE/instances" -H "api_access_token: $TOKEN" | \
  python3 -c "import sys,json; data=json.load(sys.stdin); print(any(d['instance_id']=='smoke-p13-guard' for d in data))")
check "$([ "$FOUND" = "False" ] && echo true || echo false)" \
  "GET /instances exclui channels com status=deleted"

# Cleanup
docker exec chatwoot-web bundle exec rails runner "
  ['smoke-p13-guard'].each do |iid|
    ch = WhatsappLiteChannel.find_by(instance_id: iid)
    if ch
      ch.inbox&.destroy rescue nil
      ch.destroy rescue nil
    end
  end
" 2>/dev/null > /dev/null

echo ""
echo "=== Resultado: $pass ✅  $fail ❌ ==="
[ "$fail" -eq 0 ] && exit 0 || exit 1
