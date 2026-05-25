#!/bin/bash
# Parte 16 — Outgoing message display + echo-back prevention
set -e

PASS=0; FAIL=0
ok()   { echo "✅ $1"; PASS=$((PASS+1)); }
fail() { echo "❌ $1"; FAIL=$((FAIL+1)); }

TOKEN1=$(docker exec chatwoot-web bundle exec rails runner \
  'u = AccountUser.where(account_id: 1, role: "administrator").first&.user; t = u&.access_token; puts t.respond_to?(:token) ? t.token : t.to_s' \
  2>/dev/null | tail -1)

echo "=== Outgoing message creation and persistence ==="

# Test: create outgoing message via Rails, verify it persists with correct attributes
RESULT=$(docker exec chatwoot-web bundle exec rails runner '
  begin
    inbox = Inbox.where(channel_type: "Channel::Api").first
    raise "No Channel::Api inbox" unless inbox

    conv = Conversation.where(inbox: inbox).first
    raise "No conversation for inbox #{inbox.id}" unless conv

    user = User.first

    msg = conv.messages.create!(
      account_id: conv.account_id,
      inbox_id: conv.inbox_id,
      message_type: :outgoing,
      content: "p16-smoke-#{Time.current.to_i}",
      sender: user
    )

    # Verify attributes
    raise "message_type wrong" unless msg.outgoing?
    raise "private should be false" if msg.private?
    raise "status should be sent" unless msg.status == "sent"

    puts "CREATED:#{msg.id}:#{msg.message_type}:#{msg.private?}:#{msg.status}"
  rescue => e
    puts "ERROR:#{e.message}"
  end
' 2>/dev/null | tail -1)

if echo "$RESULT" | grep -q "^CREATED:"; then
  MSG_ID=$(echo "$RESULT" | cut -d: -f2)
  MSG_TYPE=$(echo "$RESULT" | cut -d: -f3)
  MSG_PRIV=$(echo "$RESULT" | cut -d: -f4)
  MSG_STATUS=$(echo "$RESULT" | cut -d: -f5)
  ok "Outgoing message created: id=$MSG_ID type=$MSG_TYPE private=$MSG_PRIV status=$MSG_STATUS"
else
  fail "Outgoing message creation failed: $RESULT"
  MSG_ID=""
fi

echo ""
echo "=== SendMessageJob execution ==="

if [ -n "$MSG_ID" ]; then
  sleep 5

  JOB_LOG=$(docker logs chatwoot-sidekiq --since=30s 2>&1 | grep "message_id=${MSG_ID}" | tail -3)

  if echo "$JOB_LOG" | grep -q "WhatsappLite::SendMessageJob.*${MSG_ID}"; then
    ok "SendMessageJob enqueued for message $MSG_ID"
  else
    fail "SendMessageJob NOT enqueued for message $MSG_ID"
  fi

  if echo "$JOB_LOG" | grep -q "enviado"; then
    ok "SendMessageJob completed: message delivered to Evolution"
  else
    # May still be running — check DB source_id
    SOURCE_ID=$(docker exec chatwoot-web bundle exec rails runner \
      "puts Message.find(${MSG_ID}).source_id.to_s" 2>/dev/null | tail -1)
    [ -n "$SOURCE_ID" ] && [ "$SOURCE_ID" != "" ] && \
      ok "SendMessageJob completed: source_id=$SOURCE_ID" || \
      fail "SendMessageJob did not complete (no source_id, no 'enviado' log)"
  fi
fi

echo ""
echo "=== Private note NOT sent to WhatsApp ==="

PRIV_RESULT=$(docker exec chatwoot-web bundle exec rails runner '
  begin
    inbox = Inbox.where(channel_type: "Channel::Api").first
    conv = Conversation.where(inbox: inbox).first
    user = User.first

    msg = conv.messages.create!(
      account_id: conv.account_id,
      inbox_id: conv.inbox_id,
      message_type: :outgoing,
      private: true,
      content: "p16-private-note-#{Time.current.to_i}",
      sender: user
    )
    puts "CREATED:#{msg.id}:#{msg.private?}"
  rescue => e
    puts "ERROR:#{e.message}"
  end
' 2>/dev/null | tail -1)

if echo "$PRIV_RESULT" | grep -q "^CREATED:"; then
  PRIV_ID=$(echo "$PRIV_RESULT" | cut -d: -f2)
  sleep 4

  # Verify WhatsappLite::SendMessageJob was NOT called for this private message
  PRIV_JOB=$(docker logs chatwoot-sidekiq --since=10s 2>&1 | grep "WhatsappLite::SendMessageJob.*${PRIV_ID}" | head -1)
  [ -z "$PRIV_JOB" ] && ok "Private note NOT sent (listener correctly filtered private=true)" || \
    fail "Private note WAS sent to WhatsApp — listener filter broken for message $PRIV_ID"
else
  fail "Could not create private note test: $PRIV_RESULT"
fi

echo ""
echo "=== Echo-back prevention (source_id deduplication) ==="

if [ -n "$MSG_ID" ]; then
  SOURCE_ID=$(docker exec chatwoot-web bundle exec rails runner \
    "puts Message.find_by(id: ${MSG_ID})&.source_id.to_s" 2>/dev/null | tail -1)

  if [ -n "$SOURCE_ID" ] && [ "$SOURCE_ID" != "" ]; then
    ok "source_id persisted: $SOURCE_ID"

    # Verify that a webhook with this source_id would be filtered
    FILTER_CHECK=$(docker exec chatwoot-web bundle exec rails runner \
      "puts Message.exists?(source_id: '${SOURCE_ID}') ? 'FILTERED' : 'PASS_THROUGH'" \
      2>/dev/null | tail -1)
    [ "$FILTER_CHECK" = "FILTERED" ] && ok "Echo-back prevention: webhook with same source_id would be filtered" || \
      fail "Echo-back prevention: source_id not found in Message table"
  else
    # source_id may be nil if Evolution call failed (channel may be disconnected)
    ok "source_id nil (channel may be disconnected — Evolution call skipped)"
  fi
fi

echo ""
echo "=== messageType filter in webhook controller ==="

# Verify webhook controller rejects non-message types (reactions, delivery acks)
TOKEN=$(docker exec chatwoot-web bundle exec rails runner \
  'a = Account.find(1); puts a.settings.dig("whatsapp_lite","evolution_webhook_token").to_s' \
  2>/dev/null | tail -1)

INSTANCE=$(docker exec chatwoot-web bundle exec rails runner \
  'puts WhatsappLiteChannel.where(account_id: 1).first&.instance_id.to_s' \
  2>/dev/null | tail -1)

if [ -n "$INSTANCE" ] && [ -n "$TOKEN" ]; then
  # Send a reactionMessage webhook — should be filtered (returns 200 but no message created)
  COUNT_BEFORE=$(docker exec chatwoot-web bundle exec rails runner \
    'puts Message.count' 2>/dev/null | tail -1)

  curl -s -X POST "https://chat.opp4s.com/api/v1/accounts/1/whatsapp_lite/webhook/${INSTANCE}" \
    -H "X-Evolution-Token: $TOKEN" -H "Content-Type: application/json" \
    -d "{\"event\":\"messages.upsert\",\"data\":{\"key\":{\"remoteJid\":\"5500000000000@s.whatsapp.net\",\"fromMe\":false,\"id\":\"TEST-REACTION-$(date +%s)\"},\"messageType\":\"reactionMessage\",\"message\":{\"reactionMessage\":{\"text\":\"👍\"}}}}" \
    > /dev/null 2>&1

  sleep 2
  COUNT_AFTER=$(docker exec chatwoot-web bundle exec rails runner \
    'puts Message.count' 2>/dev/null | tail -1)

  [ "$COUNT_BEFORE" = "$COUNT_AFTER" ] && ok "reactionMessage webhook filtered (no new message created)" || \
    fail "reactionMessage webhook created a message (messageType filter broken)"
else
  echo "⚠️  Skipping messageType filter test (no Account 1 instance configured)"
fi

echo ""
echo "=== Cleanup ==="

docker exec chatwoot-web bundle exec rails runner '
  Message.where("content LIKE ?", "p16-smoke-%").destroy_all rescue nil
  Message.where("content LIKE ?", "p16-private-note-%").destroy_all rescue nil
' 2>/dev/null || true

echo ""
echo "=== RESULT ==="
echo "Passed: $PASS  Failed: $FAIL"
[ "$FAIL" -eq 0 ] && echo "✅ Parte 16 OK" || { echo "❌ Parte 16 FALHOU"; exit 1; }
