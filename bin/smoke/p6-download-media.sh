#!/bin/bash
set -e

WEBHOOK_URL="https://chat.opp4s.com/api/v1/accounts/1/whatsapp_lite/webhook/cw-1-5511999999999"
TOKEN="test-token-123"

# Garantir channel de teste
docker exec chatwoot-web bundle exec rails runner '
  unless WhatsappLiteChannel.exists?(instance_id: "cw-1-5511999999999")
    channel_api = Channel::Api.create!(account_id: 1)
    inbox = Inbox.create!(account_id: 1, name: "WhatsApp Lite Test", channel: channel_api)
    WhatsappLiteChannel.create!(account_id: 1, inbox: inbox, instance_id: "cw-1-5511999999999", phone_number: "+5511999999999")
  end
' >/dev/null 2>&1

# Enviar webhook com imageMessage
marker="smoke-p6-$(date +%s)"
key_id="P6-MEDIA-$(date +%s%N)"
status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$WEBHOOK_URL" \
  -H "X-Evolution-Token: $TOKEN" -H "Content-Type: application/json" \
  -d "{\"event\":\"messages.upsert\",\"data\":{\"messages\":[{\"key\":{\"remoteJid\":\"5511444000001@s.whatsapp.net\",\"fromMe\":false,\"id\":\"${key_id}\"},\"messageType\":\"imageMessage\",\"pushName\":\"Smoke P6\",\"message\":{\"imageMessage\":{\"url\":\"https://picsum.photos/200\",\"caption\":\"${marker}\"}}}]}}")

[ "$status" = "200" ] || { echo "  ❌ Webhook retornou $status"; exit 1; }

# Aguardar DownloadMediaJob processar (~5s)
sleep 10

# Verificar attachment criado
result=$(docker exec chatwoot-web bundle exec rails runner "
  msg = Message.joins(conversation: :contact).where(contacts: {phone_number: '+5511444000001'}).order(created_at: :desc).first
  a = msg&.attachments&.first
  if a && a.file.attached?
    puts a.file_type.to_s + '|true|' + (a.file.blob&.byte_size || 0).to_s
  else
    puts 'NO_ATTACHMENT'
  end
" 2>/dev/null | tail -1)

[ "$result" = "NO_ATTACHMENT" ] && { echo "  ❌ Attachment não foi criado pelo DownloadMediaJob"; exit 1; }

file_type=$(echo "$result" | cut -d'|' -f1)
attached=$(echo "$result" | cut -d'|' -f2)
blob_size=$(echo "$result" | cut -d'|' -f3)

[ "$file_type" = "image" ] || { echo "  ❌ file_type errado: $file_type (esperado image)"; exit 1; }
[ "$attached" = "true" ] || { echo "  ❌ file não attached ao blob"; exit 1; }
[ "${blob_size:-0}" -gt "0" ] 2>/dev/null || { echo "  ❌ blob_size=0 ou vazio (download falhou)"; exit 1; }

echo "  ✓ DownloadMediaJob criou attachment image · attached=true · blob_size=${blob_size}B"
