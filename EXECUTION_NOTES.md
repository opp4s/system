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

### `skip_before_action :verify_authenticity_token` requer `raise: false`
`ApplicationController` do Chatwoot pode não ter o callback `verify_authenticity_token` definido
(ou ter uma configuração diferente). Em Rails 7.1, `skip_before_action` levanta `ArgumentError` se
o callback não existir. **Fix:** `skip_before_action :verify_authenticity_token, raise: false`.
