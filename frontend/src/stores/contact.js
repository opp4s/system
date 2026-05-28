import { defineStore } from 'pinia'
import api from '@/plugins/axios'
import { usePipelineStore } from './pipeline'

// Dados Mockados para fallback caso a API não esteja pronta
const MOCK_CONTACTS = [
  {
    id: 1,
    name: 'Carlos Souza',
    phone: '+55 11 99999-9999',
    email: 'carlos@souza.com',
    avatar: '',
    last_contact: 'Hoje às 14:32'
  },
  {
    id: 2,
    name: 'Mariana Reis',
    phone: '+55 11 98888-8888',
    email: 'mariana@reis.com',
    avatar: '',
    last_contact: 'Ontem às 10:15'
  },
  {
    id: 3,
    name: 'Pedro Lima',
    phone: '+55 11 97777-7777',
    email: 'pedro@lima.com',
    avatar: '',
    last_contact: '26/05/2026 às 16:45'
  },
  {
    id: 4,
    name: 'Roberto Dias',
    phone: '+55 11 96666-6666',
    email: 'roberto@dias.com',
    avatar: '',
    last_contact: '24/05/2026 às 11:20'
  },
  {
    id: 5,
    name: 'Júlia Fonseca',
    phone: '+55 21 98765-4321',
    email: 'julia.fonseca@outlook.com',
    avatar: '',
    last_contact: '22/05/2026 às 09:00'
  },
  {
    id: 6,
    name: 'Fernando Alencar',
    phone: '+55 31 99123-4567',
    email: 'fernando.alencar@empresa.com',
    avatar: '',
    last_contact: '18/05/2026 às 15:30'
  }
]

export const useContactStore = defineStore('contact', {
  state: () => ({
    contacts: [],
    selectedContact: null,
    loading: {
      list: false,
      detail: false,
      mutation: false
    }
  }),

  actions: {
    // Lista contatos
    async fetchContacts() {
      this.loading.list = true
      try {
        const response = await api.get('/api/v1/contacts')
        this.contacts = response.data.data || response.data
      } catch (error) {
        console.warn('Endpoint GET /api/v1/contacts não disponível. Usando fallback mockado.', error)
        // TODO: replace mock
        this.contacts = [...MOCK_CONTACTS]
      } finally {
        this.loading.list = false
      }
    },

    // Busca contatos com parâmetro de busca
    async searchContacts(query) {
      this.loading.list = true
      try {
        const response = await api.get(`/api/v1/contacts/search?q=${encodeURIComponent(query)}`)
        this.contacts = response.data.data || response.data
      } catch (error) {
        console.warn(`Endpoint GET /api/v1/contacts/search não disponível. Filtrando localmente.`, error)
        // TODO: replace mock
        if (!query.trim()) {
          this.contacts = [...MOCK_CONTACTS]
        } else {
          const lowerQuery = query.toLowerCase()
          this.contacts = MOCK_CONTACTS.filter(c => 
            c.name.toLowerCase().includes(lowerQuery) ||
            c.email.toLowerCase().includes(lowerQuery) ||
            c.phone.includes(lowerQuery)
          )
        }
      } finally {
        this.loading.list = false
      }
    },

    // Busca detalhes do contato, incluindo negócios e conversas vinculadas
    async fetchContactDetail(contactId) {
      this.loading.detail = true
      try {
        const response = await api.get(`/api/v1/contacts/${contactId}`)
        this.selectedContact = response.data.data || response.data
      } catch (error) {
        console.warn(`Endpoint GET /api/v1/contacts/${contactId} não disponível. Gerando detalhe mockado.`, error)
        
        // TODO: replace mock
        const contact = this.contacts.find(c => c.id === Number(contactId)) || 
                        MOCK_CONTACTS.find(c => c.id === Number(contactId))
        
        if (!contact) {
          this.selectedContact = null
          return
        }

        // Busca negócios (cards) correspondentes na pipeline store
        const pipelineStore = usePipelineStore()
        
        // Se a store de pipeline não estiver populada, populamos para poder ler os cards
        if (pipelineStore.cards.length === 0) {
          await pipelineStore.fetchCards(1) // carrega cards do pipeline principal (ou do atual)
        }
        
        const linkedCards = pipelineStore.cards.filter(c => 
          c.contact_name === contact.name || 
          c.contact_phone === contact.phone || 
          c.contact_email === contact.email
        )

        // Mock de conversas ativas do Chatwoot para esse contato
        const linkedConversations = []
        if (contact.id === 1) { // Carlos Souza tem uma conversa ativa como exemplo
          linkedConversations.push({
            id: 123,
            last_message: 'Olá! Consegue me mandar a proposta da consultoria?',
            channel: 'whatsapp',
            status: 'open',
            updated_at: new Date().toISOString()
          })
        } else if (contact.id === 2) {
          linkedConversations.push({
            id: 124,
            last_message: 'Obrigada! Vou analisar as licenças.',
            channel: 'whatsapp',
            status: 'open',
            updated_at: new Date(Date.now() - 3600000).toISOString()
          })
        }

        this.selectedContact = {
          ...contact,
          cards: linkedCards,
          conversations: linkedConversations
        }
      } finally {
        this.loading.detail = false
      }
    },

    // Cria um contato no backend (se houver API)
    async createContact(contactData) {
      this.loading.mutation = true
      try {
        const response = await api.post('/api/v1/contacts', contactData)
        const newContact = response.data.data || response.data
        this.contacts.unshift(newContact)
        return newContact
      } catch (error) {
        console.warn('Endpoint POST /api/v1/contacts não disponível. Simulando criação local.', error)
        // TODO: replace mock
        const newContact = {
          id: Date.now(),
          name: contactData.name,
          phone: contactData.phone,
          email: contactData.email,
          avatar: '',
          last_contact: 'Criado agora'
        }
        this.contacts.unshift(newContact)
        return newContact
      } finally {
        this.loading.mutation = false
      }
    }
  }
})
