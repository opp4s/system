#!/bin/bash
# Parte 16 (espelho) — Evolution → Chatwoot mirror completo
# Premissa: tudo que a Evolution vê deve aparecer no Chatwoot,
# independente de quem originou (agente, cliente, celular físico, n8n).
#
# Cenários cobertos:
# 1. fromMe=true + source_id NOVO    → cria Message como :outgoing (celular/n8n)
# 2. fromMe=true + source_id JÁ EXISTE → idempotente (eco do envio do Chatwoot)
# 3. fromMe=false + source_id NOVO   → cria Message como :incoming (cliente externo)
# 4. Listener guard: Messages com source_id NÃO disparam SendMessageJob
#    (impede o loop de duplicação no WhatsApp)

set -e

PASS=0; FAIL=0
ok()   { echo "  ✓ $1"; PASS=$((PASS+1)); }
fail() { echo "  ✗ $1"; FAIL=$((FAIL+1)); }

WEBHOOK_URL="https://chat.opp4s.com/api/v1/accounts/1/whatsapp_lite/webhook/cw-1-5511999999999"
TOKEN="test-token-123"
ts=$(date +%s)
export TS="$ts"

# Garantir o channel de teste do P5 (idempotente)
docker exec chatwoot-web bundle exec rails runner '
  unless WhatsappLiteChannel.exists?(instance_id: "cw-1-5511999999999")
    channel_api = Channel::Api.create!(account_id: 1)
    inbox = Inbox.create!(account_id: 1, name: "WhatsApp Lite Test", channel: channel_api)
    WhatsappLiteChannel.create!(
      account_id: 1, inbox: inbox,
      instance_id: "cw-1-5511999999999", phone_number: "+5511999999999"
    )
  end
' >/dev/null 2>&1

# ---------------------------------------------------------------------
# 1. fromMe=true + source_id NOVO → :outgoing
# ---------------------------------------------------------------------
sid_out="P16-MIRROR-OUT-${ts}"
status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$WEBHOOK_URL" \
  -H "X-Evolution-Token: $TOKEN" -H "Content-Type: application/json" \
  -d "{\"event\":\"messages.upsert\",\"data\":{\"messages\":[{\"key\":{\"remoteJid\":\"5511700000001@s.whatsapp.net\",\"fromMe\":true,\"id\":\"${sid_out}\"},\"messageType\":\"conversation\",\"message\":{\"conversation\":\"p16-mirror-out-${ts}\"}}]}}")
[ "$status" = "200" ] || fail "fromMe=true novo: HTTP $status (esperado 200)"

sleep 1
type_out=$(docker exec -e SID="$sid_out" chatwoot-web bundle exec rails runner \
  "m = Message.find_by(source_id: ENV['SID']); puts m ? m.message_type.to_s : 'MISSING'" 2>/dev/null | tail -1)
[ "$type_out" = "outgoing" ] \
  && ok "fromMe=true (source_id novo) → :outgoing" \
  || fail "fromMe=true novo deveria criar :outgoing, criou: $type_out"

# ---------------------------------------------------------------------
# 2. fromMe=true + source_id JÁ EXISTE → idempotente
# ---------------------------------------------------------------------
count_before=$(docker exec -e SID="$sid_out" chatwoot-web bundle exec rails runner \
  "puts Message.where(source_id: ENV['SID']).count" 2>/dev/null | tail -1)

status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$WEBHOOK_URL" \
  -H "X-Evolution-Token: $TOKEN" -H "Content-Type: application/json" \
  -d "{\"event\":\"messages.upsert\",\"data\":{\"messages\":[{\"key\":{\"remoteJid\":\"5511700000001@s.whatsapp.net\",\"fromMe\":true,\"id\":\"${sid_out}\"},\"messageType\":\"conversation\",\"message\":{\"conversation\":\"p16-mirror-DUP-${ts}\"}}]}}")
[ "$status" = "200" ] || fail "duplicata: HTTP $status (esperado 200)"

sleep 1
count_after=$(docker exec -e SID="$sid_out" chatwoot-web bundle exec rails runner \
  "puts Message.where(source_id: ENV['SID']).count" 2>/dev/null | tail -1)

[ "$count_before" = "1" ] && [ "$count_after" = "1" ] \
  && ok "source_id duplicado: idempotente (count=1 antes e depois)" \
  || fail "idempotência quebrada (before=$count_before after=$count_after, esperado 1/1)"

