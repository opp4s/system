import { defineStore } from 'pinia'
import api from '@/plugins/axios'

export const useChatwootStore = defineStore('chatwoot', {
  state: () => ({
    configured: false,
    chatwootUrl: 'https://chat.opp4s.com',
    accountId: '',
    apiToken: '',
    autoLinkEnabled: false,
    destinationPipelineId: null,
    destinationStageId: null,
    loading: false
  }),

  persist: {
    key: 'zavy-chatwoot-settings',
    storage: localStorage
  },

  actions: {
    // Carrega as configurações de Chatwoot do backend
    async fetchSettings() {
      this.loading = true
      try {
        const response = await api.get('/api/v1/chatwoot/status')
        const data = response.data.data || response.data
        this.configured = data.configured ?? false
        this.chatwootUrl = data.chatwoot_url || 'https://chat.opp4s.com'
        this.accountId = data.chatwoot_account_id || ''
        this.apiToken = data.api_token || ''
        if (data.settings) {
          this.autoLinkEnabled = data.settings.auto_create_card ?? false
          this.destinationPipelineId = data.settings.auto_create_pipeline_id || null
          this.destinationStageId = data.settings.auto_create_stage_id || null
        } else {
          this.autoLinkEnabled = data.auto_link_enabled ?? false
          this.destinationPipelineId = data.destination_pipeline_id || null
          this.destinationStageId = data.destination_stage_id || null
        }
      } catch (error) {
        console.warn('Endpoint GET /api/v1/chatwoot/status não disponível. Mantendo configurações locais.', error)
        // Mantém as configurações que estão no localStorage/state
      } finally {
        this.loading = false
      }
    },

    // Testa a conexão e configura o Chatwoot
    async configureChatwoot(configData) {
      this.loading = true
      try {
        // Tenta chamada real à API
        // POST /api/v1/chatwoot/configure
        const response = await api.post('/api/v1/chatwoot/configure', {
          chatwoot_url: configData.chatwootUrl,
          account_id: configData.accountId,
          api_token: configData.apiToken
        })
        
        this.chatwootUrl = configData.chatwootUrl
        this.accountId = configData.accountId
        this.apiToken = configData.apiToken
        this.configured = true
        
        return { success: true, message: response.data?.message || 'Conexão estabelecida com sucesso!' }
      } catch (error) {
        console.warn('Endpoint POST /api/v1/chatwoot/configure não disponível ou falhou. Usando simulação local.', error)
        
        // Se for um erro 404 (rota não existente), vamos simular sucesso no mock local
        if (error.response?.status === 404) {
          // TODO: replace mock with real api verification
          this.chatwootUrl = configData.chatwootUrl
          this.accountId = configData.accountId
          this.apiToken = configData.apiToken
          this.configured = true
          return { success: true, message: 'Conexão simulada com sucesso (API não pronta)!' }
        }
        
        this.configured = false
        throw error
      } finally {
        this.loading = false
      }
    },

    // Atualiza as configurações de auto-link
    async updateSettings(settingsData) {
      this.loading = true
      try {
        // PATCH /api/v1/chatwoot/settings
        const response = await api.patch('/api/v1/chatwoot/settings', {
          settings: {
            auto_create_card: settingsData.autoLinkEnabled,
            auto_create_pipeline_id: settingsData.destinationPipelineId,
            auto_create_stage_id: settingsData.destinationStageId
          }
        })
        
        this.autoLinkEnabled = settingsData.autoLinkEnabled
        this.destinationPipelineId = settingsData.destinationPipelineId
        this.destinationStageId = settingsData.destinationStageId
        
        return response.data?.data || response.data
      } catch (error) {
        console.warn('Endpoint PATCH /api/v1/chatwoot/settings não disponível. Salvando localmente.', error)
        
        // Simulação local
        this.autoLinkEnabled = settingsData.autoLinkEnabled
        this.destinationPipelineId = settingsData.destinationPipelineId
        this.destinationStageId = settingsData.destinationStageId
        
        if (error.response?.status === 404) {
          return { success: true }
        }
        throw error
      } finally {
        this.loading = false
      }
    },

    // Desconecta a conta do Chatwoot localmente e na API
    async disconnectChatwoot() {
      this.loading = true
      try {
        // Se houver endpoint para isso, ou redefinir via configure/settings
        await api.patch('/api/v1/chatwoot/settings', {
          settings: { configured: false }
        })
      } catch (error) {
        console.warn('Falha ao notificar desconexão na API. Redefinindo localmente.', error)
      } finally {
        this.configured = false
        this.accountId = ''
        this.apiToken = ''
        this.autoLinkEnabled = false
        this.destinationPipelineId = null
        this.destinationStageId = null
        this.loading = false
      }
    }
  }
})
