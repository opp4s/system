# FEATURE — Canal de comunicação + erro de envio (Frontend)

## Contexto
O backend já está pronto (commits `a90f201`, `5fc8d41`). Esta spec cobre **só o frontend**.

Quando um lead manda mensagem, ele contata um número WhatsApp específico (uma das instâncias conectadas). A resposta SEMPRE sai por esse mesmo número. **Não existe fallback** — se aquele WhatsApp estiver desconectado, o envio é bloqueado e o usuário precisa ver o erro para reconectar.

Duas tarefas:
1. Mostrar na ficha do lead QUAL WhatsApp está conversando (canal).
2. Tratar o erro de envio quando o WhatsApp de origem está desconectado.

---

## TAREFA 1 — Mostrar o canal de comunicação na ficha do lead

### O que o backend já entrega

`GET /api/v1/pipelines/:pipeline_id/cards/:card_id` (payload detalhado) agora inclui:

```json
{
  "data": {
    "id": 56,
    "title": "Jessica",
    "conversation": { "id": 12, "status": "open", "last_activity_at": "..." },
    "whatsapp_instance": {
      "instance_id": "zavy-30-pending-7d3a9b",
      "name": "Vendas SP",
      "phone": "+554197930037",
      "status": "connected"
    }
  }
}
```

- `whatsapp_instance` pode ser `null` (card manual sem histórico de mensagem recebida).
- `status` pode ser `"connected"` ou `"disconnected"`.

### O que fazer

Na coluna esquerda do card detail (`CardDetail.vue`), abaixo de "CONTATO PRINCIPAL", adicionar um bloco:

```
CANAL DE COMUNICAÇÃO
📱 +55 41 9793-0037
   Vendas SP · 🟢 Conectado
```

Regras visuais:
- Mostrar o telefone formatado (`+55 41 9793-0037`) usando o mesmo `formatPhone` que já existe em `ConnectionList.vue`.
- Se `name` presente, mostrar abaixo (ex.: "Vendas SP"). Se não, omitir.
- Indicador de status:
  - `connected` → bolinha verde + "Conectado"
  - `disconnected` → bolinha vermelha + "Desconectado" (texto em vermelho, chamar atenção)
- Se `whatsapp_instance` for `null` → mostrar texto cinza: "Canal não definido"

Mockup (ASCII):
```
┌──────────────────────────────┐
│ CANAL DE COMUNICAÇÃO         │
│ 📱 +55 41 9793-0037          │
│    Vendas SP · 🟢 Conectado  │
└──────────────────────────────┘
```

Quando desconectado (estado de alerta):
```
┌──────────────────────────────┐
│ CANAL DE COMUNICAÇÃO         │
│ 📱 +55 41 9793-0037          │
│    Vendas SP · 🔴 Desconectado│
└──────────────────────────────┘
```

---

## TAREFA 2 — Erro de envio quando WhatsApp de origem está desconectado

### O que o backend já entrega

Ao tentar enviar (`POST /api/v1/cards/:id/messages`) e a instância de origem estiver desconectada, o backend responde:

```
HTTP 422
{
  "error": "O WhatsApp +554197930037 está desconectado. Reconecte-o para responder este lead.",
  "code": "whatsapp_unavailable"
}
```

Outras variações de erro (mesmo status/estrutura):
- Card sem nenhum WhatsApp conectado: `"Nenhum WhatsApp conectado para este lead. Verifique a conexão em Configurações › WhatsApp."`
- Card sem telefone: `"Card sem telefone de contato"` (sem o `code`).

### O que fazer

No `CardDetail.vue`, no método que envia mensagem (o `catch` da chamada `POST /messages`):

1. **Mostrar o erro como toast vermelho** com a mensagem exata vinda de `error.response.data.error`. (provavelmente já existe `toast.error`, só garantir que usa a mensagem do backend, não uma genérica.)

2. **Quando `code === "whatsapp_unavailable"`**, além do toast, dar um reforço visual:
   - NÃO limpar o campo de mensagem (o usuário não perdeu o que digitou — vai reenviar depois de reconectar).
   - Opcional (recomendado): mostrar um banner/aviso fixo acima do composer:
     ```
     ⚠️ WhatsApp desconectado. Reconecte em Configurações › WhatsApp para enviar.
        [ Ir para conexões → ]
     ```
     O botão "Ir para conexões" navega para `/settings/whatsapp`.

3. **A mensagem NÃO deve aparecer na timeline** quando o envio falha (hoje, se houver inserção otimista da mensagem outgoing antes da resposta, ela precisa ser revertida no erro).

### Comportamento esperado (resumo)

| Situação | Resultado |
|----------|-----------|
| Envio OK | Mensagem aparece na timeline (outgoing), campo limpa |
| WhatsApp origem desconectado (422 `whatsapp_unavailable`) | Toast vermelho com a msg do backend + banner + campo NÃO limpa + mensagem NÃO entra na timeline |
| Sem WhatsApp conectado | Toast vermelho + banner |

---

## NÃO fazer
- NÃO implementar reconexão dentro do card (o usuário vai para Configurações › WhatsApp, que já funciona).
- NÃO criar lógica de escolha de instância no frontend — o backend já decide qual número usar. O frontend só EXIBE e trata erro.
- NÃO mexer no backend.

---

## Critério de aceite
1. Abrir card #56 → ver "CANAL DE COMUNICAÇÃO" com +55 41 9793-0037 e status.
2. Desconectar esse WhatsApp em Configurações → voltar ao card → status mostra "Desconectado" (vermelho).
3. Tentar enviar mensagem com WhatsApp desconectado → toast vermelho com a mensagem do backend, campo preservado, mensagem não entra na timeline.
4. Reconectar → enviar → funciona normal.

---

## Arquivos provavelmente envolvidos
- `frontend/src/views/pipelines/CardDetail.vue` (ficha + composer + tratamento de erro)
- `frontend/src/views/settings/whatsapp/ConnectionList.vue` (reaproveitar `formatPhone` / classes de status)
