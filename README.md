# Chatwoot WhatsApp Lite

Plugin para conectar WhatsApp ao Chatwoot via **Evolution API**, com wizard de conexão nativo (QR Code ou Código de Pareamento).

## Como funciona

1. Admin acessa **Settings → Integrations → WhatsApp Lite** no Chatwoot
2. Clica em **Conectar WhatsApp**, preenche o número
3. Escaneia o QR ou insere o código de pareamento no celular
4. Inbox criado automaticamente no Chatwoot

## Stack

```
Chatwoot UI (Vue.js wizard)
    ↕ HTTP (fetch)
n8n webhooks  (/wa/connect, /wa/status/:id, /wa/instances)
    ↕
Evolution API  ←→  WhatsApp (WARP proxy)
    ↕
Chatwoot API  (autoCreate inbox)
```

## Instalação

### Pré-requisitos

- Docker + Docker Compose
- Chatwoot rodando (oficial `chatwoot/chatwoot`)
- Evolution API configurada
- n8n com os workflows `WhatsApp Lite — Backend API` importados

### Opção A — Trocar imagem Docker (recomendado)

```yaml
# docker-compose.yml
services:
  chatwoot-web:
    image: ghcr.io/opp4s/chatwoot-whatsapp-lite:latest  # <- substituir
    # ... resto igual
  chatwoot-worker:
    image: ghcr.io/opp4s/chatwoot-whatsapp-lite:latest  # <- substituir
```

### Opção B — Build local

```bash
git clone https://github.com/opp4s/system.git
cd system/chatwoot-whatsapp-lite

# Build (demora ~10 min na primeira vez)
docker build -t chatwoot-whatsapp-lite .

# Injetar config de runtime
CONTAINER=chatwoot-web \
WA_API_BASE=https://api.seudominio.com/webhook \
bash scripts/inject-config.sh
```

### n8n workflows

Importe o arquivo `n8n/workflows/whatsapp-lite-backend.json` no seu n8n.

Configure as variáveis de ambiente no n8n:
- `EVOLUTION_URL` — URL da sua Evolution API
- `EVOLUTION_KEY` — API key da Evolution
- `CHATWOOT_URL` — URL do Chatwoot
- `CHATWOOT_ACCOUNT_ID` — ID da conta Chatwoot
- `CHATWOOT_TOKEN` — Token do usuário admin Chatwoot

## Atualização do Chatwoot

Quando o Chatwoot lançar nova versão:

```bash
# Rebuild com nova versão
docker build --build-arg CHATWOOT_VERSION=vX.Y.Z -t chatwoot-whatsapp-lite .
```

O plugin tem impacto mínimo nos arquivos do Chatwoot:
- `config/integration/apps.yml` — +6 linhas
- `config/locales/en.yml` — +4 linhas  
- `integrations.routes.js` — +1 import, +8 linhas de rota
- Novos arquivos em `WhatsappLite/` (não sobrescreve nada)

## Variáveis de ambiente do frontend

```js
// Injetado em public/dashboard/custom-scripts.js
window.whatsappLiteConfig = {
  apiBase: 'https://api.seudominio.com/webhook'
}
```

## Licença

MIT — use, fork, monetize.