# ---------------------------------------------------------------------
# 3. fromMe=false + source_id novo → :incoming
# ---------------------------------------------------------------------
sid_in="P16-MIRROR-IN-${ts}"
status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$WEBHOOK_URL" \
  -H "X-Evolution-Token: $TOKEN" -H "Content-Type: application/json" \
  -d "{\"event\":\"messages.upsert\",\"data\":{\"messages\":[{\"key\":{\"remoteJid\":\"5511700000002@s.whatsapp.net\",\"fromMe\":false,\"id\":\"${sid_in}\"},\"messageType\":\"conversation\",\"message\":{\"conversation\":\"p16-mirror-in-${ts}\"}}]}}")
[ "$status" = "200" ] || fail "fromMe=false: HTTP $status (esperado 200)"

sleep 1
type_in=$(docker exec -e SID="$sid_in" chatwoot-web bundle exec rails runner \
  "m = Message.find_by(source_id: ENV['SID']); puts m ? m.message_type.to_s : 'MISSING'" 2>/dev/null | tail -1)
[ "$type_in" = "incoming" ] \
  && ok "fromMe=false → :incoming" \
  || fail "fromMe=false deveria criar :incoming, criou: $type_in"

# ---------------------------------------------------------------------
# 4. Listener guard: Message com source_id pré-setado NÃO enfileira
#    SendMessageJob quando MESSAGE_CREATED é dispatchado.
# ---------------------------------------------------------------------
sid_guard="P16-MIRROR-GUARD-${ts}"
guard_log=$(mktemp)
docker exec -e SID="$sid_guard" -e TS="$ts" chatwoot-web bundle exec rails runner '
  begin
    channel = WhatsappLiteChannel.find_by(instance_id: "cw-1-5511999999999")
    raise "test channel missing" unless channel
    inbox = channel.inbox

    # Reusa o contato e conversa do teste 1 (criados pelo webhook curl).
    # Se não existir ainda, cria mínimo necessário.
    contact = Contact.find_or_create_by!(account_id: 1, phone_number: "+5511700000001") { |c| c.name = "Mirror Smoke" }
    ci = ContactInbox.find_or_create_by!(contact: contact, inbox: inbox) { |x| x.source_id = SecureRandom.uuid }
    conv = Conversation.where(contact: contact, inbox: inbox).order(created_at: :desc).first
    conv ||= Conversation.create!(account_id: 1, contact: contact, inbox: inbox, contact_inbox: ci, status: :open)

    msg = conv.messages.create!(
      account_id: 1, inbox_id: inbox.id,
      message_type: :outgoing,
      content:   "p16-mirror-guard-#{ENV[%q[TS]]}",
      source_id: ENV[%q[SID]]
    )

    qa = WhatsappLite::SendMessageJob.queue_adapter
    before = qa.respond_to?(:enqueued_jobs) ? qa.enqueued_jobs.size : 0
    Rails.configuration.dispatcher.dispatch(Events::Types::MESSAGE_CREATED, Time.current, message: msg)
    after  = qa.respond_to?(:enqueued_jobs) ? qa.enqueued_jobs.size : 0
    delta = after - before

    msg.destroy

    puts(delta == 0 ? "GUARD_OK" : "GUARD_FAIL:delta=#{delta}")
  rescue => e
    puts "GUARD_ERROR:#{e.class}:#{e.message}"
  end
' >"$guard_log" 2>&1 || true
guard_result=$(grep -E "^GUARD_(OK|FAIL|ERROR)" "$guard_log" | tail -1)
rm -f "$guard_log"

case "$guard_result" in
  GUARD_OK)    ok "Listener guard: source_id presente bloqueia SendMessageJob" ;;
  GUARD_FAIL*) fail "Listener guard quebrado: $guard_result" ;;
  *)           fail "Listener guard inconcluso: $guard_result" ;;
esac

# ---------------------------------------------------------------------
# Cleanup
# ---------------------------------------------------------------------
docker exec -e TS="$ts" chatwoot-web bundle exec rails runner '
  ts = ENV[%q[TS]]
  Message.where("source_id LIKE ?", "P16-MIRROR-%-#{ts}").delete_all rescue nil
  Message.where("content LIKE ?",   "p16-mirror-%-#{ts}").delete_all rescue nil
' >/dev/null 2>&1 || true

echo ""
echo "  Resultado p16-mirror-evolution: passed=$PASS failed=$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
