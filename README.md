# Chatwoot WhatsApp Lite

Plugin para conectar WhatsApp ao Chatwoot via **Evolution API**, com wizard de conexão nativo (QR Code ou Código de Pareamento).

## Como funciona

1. Admin acessa **Settings → Integrations → WhatsApp Lite** no Chatwoot
2. Clica em **Conectar WhatsApp**, preenche o número
3. Escaneia o QR ou insere o código de pareamento no celular
4. Inbox criado automaticamente no Chatwoot
5. Mensagens bidirecionais: tudo que a Evolution vê aparece no Chatwoot

## Arquitetura

```
Vue SPA (Chatwoot)
    │ POST /api/v1/accounts/:id/whatsapp_lite/connect
    ▼
WhatsappLite::Engine (Rails, via initializer routes.prepend)
    │ Faraday
    ▼
Evolution API (https://evolution.opp4s.com)
    │ Webhook POST /api/v1/accounts/:id/whatsapp_lite/webhook/:instance_id
    ▼
WebhookController → Conversation + Message no Chatwoot

MESSAGE_CREATED (Wisper sync_dispatcher)
    → MessageListener (filtra: outgoing + sem source_id)
    → SendMessageJob → Evolution API → WhatsApp
```

**Premissa de produto:** Chatwoot é espelho completo da Evolution.
Toda mensagem que a Evolution vê (incoming, outgoing do celular, outgoing de sistemas externos) é registrada no Chatwoot.

## Estrutura do plugin

```
/opt/apps/chatwoot-whatsapp-lite/
├── chatwoot/
│   ├── app/
│   │   ├── controllers/whatsapp_lite/api/   ← 9 controllers
│   │   ├── jobs/whatsapp_lite/              ← SendMessageJob, DownloadMediaJob
│   │   ├── models/whatsapp_lite_channel.rb  ← 5-state machine
│   │   └── javascript/dashboard/...         ← Frontend Vue
│   ├── lib/whatsapp_lite/
│   │   ├── engine.rb                        ← Rails::Engine isolate_namespace
│   │   ├── listeners/message_listener.rb    ← Wisper subscriber
│   │   └── account_helpers.rb               ← Hub-and-spoke credentials
│   ├── config/
│   │   ├── initializers/whatsapp_lite.rb    ← Routes, listener, APPS_CONFIG
│   │   └── integration/whatsapp_lite.yml    ← Card na UI
│   └── db/migrate/                          ← CreateWhatsappLiteChannels
├── bin/smoke/                               ← Smoke tests por parte (p2..p16)
├── Dockerfile                               ← Build: chatwoot base + plugin
└── assets/                                  ← Logo whatsapp_lite.png
```

## Instalação

### Pré-requisitos

- Docker + Docker Compose
- Chatwoot v4.14.0+ rodando
- Evolution API configurada e acessível

### Opção A — Trocar imagem Docker (recomendado)

```yaml
# docker-compose.yml
services:
  chatwoot-web:
    image: ghcr.io/opp4s/chatwoot-whatsapp-lite:latest
  chatwoot-sidekiq:
    image: ghcr.io/opp4s/chatwoot-whatsapp-lite:latest
```

### Opção B — Build local

```bash
cd /opt/apps/chatwoot-whatsapp-lite
docker build -t chatwoot-whatsapp-lite:latest .

# Migration (antes de recriar containers)
docker run --rm --network opt_apps_default \
  --env-file /opt/apps/chatwoot/.env \
  chatwoot-whatsapp-lite:latest \
  bundle exec rails db:migrate

# Deploy
cd /opt/apps/chatwoot
docker compose up -d --force-recreate chatwoot-web chatwoot-sidekiq
```

### Configuração de credenciais

No Chatwoot, Account 1 (primary), via **Settings → Integrations → WhatsApp Lite → Configurações**:
- URL da Evolution API
- Chave da Evolution API
- Token de webhook (usado para autenticar webhooks da Evolution)

Ou via console:
```ruby
Account.find(1).update!(settings: Account.find(1).settings.merge({
  "whatsapp_lite" => {
    "evolution_api_url"       => "https://evolution.opp4s.com",
    "evolution_api_key"       => "SUA_CHAVE",
    "evolution_webhook_token" => "SEU_TOKEN_WEBHOOK"
  }
}))
```

## Desenvolvimento local

### Setup (uma vez)

```bash
# 1. Criar override de volumes
cp docker-compose.override.yml.example /opt/apps/chatwoot/docker-compose.override.yml

# 2. Recriar containers com volumes
cd /opt/apps/chatwoot
docker compose up -d --force-recreate chatwoot-web chatwoot-sidekiq

# 3. Rodar migrations
docker exec chatwoot-web bundle exec rails db:migrate
```

### Ciclo de desenvolvimento

```bash
# Editar arquivos no host em /opt/apps/chatwoot-whatsapp-lite/chatwoot/
# Depois:
cd /opt/apps/chatwoot
docker compose restart chatwoot-web chatwoot-sidekiq
```

### Smoke tests

```bash
# Rodar todos
COMPLETED_PARTS="p2 p3 p4 p5 p6 p7 p8 p12 p13 p14 p15 p16" bash bin/smoke-test.sh

# Rodar um específico
bash bin/smoke/p16-mirror-evolution.sh
```

## Atualização do Chatwoot

```bash
# 1. Verificar compatibilidade
sh chatwoot/patches/check-upgrade-compat.sh /path/to/new-chatwoot-src

# 2. Se compatível, rebuild
CHATWOOT_VERSION=vX.Y.Z docker build -t chatwoot-whatsapp-lite .

# 3. Migration + deploy
docker run --rm --network opt_apps_default \
  --env-file /opt/apps/chatwoot/.env \
  chatwoot-whatsapp-lite:latest bundle exec rails db:migrate

cd /opt/apps/chatwoot
docker compose up -d --force-recreate chatwoot-web chatwoot-sidekiq
```

Patches no core (apenas 2 arquivos):
- `app/models/integration/app.rb` — loader glob para *.yml
- `integrations.routes.js` — import + spread de plugin-routes.js

## Multi-tenant (hub-and-spoke)

Credenciais da Evolution ficam na Account 1 (primary).
Todas as accounts usam as mesmas credenciais via `AccountHelpers.credentials_for`.
Cada account tem suas próprias inboxes e channels isolados.

## Licença

MIT
