#!/bin/bash
set -e

# 6 rotas registradas com controllers corretos
routes=$(docker exec chatwoot-web bundle exec rails routes 2>/dev/null | grep -c "whatsapp_lite")
[ "$routes" -ge 6 ] || { echo "  ❌ esperado 6 rotas, encontrado $routes"; exit 1; }

# Controllers corretos (path absoluto, sem api/v1 prefixado)
bad=$(docker exec chatwoot-web bundle exec rails routes 2>/dev/null \
  | grep whatsapp_lite | grep "api/v1/whatsapp_lite" | wc -l)
[ "$bad" -eq 0 ] || { echo "  ❌ $bad rota(s) com controller namespace errado (api/v1/whatsapp_lite)"; exit 1; }

# Sem token → 401
status=$(curl -s -o /dev/null -w "%{http_code}" \
  "https://chat.opp4s.com/api/v1/accounts/1/whatsapp_lite/instances")
[ "$status" = "401" ] || { echo "  ❌ sem token: esperado 401, recebido $status"; exit 1; }

# Com token → 200 + array JSON
TOKEN=$(docker exec chatwoot-web bundle exec rails runner \
  'puts User.where.not(access_token: nil).first.access_token.token' \
  2>/dev/null | tail -1)
response=$(curl -s -w "\n%{http_code}" \
  -H "api_access_token: $TOKEN" \
  "https://chat.opp4s.com/api/v1/accounts/1/whatsapp_lite/instances")
http_code=$(echo "$response" | tail -1)
body=$(echo "$response" | head -1)
[ "$http_code" = "200" ] || { echo "  ❌ com token: esperado 200, recebido $http_code"; exit 1; }
echo "$body" | grep -qE '^\[' || { echo "  ❌ resposta não é array JSON: $body"; exit 1; }

# POST connect stub responde (não 404)
status=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
  -H "api_access_token: $TOKEN" -H "Content-Type: application/json" \
  -d '{}' \
  "https://chat.opp4s.com/api/v1/accounts/1/whatsapp_lite/connect")
[ "$status" != "404" ] || { echo "  ❌ /connect retornou 404"; exit 1; }

echo "  ✓ 6 rotas · controllers corretos · 401 sem token · 200 com token · connect não 404"
