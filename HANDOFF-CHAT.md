# HANDOFF — Zavy CRM / Módulo Chat (Evolution direto)

> Documento para um novo chat assumir o processo. Leia tudo antes de agir.
> Última atualização: 2026-06-03

---

## 1. O QUE É O PROJETO

**Zavy CRM** — SaaS CRM estilo Kommo, multi-tenant, WhatsApp-nativo.
- **Orquestrador/PM:** Kiro (humano que passa as demandas)
- **Você (Claude):** executor backend
- **Antigravity:** executor frontend (NÃO mexer no frontend sem o Kiro autorizar)
- **Chatwoot foi REMOVIDO** em 02/06/2026 — Zavy fala **direto** com a Evolution API. Não existe mais Chatwoot em lugar nenhum (código, container, imagens — tudo deletado).

---

## 2. AMBIENTE

- **VPS:** root@185.209.228.202 (você tem acesso SSH/local direto, está logado nela)
- **Diretório:** `/opt/apps/zavy-crm/`
- **Branch git ativa:** `zavy-crm-frontend` (backend E frontend commitam nela atualmente)
- **Repo:** `github.com:opp4s/system.git`
- **URLs:** `https://api.zavycrm.com` (backend) | `https://chat.zavycrm.com` (frontend)
- **Proxy:** Caddy (`/opt/apps/caddy/Caddyfile`) — único na porta 80/443

### Stack
Rails 7.1 API-only (Ruby 3.3) · PostgreSQL 16 · Redis 7 · Sidekiq 7 · Vue 3 SPA · Whisper (Faster-Whisper CPU, porta 8085) · Evolution API (externa, `https://evolution.opp4s.com`)

### Containers (docker-compose.yml)
`zavy-api` (3100→3000) · `zavy-sidekiq` · `zavy-postgres` · `zavy-redis` · `zavy-frontend` (3101→80) · `zavy-whisper` (8085→8000)

---

## 3. WORKFLOW DE DEPLOY (decorar)

```bash
cd /opt/apps/zavy-crm
docker compose build zavy-api zavy-sidekiq   # SEMPRE os dois juntos (mesmo Dockerfile)
docker compose up -d zavy-api zavy-sidekiq
docker compose exec zavy-api bundle exec rails db:migrate RAILS_ENV=production
```

- Comandos `rails`/`rake` rodam via `docker compose exec zavy-api bundle exec rails ...`
- O `docker compose` SÓ funciona a partir de `/opt/apps/zavy-crm` (senão "no configuration file provided")
- Logs poluídos com warning `version is obsolete` — filtre com `grep -v "level=warning\|obsolete"`
- **Frontend:** `docker compose build zavy-frontend && docker compose up -d zavy-frontend`

### Gerar token JWT para testar endpoints
```bash
docker compose exec zavy-api bundle exec rails runner "user = WorkspaceMembership.where(workspace_id: 30).first&.user; puts Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first"
```
Header de teste: `-H "Authorization: Bearer $TOKEN" -H "X-Workspace-Id: 30"`

### Arquivos de mídia salvos (volume Docker)
`/var/lib/docker/volumes/zavy-crm_zavy-uploads/_data/` ← servidos em `https://api.zavycrm.com/uploads/{uuid}.ext`

---

## 4. ARQUITETURA DE MENSAGENS (pós-Chatwoot)

```
RECEBER:
WhatsApp → Evolution → POST /api/v1/webhooks/evolution
  → Evolution::MessageUpsertProcessor
     → Contact + Card + Message + CardEvent("chatwoot_message")
     → DownloadMediaJob (salva base64 em /uploads/)
     → TranscribeAudioJob (Whisper, serializado por lock Redis)

ENVIAR:
POST /api/v1/cards/:id/messages
  → Evolution::MessageSender (sendText/sendMedia/sendWhatsAppAudio)
  → Message(outgoing) + CardEvent("message_sent")
```

### Arquivos-chave
| Arquivo | Função |
|---------|--------|
| `api/app/controllers/api/v1/webhooks/evolution_controller.rb` | Recebe webhooks Evolution (connection.update, messages.upsert/update) |
| `api/app/services/evolution/message_upsert_processor.rb` | Cria Contact+Card+Message+CardEvent do incoming |
| `api/app/services/evolution/message_sender.rb` | Envia texto/mídia/áudio para Evolution |
| `api/app/jobs/download_media_job.rb` | Salva mídia base64→/uploads/, enfileira Transcribe |
| `api/app/jobs/transcribe_audio_job.rb` | Whisper (lock Redis serializa, timeout 300s) |
| `api/app/controllers/api/v1/cards/messages_controller.rb` | Endpoint de envio + escolha de instância |
| `api/app/services/whatsapp/evolution_client.rb` | HTTP client Evolution |
| `api/app/controllers/api/v1/whatsapp/connections_controller.rb` | CRUD conexões WhatsApp (connect/status/disconnect/destroy) |

---

## 5. ARMADILHAS JÁ DESCOBERTAS (não repetir)

1. **CardEvent type:** o frontend SÓ renderiza `chatwoot_message` e `message_sent`. Mensagens incoming DEVEM usar `event_type: "chatwoot_message"` (não `whatsapp_message`). Broadcast usa evento `chatwoot_message_received` com `event_data: {id, event_type, payload, created_at}`.

