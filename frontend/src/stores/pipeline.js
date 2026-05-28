import { defineStore } from 'pinia'
import api from '@/plugins/axios'

// Dados Mockados para fallback caso a API não esteja pronta
const MOCK_PIPELINES = [
  { id: 1, name: 'Funil de Vendas Principal', description: 'Funil para controle de leads comerciais', color: '#3B82F6' },
  { id: 2, name: 'Pós-Venda & Onboarding', description: 'Funil de acompanhamento de novos clientes', color: '#10B981' }
]

const MOCK_STAGES = {
  1: [
    { id: 101, pipeline_id: 1, name: 'Novo Lead', color: '#3B82F6', position: 1, stage_type: 'intermediate' },
    { id: 102, pipeline_id: 1, name: 'Qualificado', color: '#8B5CF6', position: 2, stage_type: 'intermediate' },
    { id: 103, pipeline_id: 1, name: 'Proposta Enviada', color: '#EAB308', position: 3, stage_type: 'intermediate' },
    { id: 104, pipeline_id: 1, name: 'Negociação', color: '#F97316', position: 4, stage_type: 'intermediate' },
    { id: 105, pipeline_id: 1, name: 'Fechado Ganho', color: '#10B981', position: 5, stage_type: 'win' },
    { id: 106, pipeline_id: 1, name: 'Fechado Perdido', color: '#EF4444', position: 6, stage_type: 'lose' }
  ],
  2: [
    { id: 201, pipeline_id: 2, name: 'Kickoff', color: '#3B82F6', position: 1, stage_type: 'intermediate' },
    { id: 202, pipeline_id: 2, name: 'Configuração', color: '#8B5CF6', position: 2, stage_type: 'intermediate' },
    { id: 203, pipeline_id: 2, name: 'Treinamento', color: '#EAB308', position: 3, stage_type: 'intermediate' },
    { id: 204, pipeline_id: 2, name: 'Em Produção', color: '#10B981', position: 4, stage_type: 'win' },
    { id: 205, pipeline_id: 2, name: 'Cancelado', color: '#EF4444', position: 5, stage_type: 'lose' }
  ]
}

const MOCK_CARDS = {
  1: [
    { 
      id: 1001, 
      stage_id: 101, 
      title: 'Consultoria de TI', 
      value: 15000, 
      currency: 'BRL', 
      contact_name: 'Carlos Souza', 
      contact_phone: '+55 11 99999-9999', 
      contact_email: 'carlos@souza.com', 
      days_in_stage: 2, 
      user: { name: 'João Agente', avatar: '' }, 
      labels: ['Alta Prioridade', 'Inbound'],
      custom_fields: { 'WhatsApp': '+55 11 99999-9999', 'Origem': 'Google Search' }
    },
    { 
      id: 1002, 
      stage_id: 102, 
      title: 'Licenciamento de Software', 
      value: 8500, 
      currency: 'BRL', 
      contact_name: 'Mariana Reis', 
      contact_phone: '+55 11 98888-8888', 
      contact_email: 'mariana@reis.com', 
      days_in_stage: 5, 
      user: { name: 'Ana Souza', avatar: '' }, 
      labels: ['Enterprise'],
      custom_fields: { 'WhatsApp': '+55 11 98888-8888', 'Empresa': 'Reis Tech' }
    },
    { 
      id: 1003, 
      stage_id: 103, 
      title: 'Desenvolvimento Web', 
      value: 45000, 
      currency: 'BRL', 
      contact_name: 'Pedro Lima', 
      contact_phone: '+55 11 97777-7777', 
      contact_email: 'pedro@lima.com', 
      days_in_stage: 1, 
      user: { name: 'João Agente', avatar: '' }, 
      labels: ['Urgente'],
      custom_fields: { 'WhatsApp': '+55 11 97777-7777', 'Tecnologias': 'Vue, Rails' }
    }
  ],
  2: [
    { 
      id: 2001, 
      stage_id: 201, 
      title: 'Setup Zavy CRM', 
      value: 5000, 
      currency: 'BRL', 
      contact_name: 'Roberto Dias', 
      contact_phone: '+55 11 96666-6666', 
      contact_email: 'roberto@dias.com', 
      days_in_stage: 3, 
      user: { name: 'Ana Souza', avatar: '' }, 
      labels: ['Setup Inicial'],
      custom_fields: { 'Responsável Técnico': 'Bruno Silva' }
    }
  ]
}

