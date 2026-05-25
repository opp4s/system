#!/bin/bash
set -e

# Tabela existe com 9 colunas
cols=$(docker exec postgres psql -U opp4s -d chatwoot -tA -c \
  "SELECT count(*) FROM information_schema.columns
   WHERE table_name='whatsapp_lite_channels'")
[ "$cols" -eq 10 ] || { echo "  ❌ tabela: esperado 10 colunas, encontrado $cols"; exit 1; }

# Índice unique em instance_id
idx=$(docker exec postgres psql -U opp4s -d chatwoot -tA -c \
  "SELECT count(*) FROM pg_indexes
   WHERE tablename='whatsapp_lite_channels'
   AND indexname='index_whatsapp_lite_channels_on_instance_id'")
[ "$idx" -eq 1 ] || { echo "  ❌ índice unique em instance_id ausente"; exit 1; }

# Model: enum + find_or_create_race_safe! + índice unique
docker exec chatwoot-web bundle exec rails runner '
  inbox = Inbox.first or raise "sem Inbox"
  c = WhatsappLiteChannel.find_or_create_race_safe!(
    instance_id: "smoke-p2-$$",
    account_id: 1,
    phone_number: "+5511000000000",
    inbox: inbox
  )
  raise "enum disconnected? quebrado" unless c.disconnected?
  c.update!(status: :qr_pending)
  raise "enum qr_pending? quebrado" unless c.qr_pending?
  c2 = WhatsappLiteChannel.find_or_create_race_safe!(
    instance_id: "smoke-p2-$$",
    account_id: 1,
    phone_number: "+5511000000000",
    inbox: inbox
  )
  raise "race-safe: deveria retornar mesmo registro" unless c.id == c2.id
  c.destroy
  puts "model OK"
' 2>&1 | grep -v "warning\|WARN\|deprecated\|fiddle\|gemspec\|IP_LOOKUP\|Loading\|RubyLLM" | grep -q "model OK" \
  || { echo "  ❌ model não funciona"; exit 1; }

echo "  ✓ 10 colunas · índice unique · enum · race-safe"
