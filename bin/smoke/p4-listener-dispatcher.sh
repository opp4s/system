#!/bin/bash
set -e

# NÍVEL 1 — Listener registrado no boot (verificar nos últimos 500 logs)
docker logs chatwoot-web --tail=500 2>&1 | grep -q "MessageListener subscribed to sync_dispatcher" || {
  echo "  ❌ Listener NÃO foi subscrito no boot do web"
  echo "     Verificar: docker logs chatwoot-web | grep whatsapp_lite"
  exit 1
}

# NÍVEL 3 — Caminho real: Message.create! → after_create_commit → listener → Sidekiq
runner_output=$(docker exec chatwoot-web bundle exec rails runner '
  require "securerandom"

  channel = WhatsappLiteChannel.where(account_id: 1).first
  unless channel
    channel_api = Channel::Api.create!(account_id: 1)
    inbox = Inbox.create!(account_id: 1, name: "WA Lite Smoke P4", channel: channel_api)
    channel = WhatsappLiteChannel.create!(
      account_id: 1, inbox: inbox,
      instance_id: "cw-1-smoke-p4",
      phone_number: "+5511900000001"
    )
  end

  contact = Contact.find_or_create_by!(account_id: 1, email: "smoke-p4@test.com") do |c|
    c.name = "Smoke P4"
  end
  ci = ContactInbox.find_or_create_by!(contact: contact, inbox: channel.inbox) do |c|
    c.source_id = SecureRandom.uuid
  end
  conv = Conversation.find_or_create_by!(
    account_id: 1, contact: contact,
    inbox: channel.inbox, contact_inbox: ci
  ) { |c| c.status = :open }

  msg = conv.messages.create!(
    account_id: 1, inbox_id: channel.inbox.id,
    message_type: :outgoing, content: "smoke-p4-test-#{Time.now.to_i}"
  )
  STDERR.puts "SMOKE_MSG_ID=#{msg.id}"
' 2>&1)

msg_id=$(echo "$runner_output" | grep "SMOKE_MSG_ID=" | grep -o "[0-9]*$" | head -1)
[ -n "$msg_id" ] || { echo "  ❌ Falha ao criar mensagem de teste (output: $runner_output)"; exit 1; }

# Verifica que o listener logou o evento (o runner_output captura logs do processo rails)
echo "$runner_output" | grep -q "received MESSAGE_CREATED message_id=${msg_id}" || {
  echo "  ❌ Listener NÃO recebeu MESSAGE_CREATED para message_id=${msg_id}"
  echo "     Output do runner:"
  echo "$runner_output" | grep -i "whatsapp_lite\|MESSAGE_CREATED" | head -5
  exit 1
}

# Aguarda Sidekiq processar (~500ms normalmente)
sleep 2

# Verifica execução do job no sidekiq (últimos 200 logs)
docker logs chatwoot-sidekiq --tail=200 2>&1 | grep -q "WhatsappLite::SendMessageJob.*arguments: ${msg_id}" || {
  echo "  ❌ SendMessageJob NÃO foi executado pelo Sidekiq para message_id=${msg_id}"
  echo "     Verificar: docker logs chatwoot-sidekiq | grep WhatsappLite"
  exit 1
}

echo "  ✓ Listener subscrito no boot · MESSAGE_CREATED recebido · Sidekiq executou SendMessageJob"
