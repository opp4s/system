# Resultados do Pré-voo (data: 2026-05-23)

## Respostas

1. **Faraday:** versão `2.14.1` — sintaxe de blocos v2.x (sem `connection =` separado; `Faraday.new { |f| }.get(url) { |req| }`)

2. **Api::V1::BaseController:** não existe `Api::V1::BaseController` diretamente. A hierarquia real para controllers de contas é:
   - `Api::V1::Accounts::BaseController < Api::BaseController`
   - `Api::BaseController < ApplicationController` (inclui `AccessTokenAuthHelper`)
   - `Api::V1::Accounts::BaseController` inclui `EnsureCurrentAccountHelper` e chama `before_action :current_account`
   - `current_account` é resolvido via `params[:account_id]` no `EnsureCurrentAccountHelper`
   - **Arquivo:** `app/controllers/api/v1/accounts/base_controller.rb`

3. **Contacts::ContactBuilder:** ❌ NÃO EXISTE — usar `Contact.find_or_create_by!` direto com `phone_number:` e `account_id:`

4. **Inboxes::CreateChannelService:** ❌ NÃO EXISTE — criar `Channel::Api` + `Inbox` manualmente

5. **message.activity?:** ✅ FUNCIONA — declaração: `enum message_type: { incoming: 0, outgoing: 1, activity: 2, template: 3 }` em `app/models/message.rb:87`

6. **Trait :private no core:** ❌ NÃO EXISTE em `spec/factories/message.rb` — incluir o bloco `FactoryBot.modify` na nossa factory

7. **channel_type para Inbox:** valor exato = `"Channel::Api"` (polimórfico STI)

7b. **Padrão STI para Inbox:** ❌ `Inbox.create!(channel_type: "Channel::Api")` FALHA com `Validation failed: Channel must exist`
   - **Obrigatório:** `channel_api = Channel::Api.create!(account_id: X)` + `Inbox.create!(channel: channel_api, ...)`
   - Não existe InboxBuilder para Channel::Api — criar manualmente

8. **Auth token no frontend:** mecanismo = `currentUser.access_token` (atributo string no objeto do store)
   - O payload da API serializa como `json.access_token resource.access_token.token` (ver `_user.json.jbuilder:1`)
   - No Vue: `this.currentUser.access_token` ou via store getter `getCurrentUser` → `getCurrentUser.access_token`
   - Exemplo de uso real: `app/javascript/dashboard/mixins/fileUploadMixin.js:82` e `profile/Index.vue:337`
   - **No SPA:** `store.getters['auth/getCurrentUser'].access_token`

9. **Aliases Vite:** definidos em `vite.config.ts:76`:
   - `components` → `app/javascript/dashboard/components`
   - `dashboard` → `app/javascript/dashboard`
   - `helpers` → `app/javascript/shared/helpers`
   - `shared` → `app/javascript/shared`
   - `widget` → `app/javascript/widget`
   - `assets` → `app/javascript/dashboard/assets`

10. **MESSAGE_CREATED:** valor = `'message.created'` · arquivo = `lib/events/types.rb:36`

11. **current_account no BaseController:** resolvido via `Account.find(params[:account_id])` no `EnsureCurrentAccountHelper#ensure_current_account`. Também seta `Current.account = @current_account` automaticamente.

12. **Faraday disponível no app:** ✅ SIM — usado em `app/services/telegram/send_attachments_service.rb`, `app/services/tiktok/client.rb` etc. Sintaxe v2.x.

13. **Current.account existe:** ✅ SIM — definido em `lib/current.rb` como `thread_mattr_accessor :account`. É um módulo (não classe) com `thread_mattr_accessor`. `Current.account = account` funciona. **Descomentar a linha no webhook_controller.**

14. **User#access_token:** ❌ é ASSOCIAÇÃO (classe `AccessToken`) — usar `u.access_token.token`
   - Token do admin: `User.first.access_token.token` → `STwSte3YJbFDVfuALtSeJKxX`

---

## Decisões derivadas

| Questão | Decisão |
|---------|---------|
| ContactBuilder | ❌ não existe → usar `Contact.find_or_create_by!` direto |
| Inbox creation | ✅ obrigatório: `Channel::Api.create!` + `Inbox.create!(channel:)` |
| Token nos curl tests | `User.first.access_token.token` (associação → `.token`) |
| Vue auth | `store.getters['auth/getCurrentUser'].access_token` |
| Faraday | `Faraday.new(url:) { |f| }` — sintaxe v2.x |
| Current.account no webhook | ✅ DESCOMENTAR — `Current.account = account` funciona |
| Trait :private na factory | Incluir `FactoryBot.modify` no nosso factory file |
| BaseController a herdar | `::Api::V1::Accounts::BaseController` (não `::Api::V1::BaseController`) |
| Faraday middlewares | ✅ `:raise_error` e `:retry` disponíveis — usar como planejado nas Partes 6 e 7 |
| BaseController callbacks | `before: :current_account` já herdado — zero código extra de auth necessário |

---

## Itens adicionais (pós-pré-voo)

### 15. Faraday middlewares disponíveis

- **`:raise_error`** → ✅ disponível (`Faraday::Response`)
- **`:retry`** → ✅ disponível (`Faraday::Request`)
- Todos os middlewares request: `:authorization, :instrumentation, :json, :url_encoded, :multipart, :retry, :google_authorization`
- Todos os middlewares response: `:json, :logger, :raise_error, :mashify`
- **Conclusão:** usar `f.response :raise_error` nas Partes 6 e 7 como planejado — sem fallback manual necessário

### 16. `Api::V1::Accounts::BaseController` callbacks (ordem de execução)

```
before: :authenticate_access_token!   ← autentica via api_access_token header
before: :validate_bot_access_token!
before: :authenticate_user!
before: :current_account              ← resolve params[:account_id] → @current_account + Current.account
around: :switch_locale_using_account_locale
```

- `instance_methods(false)` = `[]` — sem métodos próprios, tudo herdado de `Api::BaseController` e concerns
- **Conclusão:** `WhatsappLite::Api::BaseController < ::Api::V1::Accounts::BaseController` herda autenticação completa + `current_account` automático via `params[:account_id]`. Zero código extra necessário.
