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
key_id="P5-MARKER-$(date +%s%N)"
status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$WEBHOOK_URL" \
  -H "X-Evolution-Token: $TOKEN" -H "Content-Type: application/json" \
  -d "{\"event\":\"messages.upsert\",\"data\":{\"messages\":[{\"key\":{\"remoteJid\":\"5511777000001@s.whatsapp.net\",\"fromMe\":false,\"id\":\"${key_id}\"},\"messageType\":\"conversation\",\"pushName\":\"Smoke P5\",\"message\":{\"conversation\":\"${marker}\"}}]}}")
[ "$status" = "200" ] || { echo "  ❌ messages.upsert retornou $status"; exit 1; }

msg_count=$(docker exec chatwoot-web bundle exec rails runner \
  "puts Message.where(content: '${marker}').count" 2>/dev/null | tail -1)
[ "$msg_count" = "1" ] || { echo "  ❌ Mensagem não encontrada no banco (count=$msg_count)"; exit 1; }

phone=$(docker exec chatwoot-web bundle exec rails runner \
  "m = Message.find_by(content: '${marker}'); puts m&.conversation&.contact&.phone_number" 2>/dev/null | tail -1)
[ "$phone" = "+5511777000001" ] || { echo "  ❌ Contact phone errado: $phone (esperado +5511777000001)"; exit 1; }

# 5. fromMe: true + key.id NOVO → cria Message como :outgoing
#    (premissa "espelho completo Evolution"; antes era ignorado por filtro fromMe)
fromme_marker="smoke-p5-fromme-$(date +%s)"
fromme_key="P5-FROMME-$(date +%s%N)"
curl -s -o /dev/null -X POST "$WEBHOOK_URL" \
  -H "X-Evolution-Token: $TOKEN" -H "Content-Type: application/json" \
  -d "{\"event\":\"messages.upsert\",\"data\":{\"messages\":[{\"key\":{\"remoteJid\":\"5511000@s.whatsapp.net\",\"fromMe\":true,\"id\":\"${fromme_key}\"},\"messageType\":\"conversation\",\"message\":{\"conversation\":\"${fromme_marker}\"}}]}}"
fromme_type=$(docker exec chatwoot-web bundle exec rails runner \
  "m = Message.find_by(source_id: '${fromme_key}'); puts m ? m.message_type.to_s : 'MISSING'" 2>/dev/null | tail -1)
[ "$fromme_type" = "outgoing" ] || { echo "  ❌ fromMe:true (key.id novo) deveria criar :outgoing, foi: $fromme_type"; exit 1; }

# Cleanup das mensagens criadas pelo smoke
docker exec chatwoot-web bundle exec rails runner "
  Message.where(\"content LIKE 'smoke-p5-%'\").delete_all rescue nil
" >/dev/null 2>&1 || true

echo "  ✓ Auth 401 · instance_id inválido 401 · connection.update=connected · mensagem incoming E.164 · fromMe → :outgoing"
