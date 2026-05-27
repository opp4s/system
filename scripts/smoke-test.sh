#!/usr/bin/env bash
# Smoke test do Zavy CRM API
# Uso: ./scripts/smoke-test.sh [BASE_URL]
# Exemplo: ./scripts/smoke-test.sh https://api.zavycrm.com
#          ./scripts/smoke-test.sh http://localhost:3100

set -euo pipefail

BASE="${1:-http://localhost:3100}"
PASS=0
FAIL=0
ERRORS=()

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

ok()   { echo -e "${GREEN}✅ $1${NC}"; PASS=$((PASS+1)); }
fail() { echo -e "${RED}❌ $1${NC}"; FAIL=$((FAIL+1)); ERRORS+=("$1"); }
info() { echo -e "${YELLOW}   $1${NC}"; }

# Usuário único por run
TS=$(date +%s)
EMAIL="smoke_${TS}@test.com"
PASSWORD="Smoke123!"

echo ""
echo "🚀 Zavy CRM — Smoke Test"
echo "   BASE_URL: $BASE"
echo "   Usuário:  $EMAIL"
echo "   $(date)"
echo "─────────────────────────────────────────"

# ---------------------------------------------------------------------------
# 1. Health check
# ---------------------------------------------------------------------------
echo ""
echo "1. Health check"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$BASE/up")
if [ "$STATUS" = "200" ]; then
  ok "GET /up → 200"
else
  fail "GET /up → esperado 200, obteve $STATUS"
fi

# ---------------------------------------------------------------------------
# 2. Register
# ---------------------------------------------------------------------------
echo ""
echo "2. Register"
BODY=$(curl -s -X POST "$BASE/auth/register" \
  -H "Content-Type: application/json" \
  -d "{\"user\":{\"name\":\"Smoke User\",\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\",\"password_confirmation\":\"$PASSWORD\"}}")

STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE/auth/register" \
  -H "Content-Type: application/json" \
  -d "{\"user\":{\"name\":\"Smoke User 2\",\"email\":\"dupe_${TS}@test.com\",\"password\":\"$PASSWORD\",\"password_confirmation\":\"$PASSWORD\"}}")

TOKEN=$(echo "$BODY" | python3 -c "import sys,json; print(json.load(sys.stdin).get('token',''))" 2>/dev/null || echo "")
WS_ID=$(echo "$BODY" | python3 -c "import sys,json; print(json.load(sys.stdin).get('data',{}).get('workspace',{}).get('id',''))" 2>/dev/null || echo "")

if [ -n "$TOKEN" ] && [ -n "$WS_ID" ]; then
  ok "POST /auth/register → 201, token + workspace retornados"
  info "workspace_id=$WS_ID"
else
  fail "POST /auth/register → token ou workspace ausente"
  info "Response: $BODY"
fi

# Register duplicado → 422
DUP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE/auth/register" \
  -H "Content-Type: application/json" \
  -d "{\"user\":{\"name\":\"Dup\",\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\",\"password_confirmation\":\"$PASSWORD\"}}")
if [ "$DUP_STATUS" = "422" ]; then
  ok "POST /auth/register (e-mail duplicado) → 422"
else
  fail "POST /auth/register duplicado → esperado 422, obteve $DUP_STATUS"
fi

# ---------------------------------------------------------------------------
# 3. Login
# ---------------------------------------------------------------------------
echo ""
echo "3. Login"
LOGIN_RESP=$(curl -s -X POST "$BASE/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"user\":{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}}")
LOGIN_TOKEN=$(echo "$LOGIN_RESP" | python3 -c "import sys,json; print(json.load(sys.stdin).get('token',''))" 2>/dev/null || echo "")

if [ -n "$LOGIN_TOKEN" ]; then
  ok "POST /auth/login → 200, token retornado"
  TOKEN="$LOGIN_TOKEN"
else
  fail "POST /auth/login → token ausente"
  info "Response: $LOGIN_RESP"
fi

# Login com senha errada → 401
WRONG_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"user\":{\"email\":\"$EMAIL\",\"password\":\"senhaerrada\"}}")
if [ "$WRONG_STATUS" = "401" ]; then
  ok "POST /auth/login (senha errada) → 401"
else
  fail "POST /auth/login senha errada → esperado 401, obteve $WRONG_STATUS"
fi

# ---------------------------------------------------------------------------
# 4. GET /me
# ---------------------------------------------------------------------------
echo ""
echo "4. Perfil (/me)"
ME_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$BASE/api/v1/me" \
  -H "Authorization: Bearer $TOKEN")
if [ "$ME_STATUS" = "200" ]; then
  ok "GET /api/v1/me → 200"
else
  fail "GET /api/v1/me → esperado 200, obteve $ME_STATUS"
fi

# Sem token → 401
UNAUTH=$(curl -s -o /dev/null -w "%{http_code}" "$BASE/api/v1/me")
if [ "$UNAUTH" = "401" ]; then
  ok "GET /api/v1/me (sem token) → 401"
else
  fail "GET /api/v1/me sem token → esperado 401, obteve $UNAUTH"
fi

# ---------------------------------------------------------------------------
# 5. List workspaces
# ---------------------------------------------------------------------------
echo ""
echo "5. Workspaces"
WS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$BASE/api/v1/workspaces" \
  -H "Authorization: Bearer $TOKEN")
