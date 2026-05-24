#!/bin/bash
set -e

WEBHOOK_URL="https://chat.opp4s.com/api/v1/accounts/1/whatsapp_lite/webhook/cw-1-5511999999999"
TOKEN="test-token-123"

# Garantir que o channel de teste existe
docker exec chatwoot-web bundle exec rails runner '
  unless WhatsappLiteChannel.exists?(instance_id: "cw-1-5511999999999")
    channel_api = Channel::Api.create!(account_id: 1)
    inbox = Inbox.create!(account_id: 1, name: "WhatsApp Lite Test", channel: channel_api)
    WhatsappLiteChannel.create!(account_id: 1, inbox: inbox, instance_id: "cw-1-5511999999999", phone_number: "+5511999999999")
  end
' >/dev/null 2>&1

# 1. Auth inválido → 401
status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$WEBHOOK_URL" \
  -H "X-Evolution-Token: errado" -H "Content-Type: application/json" -d '{"event":"ping"}')
[ "$status" = "401" ] || { echo "  ❌ Auth inválido deveria retornar 401, recebeu $status"; exit 1; }

# 2. instance_id inválido → 401 (nunca 404)
status=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
  "https://chat.opp4s.com/api/v1/accounts/1/whatsapp_lite/webhook/cw-99-invalido" \
  -H "X-Evolution-Token: $TOKEN" -H "Content-Type: application/json" -d '{}')
[ "$status" = "401" ] || { echo "  ❌ instance_id inválido deveria retornar 401, recebeu $status"; exit 1; }

# 3. connection.update: open → status connected
status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$WEBHOOK_URL" \
  -H "X-Evolution-Token: $TOKEN" -H "Content-Type: application/json" \
  -d '{"event":"connection.update","data":{"state":"open"}}')
[ "$status" = "200" ] || { echo "  ❌ connection.update retornou $status"; exit 1; }

channel_status=$(docker exec chatwoot-web bundle exec rails runner \
  'puts WhatsappLiteChannel.find_by(instance_id: "cw-1-5511999999999").status' 2>/dev/null | tail -1)
[ "$channel_status" = "connected" ] || { echo "  ❌ channel.status deveria ser connected, é $channel_status"; exit 1; }

# 4. messages.upsert → conversation + contact criados
marker="smoke-p5-$(date +%s)"
status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$WEBHOOK_URL" \
  -H "X-Evolution-Token: $TOKEN" -H "Content-Type: application/json" \
  -d "{\"event\":\"messages.upsert\",\"data\":{\"messages\":[{\"key\":{\"remoteJid\":\"5511777000001@s.whatsapp.net\",\"fromMe\":false},\"pushName\":\"Smoke P5\",\"message\":{\"conversation\":\"${marker}\"}}]}}")
[ "$status" = "200" ] || { echo "  ❌ messages.upsert retornou $status"; exit 1; }

msg_count=$(docker exec chatwoot-web bundle exec rails runner \
  "puts Message.where(content: '${marker}').count" 2>/dev/null | tail -1)
[ "$msg_count" = "1" ] || { echo "  ❌ Mensagem não encontrada no banco (count=$msg_count)"; exit 1; }

phone=$(docker exec chatwoot-web bundle exec rails runner \
  "m = Message.find_by(content: '${marker}'); puts m&.conversation&.contact&.phone_number" 2>/dev/null | tail -1)
[ "$phone" = "+5511777000001" ] || { echo "  ❌ Contact phone errado: $phone (esperado +5511777000001)"; exit 1; }

# 5. fromMe: true → ignorado
fromme_marker="smoke-p5-fromme-$(date +%s)"
curl -s -o /dev/null -X POST "$WEBHOOK_URL" \
  -H "X-Evolution-Token: $TOKEN" -H "Content-Type: application/json" \
  -d "{\"event\":\"messages.upsert\",\"data\":{\"messages\":[{\"key\":{\"remoteJid\":\"5511000@s.whatsapp.net\",\"fromMe\":true},\"message\":{\"conversation\":\"${fromme_marker}\"}}]}}"
fromme_count=$(docker exec chatwoot-web bundle exec rails runner \
  "puts Message.where(content: '${fromme_marker}').count" 2>/dev/null | tail -1)
[ "$fromme_count" = "0" ] || { echo "  ❌ fromMe:true não deveria criar mensagem (count=$fromme_count)"; exit 1; }

echo "  ✓ Auth 401 · instance_id inválido 401 · connection.update=connected · mensagem criada E.164 · fromMe ignorado"
