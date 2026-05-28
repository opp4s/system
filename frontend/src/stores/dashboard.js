import { defineStore } from 'pinia'
import api from '@/plugins/axios'

// Mocks ricos para fallbacks de desenvolvimento do Dashboard
const MOCK_DASHBOARD_DATA = {
  '30d': {
    kpis: {
      active_leads: 184,
      pipeline_value: 384500,
      won_this_month: 98000,
      conversion_rate: 22.8
    },
    activities: [
      { id: 1, type: 'card_moved', text: 'Ana Souza moveu "Consultoria Nuvem" para Proposta Apresentada', created_at: '2026-05-28T12:30:00Z' },
      { id: 2, type: 'card_created', text: 'Lead "Imobiliária Prime" criado no pipeline comercial', created_at: '2026-05-28T11:15:00Z' },
      { id: 3, type: 'message_received', text: 'Mensagem recebida de Roberto Dias (WhatsApp)', created_at: '2026-05-28T10:45:00Z' },
      { id: 4, type: 'card_won', text: 'João Agente ganhou o negócio "Licenciamento SAP" (R$ 15.000,00)', created_at: '2026-05-27T17:20:00Z' },
      { id: 5, type: 'card_moved', text: 'Ana Souza moveu "Academia Fit" para Negociação', created_at: '2026-05-27T14:10:00Z' },
      { id: 6, type: 'task_created', text: 'Tarefa criada para Carlos Consultor: "Follow-up Proposta"', created_at: '2026-05-27T09:00:00Z' },
      { id: 7, type: 'card_lost', text: 'Lead "Lojas Americanas" perdido por motivo "Preço Alto"', created_at: '2026-05-26T16:30:00Z' },
      { id: 8, type: 'message_sent', text: 'Mensagem enviada para Carlos Souza (WhatsApp)', created_at: '2026-05-26T11:00:00Z' },
      { id: 9, type: 'card_moved', text: 'Mariana Gerente moveu "Indústria Metal" para Triagem', created_at: '2026-05-25T15:45:00Z' },
      { id: 10, type: 'card_won', text: 'Carlos Consultor ganhou o negócio "Treinamento In-company"', created_at: '2026-05-25T10:15:00Z' }
    ],
    pipelines_summary: [
      {
        id: 1,
        name: 'Funil de Vendas Padrão',
        total_leads: 124,
        stages: [
          { name: 'Triagem', count: 40, percentage: 32 },
          { name: 'Qualificado', count: 35, percentage: 28 },
          { name: 'Proposta', count: 25, percentage: 20 },
          { name: 'Negociação', count: 18, percentage: 15 },
          { name: 'Ganho', count: 6, percentage: 5 }
        ]
      },
      {
        id: 2,
        name: 'Pós-Venda & Retenção',
        total_leads: 60,
        stages: [
          { name: 'Kickoff', count: 15, percentage: 25 },
          { name: 'Implementação', count: 25, percentage: 42 },
          { name: 'Adoção', count: 12, percentage: 20 },
          { name: 'Sucesso', count: 8, percentage: 13 }
        ]
      }
    ],
    funnel: [
      { name: 'Triagem', count: 184, conversion_rate: 100 },
      { name: 'Qualificados', count: 142, conversion_rate: 77.1 },
      { name: 'Proposta Apresentada', count: 96, conversion_rate: 52.1 },
      { name: 'Negociação Ativa', count: 54, conversion_rate: 29.3 },
      { name: 'Ganhos', count: 42, conversion_rate: 22.8 }
    ],
    agents: [
      { id: 10001, name: 'João Agente', avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=100&h=100&q=80', cards_won: 15, value_won: 45000, avg_time_days: 12 },
      { id: 10002, name: 'Ana Souza', avatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=100&h=100&q=80', cards_won: 12, value_won: 36000, avg_time_days: 14 },
      { id: 10003, name: 'Carlos Consultor', avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=100&h=100&q=80', cards_won: 8, value_won: 24000, avg_time_days: 10 },
      { id: 10004, name: 'Mariana Gerente', avatar: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=100&h=100&q=80', cards_won: 7, value_won: 28000, avg_time_days: 9 }
    ]
  },
  '7d': {
    kpis: {
      active_leads: 154,
      pipeline_value: 312000,
      won_this_month: 25000,
      conversion_rate: 18.5
    },
    activities: [
      { id: 1, type: 'card_moved', text: 'Ana Souza moveu "Consultoria Nuvem" para Proposta Apresentada', created_at: '2026-05-28T12:30:00Z' },
      { id: 2, type: 'card_created', text: 'Lead "Imobiliária Prime" criado no pipeline comercial', created_at: '2026-05-28T11:15:00Z' },
      { id: 3, type: 'message_received', text: 'Mensagem recebida de Roberto Dias (WhatsApp)', created_at: '2026-05-28T10:45:00Z' }
    ],
    pipelines_summary: [
      {
        id: 1,
        name: 'Funil de Vendas Padrão',
        total_leads: 100,
        stages: [
          { name: 'Triagem', count: 30, percentage: 30 },
          { name: 'Qualificado', count: 30, percentage: 30 },
          { name: 'Proposta', count: 20, percentage: 20 },
          { name: 'Negociação', count: 15, percentage: 15 },
          { name: 'Ganho', count: 5, percentage: 5 }
        ]
      }
    ],
    funnel: [
      { name: 'Triagem', count: 154, conversion_rate: 100 },
      { name: 'Qualificados', count: 110, conversion_rate: 71.4 },
      { name: 'Proposta Apresentada', count: 64, conversion_rate: 41.5 },
      { name: 'Negociação Ativa', count: 35, conversion_rate: 22.7 },
      { name: 'Ganhos', count: 25, conversion_rate: 16.2 }
    ],
    agents: [
      { id: 10001, name: 'João Agente', avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=100&h=100&q=80', cards_won: 5, value_won: 15000, avg_time_days: 10 },
      { id: 10002, name: 'Ana Souza', avatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=100&h=100&q=80', cards_won: 4, value_won: 12000, avg_time_days: 12 }
    ]
  }
}

export const useDashboardStore = defineStore('dashboard', {
  state: () => ({
    kpis: {
      active_leads: 0,
      pipeline_value: 0,
      won_this_month: 0,
      conversion_rate: 0
    },
    activities: [],
    pipelinesSummary: [],
    funnel: [],
    agents: [],
    loading: false
  }),

  actions: {
    // Carrega todas as métricas do Dashboard
    async fetchDashboardMetrics(period = '30d') {
      this.loading = true
      try {
        // GET /api/v1/dashboard?period=30d
        const response = await api.get('/api/v1/dashboard', { params: { period } })
        const data = response.data.data || response.data
        
        this.kpis = data.kpis || this.kpis
        this.activities = data.activities || []
        this.pipelinesSummary = data.pipelines_summary || []
        this.funnel = data.funnel || []
        this.agents = data.agents || []
      } catch (error) {
        console.warn(`GET /api/v1/dashboard?period=${period} falhou. Usando fallback mockado.`, error)
        // Se a API falhar, carrega do mock local
        const data = MOCK_DASHBOARD_DATA[period] || MOCK_DASHBOARD_DATA['30d']
        
        this.kpis = { ...data.kpis }
        this.activities = [...data.activities]
        this.pipelinesSummary = [...data.pipelines_summary]
        this.funnel = [...data.funnel]
        this.agents = [...data.agents]
      } finally {
        this.loading = false
      }
    }
  }
})
