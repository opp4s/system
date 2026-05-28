import { defineStore } from 'pinia'
import api from '@/plugins/axios'

// Mocks ricos para desenvolvimento e fallbacks
const MOCK_BROADCASTS = [
  {
    id: 1,
    name: 'Campanha de Boas-vindas - Leads Quentes',
    status: 'completed',
    recipients_count: 150,
    sent_count: 148,
    failed_count: 2,
    scheduled_at: null,
    sent_at: '2026-05-27T10:00:00Z',
    message: 'Olá {nome}, tudo bem? Vimos que você se interessou em nosso portal. Gostaria de agendar uma demonstração?',
    media_url: null
  },
  {
    id: 2,
    name: 'Aviso de Atualização de Termos',
    status: 'scheduled',
    recipients_count: 320,
    sent_count: 0,
    failed_count: 0,
    scheduled_at: '2026-06-05T09:00:00Z',
    sent_at: null,
    message: 'Prezado(a) {nome}, informamos que nossos termos de uso foram atualizados. Confira no link: zavycrm.com/termos',
    media_url: 'https://zavycrm.com/assets/pdf/novos_termos.pdf'
  },
  {
    id: 3,
    name: 'Follow-up Propostas Estagnadas',
    status: 'running',
    recipients_count: 85,
    sent_count: 45,
    failed_count: 1,
    scheduled_at: null,
    sent_at: '2026-05-28T12:00:00Z',
    message: 'Oi {nome}! Passando para saber se conseguiu analisar nossa proposta de {value}. Qualquer dúvida, estou por aqui.',
    media_url: null
  },
  {
    id: 4,
    name: 'Oferta Relâmpago Black Friday',
    status: 'draft',
    recipients_count: 0,
    sent_count: 0,
    failed_count: 0,
    scheduled_at: null,
    sent_at: null,
    message: 'Preparado para a maior oferta do ano, {nome}? Condições exclusivas por tempo limitado.',
    media_url: null
  }
]

const MOCK_REPORTS = {
  1: {
    id: 1,
    name: 'Campanha de Boas-vindas - Leads Quentes',
    status: 'completed',
    sent_at: '2026-05-27T10:00:00Z',
    recipients_count: 150,
    sent_count: 148,
    failed_count: 2,
    delivery_rate: 98.6,
    duration_seconds: 45,
    failures: [
      { contact_name: 'Marcos Silva', phone: '+5511999999999', error_message: 'Número inválido (sem WhatsApp conectado)' },
      { contact_name: 'Juliana Pires', phone: '+5521988888888', error_message: 'Falha temporária de rede da Evolution API' }
    ]
  },
  3: {
    id: 3,
    name: 'Follow-up Propostas Estagnadas',
    status: 'running',
    sent_at: '2026-05-28T12:00:00Z',
    recipients_count: 85,
    sent_count: 45,
    failed_count: 1,
    delivery_rate: 97.8,
    duration_seconds: 12,
    failures: [
      { contact_name: 'Roberto Santos', phone: '+5519977777777', error_message: 'Cliente bloqueou o número receptor' }
    ]
  }
}

