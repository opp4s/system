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
      custom_fields: { 'WhatsApp': '+55 11 99999-9999', 'Origem': 'Google Search' },
      conversation_id: 123
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
    cardTimeline: [],
    customFields: [],
    showFinalStages: true,
    filters: {
      user: '',
      valueMin: null,
      valueMax: null,
      daysMin: null,
      daysMax: null,
      stageType: ''
    },
    loading: {
      pipelines: false,
      stages: false,
      cards: false,
      timeline: false,
      mutation: false,
      customFields: false
    }
  }),

  getters: {
    currentPipeline: (state) => {
      return state.pipelines.find(p => p.id === state.currentPipelineId) || null
    },

    // Retorna a lista de cartões filtrados baseado nas regras de negócio de filtros
    filteredCards: (state) => {
      return state.cards.filter(card => {
        // Filtro por Responsável (Agente)
        if (state.filters.user) {
          const cardUser = card.user?.name || ''
          if (!cardUser.toLowerCase().includes(state.filters.user.toLowerCase())) {
            return false
          }
        }
        // Filtro por Valor Mínimo
        if (state.filters.valueMin !== null && state.filters.valueMin !== '') {
          if (card.value < Number(state.filters.valueMin)) {
            return false
          }
        }
        // Filtro por Valor Máximo
        if (state.filters.valueMax !== null && state.filters.valueMax !== '') {
          if (card.value > Number(state.filters.valueMax)) {
            return false
          }
        }
        // Filtro por Dias na Etapa Mínimo
        if (state.filters.daysMin !== null && state.filters.daysMin !== '') {
          if (card.days_in_stage < Number(state.filters.daysMin)) {
            return false
          }
        }
        // Filtro por Dias na Etapa Máximo
        if (state.filters.daysMax !== null && state.filters.daysMax !== '') {
          if (card.days_in_stage > Number(state.filters.daysMax)) {
            return false
          }
        }
        // Filtro por Tipo de Etapa
        if (state.filters.stageType) {
          const stage = state.stages.find(s => s.id === card.stage_id)
          if (!stage || stage.stage_type !== state.filters.stageType) {
            return false
          }
        }
        return true
      })
    },

    // Agrupa os cards filtrados em um objeto reativo cujas chaves são os IDs das etapas
    cardsByStage: (state) => {
      const grouped = {}
      // Inicializa todas as etapas com array vazio para garantir reatividade
      state.stages.forEach(stage => {
        grouped[stage.id] = []
      })
      // Distribui os cards filtrados nas suas etapas correspondentes
      state.filteredCards.forEach(card => {
        if (grouped[card.stage_id] !== undefined) {
          grouped[card.stage_id].push(card)
        } else {
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
    },

    activeFiltersCount: (state) => {
      let count = 0
      if (state.filters.user) count++
      if (state.filters.valueMin !== null && state.filters.valueMin !== '') count++
      if (state.filters.valueMax !== null && state.filters.valueMax !== '') count++
      if (state.filters.daysMin !== null && state.filters.daysMin !== '') count++
      if (state.filters.daysMax !== null && state.filters.daysMax !== '') count++
      if (state.filters.stageType) count++
      return count
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
        this.pipelines = []; console.error("Erro ao carregar pipelines:", error)
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
        const fetched = response.data.data || response.data
        // Normaliza stage_type para o front-end (lost -> lose, won -> win)
        this.stages = fetched.map(stage => ({
          ...stage,
          stage_type: stage.stage_type === 'lost' ? 'lose' : (stage.stage_type === 'won' ? 'win' : stage.stage_type)
        }))
      } catch (error) {
        console.warn(`Erro ao carregar etapas do pipeline ${pipelineId} da API. Usando dados mockados.`, error)
        this.stages = []; console.error("Erro ao carregar stages:", error)
      } finally {
        this.loading.stages = false
      }
    },

    // Busca os cards do pipeline
    async fetchCards(pipelineId) {
      this.loading.cards = true
      try {
        const response = await api.get(`/api/v1/pipelines/${pipelineId}/cards`)
        const newCards = response.data.data || response.data
        this.cards = newCards.map(newCard => {
          const existing = this.cards.find(c => c.id === newCard.id)
          return existing ? { ...existing, ...newCard } : newCard
        })
      } catch (error) {
        console.warn(`Erro ao carregar cards do pipeline ${pipelineId} da API. Usando dados mockados.`, error)
        this.cards = []; console.error("Erro ao carregar cards:", error)
      } finally {
        this.loading.cards = false
      }
    },

    // Busca os detalhes de um único card (incluindo whatsapp_instance)
    async fetchCardDetail(pipelineId, cardId) {
      try {
        const response = await api.get(`/api/v1/pipelines/${pipelineId}/cards/${cardId}`)
        const detailedCard = response.data.data || response.data
        const index = this.cards.findIndex(c => c.id === Number(cardId))
        if (index !== -1) {
          this.cards[index] = { ...this.cards[index], ...detailedCard }
        } else {
          this.cards.push(detailedCard)
        }
        return detailedCard
      } catch (error) {
        console.error(`Erro ao carregar detalhes do card ${cardId}:`, error)
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
    },

    // Busca a timeline de atividades de um card
    async fetchCardTimeline(pipelineId, cardId) {
      this.loading.timeline = true
      this.cardTimeline = []
      try {
        const response = await api.get(`/api/v1/pipelines/${pipelineId}/cards/${cardId}/timeline`)
        this.cardTimeline = response.data.data || response.data
      } catch (error) {
        console.warn(`Erro ao buscar timeline do card ${cardId}. Usando dados mockados.`, error)
        // TODO: replace mock with real api when endpoint is ready
        this.cardTimeline = [
          {
            id: 1,
            event_type: 'card_created',
            title: 'Negócio Criado',
            description: 'O negócio foi registrado no sistema.',
            created_at: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000).toISOString(),
            user: { name: 'João Agente' }
          },
          {
            id: 2,
            event_type: 'card_moved',
            title: 'Etapa Alterada',
            description: 'Negócio movido para a etapa Qualificado.',
            created_at: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000).toISOString(),
            user: { name: 'Ana Souza' }
          },
          {
            id: 10,
            event_type: 'message',
            message_type: 'incoming',
            content: 'Olá! Gostaria de agendar uma demonstração da ferramenta para nosso time.',
            created_at: new Date(Date.now() - 4 * 60 * 60 * 1000).toISOString(),
            sender_name: 'Carlos Souza'
          },
          {
            id: 11,
            event_type: 'message',
            message_type: 'outgoing',
            content: 'Com certeza, Carlos! Temos horários disponíveis amanhã às 14h ou 16h. Qual fica melhor?',
            created_at: new Date(Date.now() - 3.5 * 60 * 60 * 1000).toISOString(),
            user: { name: 'João Agente' }
          },
          {
            id: 12,
            event_type: 'message',
            message_type: 'private',
            content: 'Cliente muito receptivo. Interessado no plano Enterprise (20 licenças).',
            created_at: new Date(Date.now() - 3 * 60 * 60 * 1000).toISOString(),
            user: { name: 'João Agente' }
          },
          {
            id: 3,
            event_type: 'card_updated',
            title: 'Campos Atualizados',
            description: 'Informações do contato principal foram atualizadas.',
            created_at: new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString(),
            user: { name: 'João Agente' }
          },
          {
            id: 13,
            event_type: 'message',
            message_type: 'incoming',
            content: 'Perfeito, amanhã às 14h está ótimo para nós. Pode enviar o link do convite?',
            created_at: new Date(Date.now() - 10 * 60 * 1000).toISOString(),
            sender_name: 'Carlos Souza'
          }
        ]
      } finally {
        this.loading.timeline = false
      }
    },

    // Atualiza dados de um card (como custom_fields ou título)
    async updateCard(cardId, cardData) {
      this.loading.mutation = true
      try {
        const response = await api.patch(`/api/v1/pipelines/${this.currentPipelineId}/cards/${cardId}`, {
          card: cardData
        })
        const updatedCard = response.data.data || response.data
        const index = this.cards.findIndex(c => c.id === cardId)
        if (index !== -1) {
          this.cards[index] = { ...this.cards[index], ...updatedCard }
        }
        return updatedCard
      } catch (error) {
        console.warn(`Erro ao atualizar card ${cardId} na API. Sincronizando alterações localmente.`, error)
        // Fallback local se a API falhar ou não estiver pronta
        const index = this.cards.findIndex(c => c.id === cardId)
        if (index !== -1) {
          this.cards[index] = { ...this.cards[index], ...cardData }
        }
        return this.cards[index]
      } finally {
        this.loading.mutation = false
      }
    },

    // Ações de Filtros
    setFilters(filters) {
      this.filters = { ...this.filters, ...filters }
    },

    clearFilters() {
      this.filters = {
        user: '',
        valueMin: null,
        valueMax: null,
        daysMin: null,
        daysMax: null,
        stageType: ''
      }
    },

    // CRUD e Reordenação de Pipelines/Estágios
    async reorderPipelines(ids) {
      try {
        await api.post('/api/v1/pipelines/reorder', { pipeline_ids: ids })
        // Atualiza a ordenação local também
        const reordered = []
        ids.forEach(id => {
          const pipeline = this.pipelines.find(p => p.id === id)
          if (pipeline) reordered.push(pipeline)
        })
        this.pipelines = reordered
      } catch (error) {
        console.error('Erro ao reordenar pipelines', error)
        throw error
      }
    },

    async reorderStages(pipelineId, ids) {
      try {
        await api.post(`/api/v1/pipelines/${pipelineId}/stages/reorder`, { stage_ids: ids })
        // Atualiza a ordenação local
        const reordered = []
        ids.forEach(id => {
          const stage = this.stages.find(s => s.id === id)
          if (stage) reordered.push(stage)
        })
        this.stages = reordered
      } catch (error) {
        console.error('Erro ao reordenar etapas', error)
        throw error
      }
    },

    async updateStage(pipelineId, stageId, stageData) {
      const apiData = { ...stageData }
      if (apiData.stage_type) {
        apiData.stage_type = apiData.stage_type === 'lose' ? 'lost' : (apiData.stage_type === 'win' ? 'won' : apiData.stage_type)
      }
      try {
        const response = await api.patch(`/api/v1/pipelines/${pipelineId}/stages/${stageId}`, { stage: apiData })
        const updatedStage = response.data.data || response.data
        const mappedStage = {
          ...updatedStage,
          stage_type: updatedStage.stage_type === 'lost' ? 'lose' : (updatedStage.stage_type === 'won' ? 'win' : updatedStage.stage_type)
        }
        const index = this.stages.findIndex(s => s.id === stageId)
        if (index !== -1) {
          this.stages[index] = mappedStage
        }
        return mappedStage
      } catch (error) {
        console.error('Erro ao atualizar etapa', error)
        // Fallback local
        const index = this.stages.findIndex(s => s.id === stageId)
        if (index !== -1) {
          this.stages[index] = { ...this.stages[index], ...stageData }
        }
        throw error
      }
    },

    async createPipeline(pipelineData) {
      try {
        const response = await api.post('/api/v1/pipelines', { pipeline: pipelineData })
        const newPipeline = response.data.data || response.data
        this.pipelines.push(newPipeline)
        return newPipeline
      } catch (error) {
        console.error('Erro ao criar pipeline', error)
        const mockNew = {
          id: Date.now(),
          ...pipelineData,
          stages: []
        }
        this.pipelines.push(mockNew)
        return mockNew
      }
    },

    async updatePipeline(pipelineId, pipelineData) {
      try {
        const response = await api.patch(`/api/v1/pipelines/${pipelineId}`, { pipeline: pipelineData })
        const updated = response.data.data || response.data
        const index = this.pipelines.findIndex(p => p.id === pipelineId)
        if (index !== -1) {
          this.pipelines[index] = { ...this.pipelines[index], ...updated }
        }
        return updated
      } catch (error) {
        console.error('Erro ao atualizar pipeline', error)
        const index = this.pipelines.findIndex(p => p.id === pipelineId)
        if (index !== -1) {
          this.pipelines[index] = { ...this.pipelines[index], ...pipelineData }
        }
        throw error
      }
    },

    async deletePipeline(pipelineId) {
      try {
        await api.delete(`/api/v1/pipelines/${pipelineId}`)
        this.pipelines = this.pipelines.filter(p => p.id !== pipelineId)
      } catch (error) {
        console.error('Erro ao deletar pipeline', error)
        this.pipelines = this.pipelines.filter(p => p.id !== pipelineId)
        throw error
      }
    },

    async createStage(pipelineId, stageData) {
      const apiData = { ...stageData }
      if (apiData.stage_type) {
        apiData.stage_type = apiData.stage_type === 'lose' ? 'lost' : (apiData.stage_type === 'win' ? 'won' : apiData.stage_type)
      }
      try {
        const response = await api.post(`/api/v1/pipelines/${pipelineId}/stages`, { stage: apiData })
        const newStage = response.data.data || response.data
        const mappedStage = {
          ...newStage,
          stage_type: newStage.stage_type === 'lost' ? 'lose' : (newStage.stage_type === 'won' ? 'win' : newStage.stage_type)
        }
        this.stages.push(mappedStage)
        return mappedStage
      } catch (error) {
        console.error('Erro ao criar etapa', error)
        const mockNew = {
          id: Date.now(),
          pipeline_id: pipelineId,
          ...stageData
        }
        this.stages.push(mockNew)
        return mockNew
      }
    },

    async deleteStage(pipelineId, stageId) {
      try {
        await api.delete(`/api/v1/pipelines/${pipelineId}/stages/${stageId}`)
        this.stages = this.stages.filter(s => s.id !== stageId)
      } catch (error) {
        console.error('Erro ao deletar etapa', error)
        this.stages = this.stages.filter(s => s.id !== stageId)
        throw error
      }
    },

    async sendMessage(cardId, content, isPrivate) {
      this.loading.mutation = true
      try {
        const response = await api.post(`/api/v1/cards/${cardId}/messages`, {
          message: {
            content: content,
            private_note: isPrivate
          }
        })
        const newMessage = response.data.data || response.data
        const exists = this.cardTimeline.some(item => item.id === newMessage.id)
        if (!exists) {
          this.cardTimeline.push(newMessage)
        }
        return newMessage
      } catch (error) {
        console.warn(`Erro ao enviar mensagem para o card ${cardId}. Utilizando fallback local.`, error)
        
        // Mock fallback local reativo (optimistic update)
        const mockMsg = {
          id: Date.now(),
          event_type: 'message',
          message_type: isPrivate ? 'private' : 'outgoing',
          content: content,
          created_at: new Date().toISOString(),
          user: { name: 'João Agente' }
        }
        
        this.cardTimeline.push(mockMsg)
        
        // Dispara o evento de scroll reativo
        const customEvent = new CustomEvent('zavy-new-message', { detail: mockMsg })
        window.dispatchEvent(customEvent)
        
        return mockMsg
      } finally {
        this.loading.mutation = false
      }
    },

    async linkConversation(cardId, conversationId) {
      this.loading.mutation = true
      try {
        const response = await api.post(`/api/v1/cards/${cardId}/link_conversation`, {
          conversation_id: conversationId
        })
        
        const cardIdx = this.cards.findIndex(c => c.id === cardId)
        if (cardIdx !== -1) {
          this.cards[cardIdx].conversation_id = conversationId
          this.cards[cardIdx].conversation = { id: conversationId }
        }
        
        return response.data?.data || response.data
      } catch (error) {
        console.warn(`Erro ao vincular conversa ${conversationId} no card ${cardId}. Utilizando fallback local.`, error)
        
        const cardIdx = this.cards.findIndex(c => c.id === cardId)
        if (cardIdx !== -1) {
          this.cards[cardIdx].conversation_id = conversationId
          this.cards[cardIdx].conversation = { id: conversationId }
        }
        
        if (error.response?.status === 404) {
          return { success: true }
        }
        throw error
      } finally {
        this.loading.mutation = false
      }
    },

    async unlinkConversation(cardId) {
      this.loading.mutation = true
      try {
        const response = await api.delete(`/api/v1/cards/${cardId}/unlink_conversation`)
        
        const cardIdx = this.cards.findIndex(c => c.id === cardId)
        if (cardIdx !== -1) {
          this.cards[cardIdx].conversation_id = null
          this.cards[cardIdx].conversation = null
        }
        
        return response.data?.data || response.data
      } catch (error) {
        console.warn(`Erro ao desvincular conversa do card ${cardId}. Utilizando fallback local.`, error)
        
        const cardIdx = this.cards.findIndex(c => c.id === cardId)
        if (cardIdx !== -1) {
          this.cards[cardIdx].conversation_id = null
          this.cards[cardIdx].conversation = null
        }
        
        if (error.response?.status === 404) {
          return { success: true }
        }
        throw error
      } finally {
        this.loading.mutation = false
      }
    },

    async fetchCustomFields(pipelineId) {
      this.loading.customFields = true
      try {
        const response = await api.get(`/api/v1/custom_fields?pipeline_id=${pipelineId}`)
        this.customFields = response.data.data || response.data
      } catch (error) {
        console.warn('Erro ao carregar campos personalizados da API. Usando localStorage ou padrão.', error)
        const local = localStorage.getItem(`zavy-custom-fields-${pipelineId}`)
        if (local) {
          this.customFields = JSON.parse(local)
        } else {
          this.customFields = [
            { id: 1, name: 'Empresa', field_type: 'text', options: [] },
            { id: 2, name: 'Origem do Lead', field_type: 'select', options: ['Google Search', 'Indicação', 'Redes Sociais', 'Outro'] },
            { id: 3, name: 'Necessita Contrato?', field_type: 'boolean', options: [] },
            { id: 4, name: 'Data da Demonstração', field_type: 'date', options: [] }
          ]
          localStorage.setItem(`zavy-custom-fields-${pipelineId}`, JSON.stringify(this.customFields))
        }
      } finally {
        this.loading.customFields = false
      }
    },

    async createCustomField(pipelineId, fieldData) {
      try {
        const response = await api.post(`/api/v1/custom_fields`, {
          pipeline_id: pipelineId,
          custom_field: fieldData
        })
        const newField = response.data.data || response.data
        this.customFields.push(newField)
        localStorage.setItem(`zavy-custom-fields-${pipelineId}`, JSON.stringify(this.customFields))
        return newField
      } catch (error) {
        console.warn('Erro ao criar campo personalizado na API. Criando localmente.', error)
        const newField = {
          id: Date.now(),
          ...fieldData
        }
        this.customFields.push(newField)
        localStorage.setItem(`zavy-custom-fields-${pipelineId}`, JSON.stringify(this.customFields))
        return newField
      }
    },

    async updateCustomField(pipelineId, fieldId, fieldData) {
      try {
        const response = await api.patch(`/api/v1/custom_fields/${fieldId}`, {
          custom_field: fieldData
        })
        const updated = response.data.data || response.data
        const index = this.customFields.findIndex(cf => cf.id === fieldId)
        if (index !== -1) {
          this.customFields[index] = { ...this.customFields[index], ...updated }
        }
        localStorage.setItem(`zavy-custom-fields-${pipelineId}`, JSON.stringify(this.customFields))
        return updated
      } catch (error) {
        console.warn('Erro ao atualizar campo personalizado na API. Sincronizando localmente.', error)
        const index = this.customFields.findIndex(cf => cf.id === fieldId)
        if (index !== -1) {
          this.customFields[index] = { ...this.customFields[index], ...fieldData }
        }
        localStorage.setItem(`zavy-custom-fields-${pipelineId}`, JSON.stringify(this.customFields))
        return this.customFields[index]
      }
    },

    async deleteCustomField(pipelineId, fieldId) {
      try {
        await api.delete(`/api/v1/custom_fields/${fieldId}`)
        this.customFields = this.customFields.filter(cf => cf.id !== fieldId)
        localStorage.setItem(`zavy-custom-fields-${pipelineId}`, JSON.stringify(this.customFields))
      } catch (error) {
        console.warn('Erro ao deletar campo personalizado na API. Deletando localmente.', error)
        this.customFields = this.customFields.filter(cf => cf.id !== fieldId)
        localStorage.setItem(`zavy-custom-fields-${pipelineId}`, JSON.stringify(this.customFields))
      }
    }
  }
})