2. **base64 do áudio Evolution:** vem em `data.message.base64` (minúsculo!) já como OGG decodificado ("OggS"). NÃO em `data.Message.base64` (maiúsculo). A URL `.enc` do `audioMessage.url` é CIFRADA (header `0f52...`) — Whisper rejeita. Sempre usar o base64.

3. **Whisper é CPU e serial:** áudio de 95s leva ~77s. 2 transcrições concorrentes estouram timeout. Resolvido com lock Redis (`whisper:transcribe:lock`) + timeout 300s no `TranscribeAudioJob`. Modelo `Systran/faster-whisper-small`.

4. **nginx do frontend cacheia IP:** `zavy-frontend` nginx usa `resolver 127.0.0.11 valid=10s` + variável no `proxy_pass` para não cravar o IP do `zavy-api` (causava 502 após rebuild). Frontend chama `/api/api/v1/...` (baseURL `/api` + path `/api/v1/...`); nginx faz strip do primeiro `/api/`.

5. **queue_adapter:** `config.active_job.queue_adapter = :sidekiq` em production.rb (era `:async` → jobs sumiam no restart).

6. **Reconexão WhatsApp:** ao conectar (`connection.update: open`), `cleanup_stale_disconnected` remove QUALQUER instância (connected ou disconnected) com o mesmo número, herda pipeline_id+name, faz logout na Evolution da antiga. phone_number sempre com `+`.

---

## 6. ESTADO ATUAL DO CHAT (03/06/2026) — ESTÁVEL

| Cenário | Status |
|---------|--------|
| Texto recebido/enviado | ✅ |
| Imagem recebida/enviada | ✅ |
| Documento recebido/enviado | ✅ |
| Áudio enviado | ✅ |
| Áudio recebido + transcrição Whisper | ✅ |
| Reply/quote | ✅ |
| Timeline + URLs de mídia (200 direto) | ✅ |
| Envio pela instância correta (multi-número) | ✅ |
| Bloqueio de envio se WhatsApp de origem off | ✅ |

### Instâncias workspace 30
- `zavy-30-pending-8268d3` | connected | +554198291968 | pipeline=38
- `zavy-30-pending-1246c8` | connected | +554197310537 | pipeline=38
- `zavy-30-pending-7d3a9b` | connected | +554197930037 | pipeline=38

---

## 7. ÚLTIMOS COMMITS (branch zavy-crm-frontend)

```
5fc8d41 — fix(chat): sem fallback de instância — bloqueia envio se WhatsApp origem off
a90f201 — fix(chat): resposta sai pela instância que recebeu a mensagem
cda86c9 — fix(chat): áudio incoming usa base64 OGG válido + serializa transcrição
2890ce9 — fix(chat): mensagens Evolution visíveis no chat (chatwoot_message type)
3ce1958 — fix(connect): cleanup remove instâncias connected com mesmo número
6bf0584 — fix(connect): auto-cleanup instâncias desconectadas duplicadas
c48e125 — fix(frontend): nginx DNS dinâmico evita 502
f1c9399..34ffd03 — Chatwoot removal fases 1-5
```

### Regra de roteamento de instância (commit a90f201 + 5fc8d41) — IMPORTANTE
- `messages.whatsapp_instance_id` guarda QUAL instância recebeu cada mensagem
- No envio, usa a instância da última mensagem **incoming** do card (origem da conversa)
- **SEM FALLBACK para outro número.** Se a instância de origem está desconectada → erro 422 `code: whatsapp_unavailable`, usuário deve reconectar. Nunca responde por outro WhatsApp.
- `GET /cards/:id` detalhado retorna `payload.whatsapp_instance` ({instance_id, name, phone, status} ou null)

---

## 8. PENDENTE AGORA — aguardando Antigravity (frontend)

Spec escrita em **`/opt/apps/zavy-crm/FEATURE-CANAL-WHATSAPP-ANTIGRAVITY.md`**. Backend 100% pronto. Duas tarefas de frontend:
1. Mostrar "CANAL DE COMUNICAÇÃO" na ficha do lead (lê `payload.whatsapp_instance`)
2. Tratar erro 422 `whatsapp_unavailable` no envio (toast + banner + não limpar campo + não inserir na timeline)

---

## 9. PRÓXIMOS PASSOS (depois do chat fechado)

- QA dos módulos: Contatos, Automações, Broadcast (nunca testados end-to-end com dados reais)
- Entidades faltantes vs Kommo: Tasks, Notes, Tags
- Sprint 6: Billing (Asaas)
- Sprints 7-10: IA (rewrite, copilot, qualification, Qdrant embeddings)

---

## 10. REGRAS DO PROJETO

1. NÃO toque no frontend sem o Kiro autorizar (Antigravity é o responsável)
2. NÃO use Chatwoot (removido)
3. `.env` NUNCA commitado (real em `/etc/zavy-crm/production.env`, symlink em `/opt/apps/zavy-crm/.env`)
4. Nunca `git stash --include-untracked`
5. Auditar na VPS antes de reportar OK — não confiar em report cego
6. Docs para devs: intenção + critério de aceite + exclusões de escopo. SEM código de exemplo inventado (citar nome de método/classe real). Não listar "causas prováveis" (cria ancoragem)
7. Ao rebuildar zavy-api, rebuildar zavy-sidekiq junto

---

## 11. MEMÓRIA PERSISTENTE

Detalhes técnicos completos (schemas, rotas, env vars) em:
`/root/.claude/projects/-root/memory/project-zavy-crm.md`

Leia esse arquivo também — tem o schema das tabelas, env vars críticas e mais armadilhas.