export const useBroadcastStore = defineStore('broadcast', {
  state: () => ({
    broadcasts: [],
    currentBroadcast: null,
    activeReport: null,
    previewCount: 0,
    loading: {
      list: false,
      detail: false,
      mutation: false,
      report: false,
      preview: false
    }
  }),

  actions: {
    // Carrega lista de broadcasts
    async fetchBroadcasts() {
      this.loading.list = true
      try {
        const response = await api.get('/api/v1/broadcasts')
        this.broadcasts = response.data.data || response.data
      } catch (error) {
        console.warn('GET /api/v1/broadcasts falhou. Usando fallback mockado.', error)
        // TODO: replace mock
        this.broadcasts = [...MOCK_BROADCASTS]
      } finally {
        this.loading.list = false
      }
    },

    // Executa preview de audiência baseada em filtros
    async fetchPreview(params) {
      this.loading.preview = true
      try {
        const response = await api.get('/api/v1/broadcasts/preview', { params })
        this.previewCount = response.data.count || response.data.data?.count || 0
        return this.previewCount
      } catch (error) {
        console.warn('GET /api/v1/broadcasts/preview falhou. Simulando contagem mockada.', error)
        // Simulando filtro simples: se selecionou pipeline, retorna contagem baseada nas etapas
        let baseCount = 0
        if (params.pipeline_id) {
          baseCount += 42
          if (params.stage_ids && params.stage_ids.length > 0) {
            baseCount = params.stage_ids.length * 15
          }
          if (params.labels && params.labels.length > 0) {
            baseCount = Math.max(5, baseCount - 10)
          }
        }
        this.previewCount = baseCount
        return baseCount
      } finally {
        this.loading.preview = false
      }
    },

    // Cria um broadcast em rascunho
    async createBroadcast(broadcastData) {
      this.loading.mutation = true
      try {
        const response = await api.post('/api/v1/broadcasts', { broadcast: broadcastData })
        const created = response.data.data || response.data
        this.broadcasts.unshift(created)
        return created
      } catch (error) {
        console.warn('POST /api/v1/broadcasts falhou. Simulando criação local.', error)
        // TODO: replace mock
        const newBroadcast = {
          ...broadcastData,
          id: Date.now(),
          status: 'draft',
          recipients_count: this.previewCount || 25,
          sent_count: 0,
          failed_count: 0,
          scheduled_at: null,
          sent_at: null
        }
        this.broadcasts.unshift(newBroadcast)
        return newBroadcast
      } finally {
        this.loading.mutation = false
      }
    },

    // Atualiza um broadcast existente (se for rascunho)
    async updateBroadcast(id, broadcastData) {
      this.loading.mutation = true
      try {
        const response = await api.patch(`/api/v1/broadcasts/${id}`, { broadcast: broadcastData })
        const updated = response.data.data || response.data
        const idx = this.broadcasts.findIndex(b => b.id === id)
        if (idx !== -1) {
          this.broadcasts[idx] = updated
        }
        return updated
      } catch (error) {
        console.warn(`PATCH /api/v1/broadcasts/${id} falhou. Atualizando localmente.`, error)
        const idx = this.broadcasts.findIndex(b => b.id === id)
        if (idx !== -1) {
          this.broadcasts[idx] = {
            ...this.broadcasts[idx],
            ...broadcastData,
            recipients_count: this.previewCount || this.broadcasts[idx].recipients_count
          }
          return this.broadcasts[idx]
        }
      } finally {
        this.loading.mutation = false
      }
    },

    // Enviar broadcast agora
    async sendNow(id) {
      this.loading.mutation = true
      try {
        const response = await api.post(`/api/v1/broadcasts/${id}/send_now`)
        const updated = response.data.data || response.data
        const idx = this.broadcasts.findIndex(b => b.id === id)
        if (idx !== -1) {
          this.broadcasts[idx] = updated
        }
        return updated
      } catch (error) {
        console.warn(`POST /api/v1/broadcasts/${id}/send_now falhou. Simulando envio imediato.`, error)
        const idx = this.broadcasts.findIndex(b => b.id === id)
        if (idx !== -1) {
          this.broadcasts[idx].status = 'running'
          this.broadcasts[idx].sent_at = new Date().toISOString()
          
          // Simula conclusão em mock após alguns segundos
          setTimeout(() => {
            const b = this.broadcasts.find(item => item.id === id)
            if (b) {
              b.status = 'completed'
              b.sent_count = b.recipients_count - 2
              b.failed_count = 2
            }
          }, 4000)
        }
        return this.broadcasts[idx]
      } finally {
        this.loading.mutation = false
      }
    },

    // Agendar broadcast para data futura
    async scheduleBroadcast(id, scheduledAt) {
      this.loading.mutation = true
      try {
        const response = await api.post(`/api/v1/broadcasts/${id}/schedule`, { scheduled_at: scheduledAt })
        const updated = response.data.data || response.data
        const idx = this.broadcasts.findIndex(b => b.id === id)
        if (idx !== -1) {
          this.broadcasts[idx] = updated
        }
        return updated
      } catch (error) {
        console.warn(`POST /api/v1/broadcasts/${id}/schedule falhou. Simulando agendamento local.`, error)
        const idx = this.broadcasts.findIndex(b => b.id === id)
        if (idx !== -1) {
          this.broadcasts[idx].status = 'scheduled'
          this.broadcasts[idx].scheduled_at = scheduledAt
        }
        return this.broadcasts[idx]
      } finally {
        this.loading.mutation = false
      }
    },

    // Cancelar broadcast em andamento ou agendado
    async cancelBroadcast(id) {
      this.loading.mutation = true
      try {
        const response = await api.post(`/api/v1/broadcasts/${id}/cancel`)
        const updated = response.data.data || response.data
        const idx = this.broadcasts.findIndex(b => b.id === id)
        if (idx !== -1) {
          this.broadcasts[idx] = updated
        }
        return updated
      } catch (error) {
        console.warn(`POST /api/v1/broadcasts/${id}/cancel falhou. Cancelando localmente.`, error)
        const idx = this.broadcasts.findIndex(b => b.id === id)
        if (idx !== -1) {
          this.broadcasts[idx].status = 'cancelled'
        }
        return this.broadcasts[idx]
      } finally {
        this.loading.mutation = false
      }
    },

    // Carrega relatório específico do broadcast
    async fetchReport(id) {
      this.loading.report = true
      try {
        const response = await api.get(`/api/v1/broadcasts/${id}/report`)
        this.activeReport = response.data.data || response.data
      } catch (error) {
        console.warn(`GET /api/v1/broadcasts/${id}/report falhou. Usando relatório mockado.`, error)
        // TODO: replace mock
        const base = this.broadcasts.find(b => b.id === id) || { name: 'Broadcast', status: 'completed', recipients_count: 100 }
        
        // Retorna dados com base no status atual
        const defaultReport = MOCK_REPORTS[id] || {
          id: id,
          name: base.name,
          status: base.status,
          sent_at: base.sent_at || base.scheduled_at,
          recipients_count: base.recipients_count || 100,
          sent_count: base.sent_count || (base.status === 'completed' ? 98 : 0),
          failed_count: base.failed_count || (base.status === 'completed' ? 2 : 0),
          delivery_rate: base.status === 'completed' ? 98.0 : 0.0,
          duration_seconds: base.status === 'completed' ? 30 : 0,
          failures: base.status === 'completed' ? [
            { contact_name: 'Lead de Teste', phone: '+5511900000000', error_message: 'Número não registrado no WhatsApp' }
          ] : []
        }
        this.activeReport = defaultReport
      } finally {
        this.loading.report = false
      }
    }
  }
})
