import { defineStore } from 'pinia'
import api from '@/plugins/axios'

// Mocks iniciais para fallbacks de desenvolvimento
const MOCK_AUTOMATIONS = [
  {
    id: 1,
    pipeline_id: 1,
    name: 'Mensagem de Boas-vindas no WhatsApp',
    trigger_type: 'card_created',
    trigger_config: {},
    active: true,
    conditions: [],
    actions: [
      {
        id: 'act_1',
        action_type: 'send_whatsapp',
        action_config: {
          template: 'Olá {contact_name}! Obrigado pelo contato. Recebemos seu interesse em "{title}" no valor de {value}. Em breve um consultor falará com você.'
        }
      }
    ],
    last_triggered_at: '2026-05-28T09:15:00Z',
    trigger_count: 45
  },
  {
    id: 2,
    pipeline_id: 1,
    name: 'Alerta de Lead Frio (Qualificado > 3 dias)',
    trigger_type: 'time_in_stage',
    trigger_config: { stage_id: 102, days: 3 },
    active: true,
    conditions: [
      { field: 'value', operator: 'greater_than', value: 5000 }
    ],
    actions: [
      {
        id: 'act_2',
        action_type: 'create_task',
        action_config: {
          title: 'Fazer follow-up com o lead (proposta estagnada)',
          due_in_days: 1
        }
      },
      {
        id: 'act_3',
        action_type: 'assign_agent',
        action_config: {
          agent_id: null,
          round_robin: true
        }
      }
    ],
    last_triggered_at: '2026-05-28T08:30:22Z',
    trigger_count: 12
  },
  {
    id: 3,
    pipeline_id: 2,
    name: 'Boas-vindas no Pós-Venda',
    trigger_type: 'card_enters_stage',
    trigger_config: { stage_id: 201 },
    active: false,
    conditions: [],
    actions: [
      {
        id: 'act_4',
        action_type: 'send_whatsapp',
        action_config: {
          template: 'Olá {contact_name}! Seu projeto de "{title}" foi iniciado no nosso funil de Kickoff. Vamos alinhar os próximos passos!'
        }
      }
    ],
    last_triggered_at: '2026-05-27T11:20:00Z',
    trigger_count: 5
  }
]

const MOCK_LOGS = {
  1: [
    {
      id: 10001,
      created_at: '2026-05-28T09:15:00Z',
      card_id: 1001,
      card_title: 'Consultoria de TI',
      status: 'success',
      actions_summary: ['💬 WhatsApp: Enviado com sucesso para Carlos Souza']
    },
    {
      id: 10002,
      created_at: '2026-05-28T07:10:00Z',
      card_id: 1003,
      card_title: 'Desenvolvimento Web',
      status: 'success',
      actions_summary: ['💬 WhatsApp: Enviado com sucesso para Pedro Lima']
    },
    {
      id: 10003,
      created_at: '2026-05-27T15:20:00Z',
      card_id: 1002,
      card_title: 'Licenciamento de Software',
      status: 'failed',
      actions_summary: ['💬 WhatsApp: Falha no envio - Token da Evolution API expirado']
    }
  ],
  2: [
    {
      id: 20001,
      created_at: '2026-05-28T08:30:22Z',
      card_id: 1002,
      card_title: 'Licenciamento de Software',
      status: 'success',
      actions_summary: [
        '📋 Tarefa: Criada tarefa "Fazer follow-up com o lead (proposta estagnada)" com vencimento em 29/05',
        '👤 Atribuição: Lead atribuído via Round-robin para Ana Souza'
      ]
    }
  ],
  3: [
    {
      id: 30001,
      created_at: '2026-05-27T11:20:00Z',
      card_id: 2001,
      card_title: 'Setup Zavy CRM',
      status: 'success',
      actions_summary: ['💬 WhatsApp: Enviado com sucesso para Roberto Dias']
    }
  ]
}

