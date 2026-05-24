#!/bin/bash
set -e

TOKEN=$(docker exec chatwoot-web bundle exec rails runner 'u = User.where.not(access_token: nil).first; t = u.access_token; puts t.respond_to?(:token) ? t.token : t' 2>/dev/null | tail -1)
BASE="https://chat.opp4s.com/api/v1/accounts/1/whatsapp_lite"
SMOKE_PHONE="+5541800099901"
INSTANCE_ID="cw-1-5541800099901"

# Limpar instância de smoke anterior se existir
docker exec chatwoot-web bundle exec rails runner "WhatsappLiteChannel.where(instance_id: '${INSTANCE_ID}').destroy_all" 2>/dev/null || true

# 1. Phone inválido → 422
status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE/connect" \
  -H "api_access_token: $TOKEN" -H "Content-Type: application/json" \
  -d '{"phone_number":"abc"}')
[ "$status" = "422" ] || { echo "  ❌ Phone inválido deveria retornar 422, recebeu $status"; exit 1; }

# 2. Connect com número válido → 200 + qr_code_base64
response=$(curl -s -X POST "$BASE/connect" \
  -H "api_access_token: $TOKEN" -H "Content-Type: application/json" \
  -d "{\"phone_number\":\"${SMOKE_PHONE}\",\"method\":\"qr\"}")
echo "$response" | python3 -c "import sys,json; d=json.load(sys.stdin); assert 'qr_code_base64' in d or 'pairing_code' in d, f'No QR/pairing in response: {d}'" 2>/dev/null || {
  echo "  ❌ Connect não retornou qr_code_base64: $response"
  exit 1
}
inbox_id=$(echo "$response" | python3 -c "import sys,json; print(json.load(sys.stdin).get('inbox_id',''))" 2>/dev/null)
[ -n "$inbox_id" ] || { echo "  ❌ Connect não retornou inbox_id"; exit 1; }

# 3. Status retorna qr_pending
status_resp=$(curl -s "$BASE/status?instance_id=${INSTANCE_ID}" -H "api_access_token: $TOKEN")
echo "$status_resp" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d.get('status') in ['qr_pending','connected','qr_expired'], f'Unexpected status: {d}'" 2>/dev/null || {
  echo "  ❌ Status inesperado: $status_resp"
  exit 1
}

# 4. Instances list contém a nova instância
instances=$(curl -s "$BASE/instances" -H "api_access_token: $TOKEN")
echo "$instances" | python3 -c "import sys,json; ids=[i['instance_id'] for i in json.load(sys.stdin)]; assert '${INSTANCE_ID}' in ids, f'Instance not found in: {ids}'" 2>/dev/null || {
  echo "  ❌ Instância ${INSTANCE_ID} não encontrada em /instances"
  exit 1
}

# 5. Disconnect → status disconnected
status=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "$BASE/instances?instance_id=${INSTANCE_ID}" \
  -H "api_access_token: $TOKEN")
[ "$status" = "200" ] || { echo "  ❌ Disconnect retornou $status"; exit 1; }

ch_status=$(docker exec chatwoot-web bundle exec rails runner "puts WhatsappLiteChannel.find_by(instance_id: '${INSTANCE_ID}')&.status" 2>/dev/null | tail -1)
[ "$ch_status" = "disconnected" ] || { echo "  ❌ Channel status deveria ser disconnected, é $ch_status"; exit 1; }

# 6. Sem token → 401
status=$(curl -s -o /dev/null -w "%{http_code}" -X GET "$BASE/instances")
[ "$status" = "401" ] || { echo "  ❌ Sem token deveria retornar 401, recebeu $status"; exit 1; }

echo "  ✓ Phone inválido 422 · Connect QR · Status qr_pending · Instances list · Disconnect 200 · 401 sem token"
