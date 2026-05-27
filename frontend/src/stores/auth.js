import { defineStore } from 'pinia'

export const useAuthStore = defineStore('auth', {
  state: () => ({
    user: null,
    token: null,
  }),
  actions: {
    // Simulação de login com atraso de rede
    async login(email, password) {
      await new Promise((resolve) => setTimeout(resolve, 1000))

      if (email === 'erro@zavycrm.com') {
        throw new Error('E-mail ou senha incorretos.')
      }

      const mockToken = 'mocked_jwt_token_zavy_crm_2026'
      const mockUser = {
        id: 1,
        name: 'Carlos Zavy',
        email: email,
        role: 'admin',
        avatar: null
      }

      this.token = mockToken
      this.user = mockUser

      return { user: mockUser, token: mockToken }
    },

    // Simulação de cadastro com auto-login
    async register(name, email, password) {
      await new Promise((resolve) => setTimeout(resolve, 1000))

      if (email === 'erro@zavycrm.com') {
        throw new Error('Este e-mail já está sendo utilizado.')
      }

      const mockToken = 'mocked_jwt_token_new_user'
      const mockUser = {
        id: 2,
        name: name,
        email: email,
        role: 'admin',
        avatar: null
      }

      this.token = mockToken
      this.user = mockUser

      return { user: mockUser, token: mockToken }
    },

    // Ação de logout limpando estados e dados persistidos
    logout() {
      this.token = null
      this.user = null
      localStorage.removeItem('auth')
      localStorage.removeItem('workspace')
    },

    // Simulação de envio de recuperação de senha
    async forgotPassword(email) {
      await new Promise((resolve) => setTimeout(resolve, 800))
      
      if (email === 'erro@zavycrm.com') {
        throw new Error('E-mail não cadastrado.')
      }
      
      return true
    },

    // Simulação de redefinição de senha
    async resetPassword(token, password) {
      await new Promise((resolve) => setTimeout(resolve, 1000))
      
      if (token === 'expirado') {
        throw new Error('O link de recuperação expirou. Solicite um novo.')
      }
      
      return true
    }
  },
  persist: true
})