export const useAutomationStore = defineStore('automation', {
  state: () => ({
    automations: [],
    logs: [],
    availableFields: {},
    currentAutomation: null,
    loading: {
      list: false,
      detail: false,
      mutation: false,
      logs: false,
      fields: false
    }
  }),

  actions: {
    // Carrega campos disponíveis para condições
    async fetchAvailableFields(pipelineId) {
      this.loading.fields = true
      try {
        const response = await api.get(`/api/v1/pipelines/${pipelineId}/automations/available_fields`)
        this.availableFields = response.data.data || response.data
      } catch (error) {
        console.warn(`GET /api/v1/pipelines/${pipelineId}/automations/available_fields falhou. Usando fallback mockado.`, error)
        // TODO: replace mock
        this.availableFields = {
          value: { type: "number", label: "Valor do Card" },
          days_in_stage: { type: "number", label: "Dias na Etapa" },
          assigned_agent_id: { type: "select", label: "Agente Atribuído" },
          contact_name: { type: "text", label: "Nome do Contato" },
          contact_phone: { type: "text", label: "Telefone do Contato" },
          contact_email: { type: "text", label: "Email do Contato" },
          stage_type: { type: "select", label: "Tipo de Etapa", values: ["won", "lost", "intermediate"] },
          title: { type: "text", label: "Título do Card" }
        }
      } finally {
        this.loading.fields = false
      }
    },

    // Carrega a lista de automações do pipeline ativo
    async fetchAutomations(pipelineId) {
      this.loading.list = true
      try {
        const response = await api.get(`/api/v1/pipelines/${pipelineId}/automations`)
        this.automations = response.data.data || response.data
      } catch (error) {
        console.warn(`GET /api/v1/pipelines/${pipelineId}/automations falhou. Usando fallback mockado.`, error)
        // TODO: replace mock
        this.automations = MOCK_AUTOMATIONS.filter(a => a.pipeline_id === Number(pipelineId))
      } finally {
        this.loading.list = false
      }
    },

    // Carrega logs de execuções de uma automação
    async fetchLogs(pipelineId, id) {
      this.loading.logs = true
      try {
        const response = await api.get(`/api/v1/pipelines/${pipelineId}/automations/${id}/logs`)
        this.logs = response.data.data || response.data
      } catch (error) {
        console.warn(`GET /api/v1/pipelines/${pipelineId}/automations/${id}/logs falhou. Usando fallback mockado.`, error)
        // TODO: replace mock
        this.logs = MOCK_LOGS[id] || []
      } finally {
        this.loading.logs = false
      }
    },

    // Ativa/Desativa uma automação
    async toggleAutomation(pipelineId, id) {
      this.loading.mutation = true
      try {
        const response = await api.post(`/api/v1/pipelines/${pipelineId}/automations/${id}/toggle`)
        const updated = response.data.data || response.data
        
        const idx = this.automations.findIndex(a => a.id === id)
        if (idx !== -1) {
          this.automations[idx].active = updated.active
        }
        return updated
      } catch (error) {
        console.warn(`POST /automations/${id}/toggle falhou. Atualizando reativamente local.`, error)
        // TODO: replace mock
        const idx = this.automations.findIndex(a => a.id === id)
        if (idx !== -1) {
          this.automations[idx].active = !this.automations[idx].active
        }
        return this.automations[idx]
      } finally {
        this.loading.mutation = false
      }
    },

    // Deleta uma automação
    async deleteAutomation(pipelineId, id) {
      this.loading.mutation = true
      try {
        await api.delete(`/api/v1/pipelines/${pipelineId}/automations/${id}`)
        this.automations = this.automations.filter(a => a.id !== id)
      } catch (error) {
        console.warn(`DELETE /automations/${id} falhou. Removendo localmente.`, error)
        // TODO: replace mock
        this.automations = this.automations.filter(a => a.id !== id)
      } finally {
        this.loading.mutation = false
      }
    },

    // Duplica uma automação
    async duplicateAutomation(pipelineId, id) {
      this.loading.mutation = true
      try {
        // Envia requisição para criar uma cópia
        const source = this.automations.find(a => a.id === id)
        if (!source) throw new Error('Automação de origem não encontrada')

        const copyData = {
          ...source,
          name: `${source.name} (Cópia)`,
          active: false
        }
        delete copyData.id
        delete copyData.last_triggered_at
        copyData.trigger_count = 0

        const response = await api.post(`/api/v1/pipelines/${pipelineId}/automations`, copyData)
        const newAuto = response.data.data || response.data
        this.automations.push(newAuto)
        return newAuto
      } catch (error) {
        console.warn('Duplicação via API falhou. Executando localmente.', error)
        // TODO: replace mock
        const source = this.automations.find(a => a.id === id)
        if (!source) return null

        const mockCopy = {
          ...source,
          id: Date.now(),
          name: `${source.name} (Cópia)`,
          active: false,
          trigger_count: 0,
          last_triggered_at: null
        }
        this.automations.push(mockCopy)
        return mockCopy
      } finally {
        this.loading.mutation = false
      }
    },

    // Salva ou atualiza a automação (Criada ou Editada)
    async saveAutomation(pipelineId, automationData) {
      this.loading.mutation = true
      try {
        let response
        if (automationData.id) {
          response = await api.patch(`/api/v1/pipelines/${pipelineId}/automations/${automationData.id}`, automationData)
        } else {
          response = await api.post(`/api/v1/pipelines/${pipelineId}/automations`, automationData)
        }
        const saved = response.data.data || response.data
        
        const idx = this.automations.findIndex(a => a.id === saved.id)
        if (idx !== -1) {
          this.automations[idx] = saved
        } else {
          this.automations.push(saved)
        }
        return saved
      } catch (error) {
        console.warn('Erro ao salvar automação via API. Simulando salvamento local.', error)
        // TODO: replace mock
        if (automationData.id) {
          const idx = this.automations.findIndex(a => a.id === automationData.id)
          if (idx !== -1) {
            this.automations[idx] = {
              ...this.automations[idx],
              ...automationData
            }
            return this.automations[idx]
          }
        } else {
          const newAuto = {
            ...automationData,
            id: Date.now(),
            pipeline_id: Number(pipelineId),
            active: true,
            trigger_count: 0,
            last_triggered_at: null
          }
          this.automations.push(newAuto)
          return newAuto
        }
      } finally {
        this.loading.mutation = false
      }
    }
  }
})