if [ "$WS_STATUS" = "200" ]; then
  ok "GET /api/v1/workspaces → 200"
else
  fail "GET /api/v1/workspaces → esperado 200, obteve $WS_STATUS"
fi

# Create workspace
NEW_WS=$(curl -s -X POST "$BASE/api/v1/workspaces" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"workspace":{"name":"Smoke Workspace","plan":"starter"}}')
NEW_WS_ID=$(echo "$NEW_WS" | python3 -c "import sys,json; print(json.load(sys.stdin).get('data',{}).get('id',''))" 2>/dev/null || echo "")

if [ -n "$NEW_WS_ID" ]; then
  ok "POST /api/v1/workspaces → 201, id=$NEW_WS_ID"
else
  fail "POST /api/v1/workspaces → id ausente"
  info "Response: $NEW_WS"
fi

# Show workspace
if [ -n "$NEW_WS_ID" ]; then
  SHOW_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$BASE/api/v1/workspaces/$NEW_WS_ID" \
    -H "Authorization: Bearer $TOKEN")
  if [ "$SHOW_STATUS" = "200" ]; then
    ok "GET /api/v1/workspaces/$NEW_WS_ID → 200"
  else
    fail "GET /api/v1/workspaces/$NEW_WS_ID → esperado 200, obteve $SHOW_STATUS"
  fi
fi

# Update workspace
if [ -n "$NEW_WS_ID" ]; then
  UPD_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X PATCH "$BASE/api/v1/workspaces/$NEW_WS_ID" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"workspace":{"name":"Smoke Workspace Editado"}}')
  if [ "$UPD_STATUS" = "200" ]; then
    ok "PATCH /api/v1/workspaces/$NEW_WS_ID → 200"
  else
    fail "PATCH /api/v1/workspaces/$NEW_WS_ID → esperado 200, obteve $UPD_STATUS"
  fi
fi

# ---------------------------------------------------------------------------
# 6. Invite + Accept
# ---------------------------------------------------------------------------
echo ""
echo "6. Invite / Accept"
INVITEE_EMAIL="invitee_${TS}@test.com"
# Registra o convidado
curl -s -X POST "$BASE/auth/register" \
  -H "Content-Type: application/json" \
  -d "{\"user\":{\"name\":\"Invitee\",\"email\":\"$INVITEE_EMAIL\",\"password\":\"$PASSWORD\",\"password_confirmation\":\"$PASSWORD\"}}" > /dev/null

INVITE_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE/api/v1/workspaces/$NEW_WS_ID/invite" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"invite\":{\"email\":\"$INVITEE_EMAIL\",\"role\":\"agent\"}}")
if [ "$INVITE_STATUS" = "201" ]; then
  ok "POST /api/v1/workspaces/$NEW_WS_ID/invite → 201"
else
  fail "POST /workspaces/$NEW_WS_ID/invite → esperado 201, obteve $INVITE_STATUS"
fi

# Accept com token do convidado
INVITEE_RESP=$(curl -s -X POST "$BASE/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"user\":{\"email\":\"$INVITEE_EMAIL\",\"password\":\"$PASSWORD\"}}")
INVITEE_TOKEN=$(echo "$INVITEE_RESP" | python3 -c "import sys,json; print(json.load(sys.stdin).get('token',''))" 2>/dev/null || echo "")

if [ -n "$INVITEE_TOKEN" ]; then
  ACCEPT_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE/api/v1/workspaces/$NEW_WS_ID/accept_invite" \
    -H "Authorization: Bearer $INVITEE_TOKEN")
  if [ "$ACCEPT_STATUS" = "200" ]; then
    ok "POST /api/v1/workspaces/$NEW_WS_ID/accept_invite → 200"
  else
    fail "POST /workspaces/$NEW_WS_ID/accept_invite → esperado 200, obteve $ACCEPT_STATUS"
  fi
fi

# ---------------------------------------------------------------------------
# 7. Logout
# ---------------------------------------------------------------------------
echo ""
echo "7. Logout"
LOGOUT_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "$BASE/auth/logout" \
  -H "Authorization: Bearer $TOKEN")
if [ "$LOGOUT_STATUS" = "200" ]; then
  ok "DELETE /auth/logout → 200"
else
  fail "DELETE /auth/logout → esperado 200, obteve $LOGOUT_STATUS"
fi

# Token revogado → 401
REVOKED=$(curl -s -o /dev/null -w "%{http_code}" "$BASE/api/v1/me" \
  -H "Authorization: Bearer $TOKEN")
if [ "$REVOKED" = "401" ]; then
  ok "GET /api/v1/me (token revogado) → 401"
else
  fail "Token revogado ainda aceito → esperado 401, obteve $REVOKED"
fi

# ---------------------------------------------------------------------------
# Resultado final
# ---------------------------------------------------------------------------
echo ""
echo "─────────────────────────────────────────"
echo -e "  ${GREEN}Passou: $PASS${NC}   ${RED}Falhou: $FAIL${NC}"
if [ ${#ERRORS[@]} -gt 0 ]; then
  echo ""
  echo -e "${RED}Falhas:${NC}"
  for e in "${ERRORS[@]}"; do
    echo -e "  ${RED}• $e${NC}"
  done
fi
echo "─────────────────────────────────────────"
echo ""

[ "$FAIL" -eq 0 ]
