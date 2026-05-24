# Execution Notes — WhatsApp Lite Plugin

Surpresas e achados durante a execução que não estão no plano original.
Útil para upgrades futuros e para outro engenheiro entender o estado real do ambiente.

---

## Parte 1 — Pré-voo

### Zeitwerk eager_load_paths inclui lib/
`config/application.rb` do Chatwoot tem `config.eager_load_paths << Rails.root.join('lib')`.
Isso significa que `lib/whatsapp_lite/` é gerenciado pelo Zeitwerk com a regra de 1 constante por arquivo.
**Impacto:** não criar arquivos com múltiplas constantes nesse diretório (ex: `errors.rb` com 3 classes).

### Api::V1::Accounts::BaseController (não Api::V1::BaseController)
O controller base correto é `::Api::V1::Accounts::BaseController`. `Api::V1::BaseController` não existe.
Já tem `before_action :current_account` que resolve via `params[:account_id]`.

### STI Channel::Api obrigatório
`Inbox.create!(channel_type: 'Channel::Api')` falha sozinho. Padrão correto:
```ruby
channel_api = Channel::Api.create!(account_id: account_id)
inbox = Inbox.create!(account_id: account_id, channel: channel_api)
```

### User#access_token é associação
`u.access_token` retorna objeto `AccessToken`. Usar `u.access_token.token` para o string.

---

## Parte 2 — Migration + Model

### en.yml e pt_BR.yml corrompidos de sessão anterior
Os arquivos `config/locales/en.yml` e `config/locales/pt_BR.yml` do Chatwoot tinham
`whatsapp_lite:` appendado inline (sem newline) em dois lugares cada, de uma sessão anterior.
Sintoma: `Psych::SyntaxError: did not find expected key while parsing a block mapping at line N column 9`.
Correção: Ruby inline no container para remover os sufixos corrompidos:
```bash
docker exec chatwoot-web ruby -e "
lines = File.readlines('/app/config/locales/en.yml')
result = []
skip = 0
lines.each do |line|
  if skip > 0; skip -= 1; next; end
  if line.include?('    whatsapp_lite:') && (line.strip.start_with?('permission_request_failed:') || line.strip.start_with?('description:'))
    result << line.sub('    whatsapp_lite:', ''); skip = 3
  else; result << line; end
end
File.write('/app/config/locales/en.yml', result.join)
"
```

### Bootsnap cache deve ser limpo após edição manual de YML
O Bootsnap cacheia arquivos YAML compilados. Após editar um .yml diretamente no container,
o cache antigo continua sendo usado até ser limpo:
```bash
docker exec chatwoot-web sh -c "rm -rf /app/tmp/cache/bootsnap/*"
docker compose restart chatwoot-web chatwoot-sidekiq
```

### File-to-file bind mounts exigem arquivo existente na imagem
Docker não consegue montar arquivo-a-arquivo (`host_file:container_file`) quando o arquivo de destino
não existe na imagem. Cria um diretório em vez do arquivo (ou falha com ENOTDIR).
**Workaround para dev:** usar `docker cp` para o `whatsapp_lite_channel.rb` (model não está na imagem).
Diretórios são montados sem problema.

### Zeitwerk: 1 constante por arquivo, nome do arquivo = nome da constante
`errors.rb` com 3 classes (`Error`, `EvolutionApiError`, `InvalidWebhookError`) causa:
`NameError: expected file .../errors.rb to define constant WhatsappLite::Errors`
Solução: 3 arquivos separados (`error.rb`, `evolution_api_error.rb`, `invalid_webhook_error.rb`).

---

## Parte 3 — Engine + roteamento

### `initializer 'add_routes', before: :add_routing_paths` não funciona
Engines carregadas via Zeitwerk eager_load_paths (lib/) têm seus initializers registrados
DEPOIS que a chain do Rails passou pelo ponto de routing. O initializer do engine nunca aparece
em `Rails.application.initializers`. Sintoma: rotas não aparecem em `rails routes`.
**Fix:** usar `config.after_initialize { Rails.application.routes.prepend { ... } }` no config
initializer — `routes.prepend` pode ser chamado a qualquer momento após a inicialização.

### `routes.draw` dentro de `load_config_initializers` causa recursão com Devise
Chamar `Rails.application.routes.draw` dentro de um config initializer (que roda em
`load_config_initializers`) dispara `Devise::RouteSet#finalize!` em loop infinito (SystemStackError).
**Fix:** mover para `config.after_initialize` — roda após tudo estar carregado.

### `namespace :api + namespace :v1 + scope module:` acumula o module prefix
O controller lookup resultante fica `api/v1/whatsapp_lite/api/connect` em vez de `whatsapp_lite/api/connect`.
**Fix:** usar path absoluto com `/` no controller:
```ruby
post 'whatsapp_lite/connect', controller: '/whatsapp_lite/api/connect', action: :create
```

