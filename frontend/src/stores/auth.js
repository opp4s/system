import { defineStore } from 'pinia'
import api from '@/plugins/axios'

export const useAuthStore = defineStore('auth', {
  state: () => ({
    user: null,
    token: null,
  }),
  actions: {
    // Login real enviando credenciais sob a chave 'user'
    async login(email, password) {
      const response = await api.post('/auth/login', {
        user: { email, password }
      })

      this.token = response.data.token
      this.user = response.data.data

      // Carrega informações completas de perfil e workspaces
      await this.fetchMe()

      return response.data
    },

    // Cadastro real com criação de workspace padrão no Rails
    async register(name, email, password) {
      const response = await api.post('/auth/register', {
        user: { 
          name, 
          email, 
          password, 
          password_confirmation: password 
        }
      })

      this.token = response.data.token
      this.user = response.data.data

      // Carrega informações completas de perfil e workspaces
      await this.fetchMe()

      return response.data
    },

    // Ação de logout real com revogação de token no servidor
    async logout() {
      try {
        if (this.token) {
          await api.delete('/auth/logout')
        }
      } catch (error) {
        console.error('Erro ao efetuar logout no servidor:', error)
      } finally {
        this.token = null
        this.user = null
        localStorage.removeItem('auth')
        localStorage.removeItem('workspace')
      }
    },

    // Envio de email para recuperação de senha
    async forgotPassword(email) {
      const response = await api.post('/auth/forgot_password', { email })
      return response.data
    },

    // Redefinição de senha com token recebido
    async resetPassword(token, password) {
      const response = await api.post('/auth/reset_password', {
        reset_password_token: token,
        password: password,
        password_confirmation: password
      })
      return response.data
    },

    // Carrega o usuário atual e popula a store de workspaces de forma síncrona
    async fetchMe() {
      if (!this.token) return null
      
      try {
        const response = await api.get('/api/v1/me')
        this.user = response.data.data

        // Importa dinamicamente a workspace store para evitar dependência circular
        const { useWorkspaceStore } = await import('./workspace')
        const workspaceStore = useWorkspaceStore()
        
        if (this.user.workspaces) {
          workspaceStore.workspaces = this.user.workspaces
          
          // Se houver workspaces mas nenhum selecionado estiver na lista, seleciona o primeiro
          if (workspaceStore.workspaces.length > 0) {
            const exists = workspaceStore.workspaces.some(w => w.id === workspaceStore.currentWorkspaceId)
            if (!exists) {
              workspaceStore.currentWorkspaceId = workspaceStore.workspaces[0].id
            }
          }
        }

        return this.user
      } catch (error) {
        if (error.response && error.response.status === 401) {
          // Token expirado ou inválido, limpa sessão local
          this.token = null
          this.user = null
          localStorage.removeItem('auth')
          localStorage.removeItem('workspace')
        }
        throw error
      }
    }
  },
  persist: true
})