export const usePipelineStore = defineStore('pipeline', {
  state: () => ({
    pipelines: [],
    currentPipelineId: null,
    stages: [],
    cards: [],
    showFinalStages: true,
    loading: {
      pipelines: false,
      stages: false,
      cards: false,
      mutation: false
    }
  }),

  getters: {
    currentPipeline: (state) => {
      return state.pipelines.find(p => p.id === state.currentPipelineId) || null
    },

    // Agrupa os cards em um objeto reativo cujas chaves são os IDs das etapas e os valores são arrays de cards correspondentes
    cardsByStage: (state) => {
      const grouped = {}
      // Inicializa todas as etapas com array vazio para garantir reatividade
      state.stages.forEach(stage => {
        grouped[stage.id] = []
      })
      // Distribui os cards nas suas etapas correspondentes
      state.cards.forEach(card => {
        if (grouped[card.stage_id] !== undefined) {
          grouped[card.stage_id].push(card)
        } else {
          // Se por acaso o card pertencer a um stage_id que não está na lista de stages,
          // inicializa o array dinamicamente
          grouped[card.stage_id] = [card]
        }
      })
      return grouped
    },

    visibleStages: (state) => {
      if (!state.showFinalStages) {
        return state.stages.filter(s => s.stage_type === 'intermediate')
      }
      return state.stages
    }
  },

  actions: {
    // Busca todos os pipelines
    async fetchPipelines() {
      this.loading.pipelines = true
      try {
        // Tenta chamada real de API
        const response = await api.get('/api/v1/pipelines')
        this.pipelines = response.data.data || response.data
      } catch (error) {
        console.warn('Erro ao carregar pipelines da API. Usando dados mockados.', error)
        this.pipelines = MOCK_PIPELINES
      } finally {
        this.loading.pipelines = false
      }
    },

    // Seleciona um pipeline e dispara o carregamento de etapas e cards
    async selectPipeline(pipelineId) {
      this.currentPipelineId = pipelineId
      this.showFinalStages = true
      await Promise.all([
        this.fetchStages(pipelineId),
        this.fetchCards(pipelineId)
      ])
    },

    // Busca as etapas do pipeline
    async fetchStages(pipelineId) {
      this.loading.stages = true
      try {
        const response = await api.get(`/api/v1/pipelines/${pipelineId}/stages`)
        this.stages = response.data.data || response.data
      } catch (error) {
        console.warn(`Erro ao carregar etapas do pipeline ${pipelineId} da API. Usando dados mockados.`, error)
        this.stages = MOCK_STAGES[pipelineId] || []
      } finally {
        this.loading.stages = false
      }
    },

    // Busca os cards do pipeline
    async fetchCards(pipelineId) {
      this.loading.cards = true
      try {
        const response = await api.get(`/api/v1/pipelines/${pipelineId}/cards`)
        this.cards = response.data.data || response.data
      } catch (error) {
        console.warn(`Erro ao carregar cards do pipeline ${pipelineId} da API. Usando dados mockados.`, error)
        this.cards = MOCK_CARDS[pipelineId] || []
      } finally {
        this.loading.cards = false
      }
    },

    // Move um card entre etapas (com atualização otimista)
    async moveCard(cardId, fromStageId, toStageId, newIndex) {
      const cardIndex = this.cards.findIndex(c => c.id === cardId)
      if (cardIndex === -1) return

      // Guarda estado anterior para eventual rollback
      const originalStageId = this.cards[cardIndex].stage_id
      
      // Atualização otimista
      this.cards[cardIndex].stage_id = toStageId

      try {
        // Tenta chamada real à API
        await api.post(`/api/v1/pipelines/${this.currentPipelineId}/cards/${cardId}/move`, {
          stage_id: toStageId,
          position: newIndex
        })
      } catch (error) {
        console.error('Falha ao mover card na API. Efetuando rollback.', error)
        // Rollback se a API falhar
        const indexToRollback = this.cards.findIndex(c => c.id === cardId)
        if (indexToRollback !== -1) {
          this.cards[indexToRollback].stage_id = originalStageId
        }
        throw error
      }
    },

    // Cria um novo card
    async createCard(cardData) {
      this.loading.mutation = true
      try {
        const response = await api.post(`/api/v1/pipelines/${this.currentPipelineId}/cards`, {
          card: cardData
        })
        const newCard = response.data.data || response.data
        this.cards.push(newCard)
        return newCard
      } catch (error) {
        console.warn('Erro ao criar card na API. Adicionando card mockado localmente.', error)
        // Mock fallback
        const mockNewCard = {
          id: Date.now(),
          stage_id: cardData.stage_id,
          title: cardData.title,
          value: cardData.value || 0,
          currency: cardData.currency || 'BRL',
          contact_name: cardData.contact_name || '',
          contact_phone: cardData.contact_phone || '',
          contact_email: cardData.contact_email || '',
          days_in_stage: 0,
          user: { name: 'João Agente', avatar: '' },
          labels: [],
          custom_fields: {}
        }
        this.cards.push(mockNewCard)
        return mockNewCard
      } finally {
        this.loading.mutation = false
      }
    }
  }
})
