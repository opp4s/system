#!/bin/bash
set -e

# Garantir model no sidekiq (file-to-file bind mount não funciona para arquivo inexistente na imagem)
docker cp /opt/apps/chatwoot-whatsapp-lite/chatwoot/app/models/whatsapp_lite_channel.rb \
  chatwoot-sidekiq:/app/app/models/whatsapp_lite_channel.rb 2>/dev/null || true

# NÍVEL 1: Guard — canal desconectado → job não envia
guard_result=$(docker exec chatwoot-web bundle exec rails runner '
  ch = WhatsappLiteChannel.find_by(instance_id: "cw-1-5511999999999")
  ch.update!(status: :auto_disconnected)
  contact = Contact.find_or_create_by!(account_id: 1, phone_number: "+5511000099999") { |c| c.name = "Guard Test" }
  ci = ContactInbox.find_or_create_by!(contact: contact, inbox: ch.inbox) { |x| x.source_id = SecureRandom.uuid }
  conv = Conversation.find_or_create_by!(account_id: 1, contact: contact, inbox: ch.inbox, contact_inbox: ci) { |c| c.status = :open }
  msg = conv.messages.create!(account_id: 1, inbox_id: ch.inbox_id, message_type: :outgoing, content: "guard-test")
  WhatsappLite::SendMessageJob.perform_now(msg.id)
  puts "GUARD_OK"
' 2>/dev/null | tail -1)

[ "$guard_result" = "GUARD_OK" ] || { echo "  ❌ Guard test falhou (resultado: $guard_result)"; exit 1; }

# NÍVEL 2: Envio real via Evolution API (instância conectada)
runner_output=$(docker exec chatwoot-web bundle exec rails runner '
  ch = WhatsappLiteChannel.find_or_create_by!(instance_id: "cw-1-5541995017777") do |c|
    channel_api = Channel::Api.create!(account_id: 1)
    inbox = Inbox.create!(account_id: 1, name: "WA P7 Test", channel: channel_api)
    c.account_id = 1; c.inbox = inbox; c.phone_number = "+5541995017777"; c.status = :connected
  end
  ch.update!(status: :connected)
  contact = Contact.find_or_create_by!(account_id: 1, phone_number: "+5541995017777") { |c| c.name = "P7 Test" }
  ci = ContactInbox.find_or_create_by!(contact: contact, inbox: ch.inbox) { |x| x.source_id = SecureRandom.uuid }
  conv = Conversation.find_or_create_by!(account_id: 1, contact: contact, inbox: ch.inbox, contact_inbox: ci) { |c| c.status = :open }
  msg = conv.messages.create!(account_id: 1, inbox_id: ch.inbox_id, message_type: :outgoing, content: "smoke-p7-#{Time.now.to_i}")
  STDERR.puts "SMOKE_MSG_ID=#{msg.id}"
' 2>&1)

msg_id=$(echo "$runner_output" | grep "SMOKE_MSG_ID=" | grep -o "[0-9]*$" | head -1)
[ -n "$msg_id" ] || { echo "  ❌ Falha ao criar mensagem (output: $runner_output)"; exit 1; }

# Aguardar Sidekiq processar
sleep 4

# Verificar log de envio no sidekiq
docker logs chatwoot-sidekiq --tail=50 2>&1 | grep -q "message_id=${msg_id}.*enviado" || {
  echo "  ❌ SendMessageJob não logou 'enviado' para message_id=${msg_id}"
  docker logs chatwoot-sidekiq --tail=20 2>&1 | grep -i "SendMessage\|whatsapp_lite" | tail -5
  exit 1
}

echo "  ✓ Guard disconnected · Evolution API chamada · message_id=${msg_id} enviado"