### `docker compose -f X` sem `-f override` ignora o override file
Especificar `-f docker-compose.yml` explicitamente desativa a detecção automática do override.
Consequência: volume mounts do override não são aplicados, containers iniciam com arquivos da imagem.
**Fix:** sempre usar AMBOS os arquivos:
```bash
docker compose -f /opt/apps/chatwoot/docker-compose.yml \
               -f /opt/apps/chatwoot/docker-compose.override.yml \
               restart chatwoot-web chatwoot-sidekiq
```

### Locales corrompidos na imagem — solução definitiva: volume mount
Como a imagem tem os locales corrompidos, qualquer force-recreate restaura a corrupção.
**Fix definitivo:** montar os locales corrigidos do host como volumes no override:
```yaml
- /opt/apps/chatwoot-whatsapp-lite/chatwoot/config/locales/en.yml:/app/config/locales/en.yml
- /opt/apps/chatwoot-whatsapp-lite/chatwoot/config/locales/pt_BR.yml:/app/config/locales/pt_BR.yml
```

---

## Parte 4 — Listener + Dispatcher (pré-investigação)

### Check A: MESSAGE_CREATED despachado em app/models/message.rb:379
`dispatch_create_events` é chamado via `after_create_commit → execute_after_create_commit_callbacks`.
Portanto `Message.create!` dispara o evento diretamente — builder não é necessário no smoke test.

### Check B: Dispatcher disponível, mas sem `.subscribe` direto
`Rails.configuration.dispatcher` é instância de `Dispatcher` (Singleton).
Não tem `subscribe` nem `listeners` expostos — tem `sync_dispatcher` e `async_dispatcher`.
Ambos herdam de `BaseDispatcher < Wisper::Publisher` e TÊM `subscribe`.
Subscribe correto: `dispatcher.sync_dispatcher.subscribe(listener_instance)`.

### Check B2: Timing — `after_initialize` roda ANTES de `to_prepare`
`event_handlers.rb` cria o dispatcher em `config.to_prepare` (roda após `after_initialize`).
Se subscrevermos em `after_initialize`, o dispatcher ainda não existe.
**Fix:** usar `config.to_prepare` no inicializador do plugin — mesma estratégia do Chatwoot.
Como `event_handlers.rb` (e) vem antes de `whatsapp_lite.rb` (w) alfabeticamente,
seu `to_prepare` (que cria o dispatcher) roda antes do nosso (que subscreve).

### Check C: Volumes OK em web e sidekiq
`lib/whatsapp_lite` e `app/jobs/whatsapp_lite` montados em ambos os containers. ✅
`app/controllers/whatsapp_lite` só no web (sidekiq não precisa de controllers). ✅

### RSpec não disponível no container (production mode)
Container roda sem gems de test/development. Level 2 (RSpec) substituído por:
- Level 1: log "[whatsapp_lite] MessageListener subscribed" no boot
- Level 3: criar Message real → verificar Sidekiq queue via rails runner

### `skip_before_action :verify_authenticity_token` requer `raise: false`
`ApplicationController` do Chatwoot pode não ter o callback `verify_authenticity_token` definido
(ou ter uma configuração diferente). Em Rails 7.1, `skip_before_action` levanta `ArgumentError` se
o callback não existir. **Fix:** `skip_before_action :verify_authenticity_token, raise: false`.

---

## Parte 5 — Webhook Controller

### `ContactInbox` requer `source_id`
`ContactInbox` tem `validates :source_id, presence: true`. Ao usar `find_or_create_by!`,
o bloco de inicialização deve incluir `ci.source_id = SecureRandom.uuid`.
Sem isso: `ActiveRecord::RecordInvalid: Validation failed: Source can't be blank`.

### `Attachment.file_types` não tem `:document`
`Attachment.file_types.keys` inclui `image`, `audio`, `video`, `file` — mas NÃO `document`.
**Fix:** mapear `'document' → 'file'` no DownloadMediaJob (constante `FILE_TYPE_MAP`).

---

## Parte 6 — DownloadMediaJob (Mídia)

### aws-sdk-s3 >= 1.210 conflita com `content_md5` do ActiveStorage
`aws-sdk-s3 1.208` + `aws-sdk-core 3.240` adicionam checksum CRC32 automaticamente
(`request_checksum_calculation: "when_supported"` é o default). ActiveStorage S3 service
também envia `content_md5`. S3 rejeita: `You can only specify one non-default checksum at a time`.
**Fix:** no initializer do plugin (top-level, fora de qualquer block), antes do after_initialize:
```ruby
Aws.config.update(
  request_checksum_calculation: 'when_required',
  response_checksum_validation: 'when_required'
) if defined?(Aws)
```
Isso precisa ficar no TOP NÍVEL do initializer (não dentro de um block), porque o cliente S3
é criado em `after_initialize` — se o config já estiver setado quando o cliente for criado,
ele usa o valor correto.

### Faraday 2.x não segue redirects por padrão
Picsum.photos e algumas CDNs retornam 302. Faraday 2.x requer middleware explícito:
```ruby
require 'faraday/follow_redirects'
conn = Faraday.new { |f| f.response :follow_redirects }
```
Gem `faraday-follow_redirects` já está disponível no container (confirmado).
Sem isso: `response.success?` é `false` para 302, job retorna early sem criar attachment.
