import { defineStore } from 'pinia'
import api from '@/plugins/axios'

export const useWorkspaceStore = defineStore('workspace', {
  state: () => ({
    workspaces: [],
    currentWorkspaceId: null
  }),
  getters: {
    currentWorkspace: (state) => {
      return state.workspaces.find((w) => w.id === state.currentWorkspaceId) || state.workspaces[0] || { name: 'Carregando...', plan: 'Nenhum' }
    }
  },
  actions: {
    // Muda o workspace selecionado
    switchWorkspace(id) {
      const exists = this.workspaces.some((w) => w.id === id)
      if (exists) {
        this.currentWorkspaceId = id
      }
    },

    // Cria um novo workspace real via POST /api/v1/workspaces
    async createWorkspace(name) {
      if (!name.trim()) {
        throw new Error('O nome do workspace não pode estar vazio.')
      }

      const response = await api.post('/api/v1/workspaces', {
        workspace: { name }
      })

      const newWorkspace = response.data.data
      this.workspaces.push(newWorkspace)
      this.currentWorkspaceId = newWorkspace.id

      return newWorkspace
    },

    // Carrega a lista real de workspaces do servidor
    async fetchWorkspaces() {
      const response = await api.get('/api/v1/workspaces')
      this.workspaces = response.data.data

      if (this.workspaces.length > 0) {
        const exists = this.workspaces.some((w) => w.id === this.currentWorkspaceId)
        if (!exists) {
          this.currentWorkspaceId = this.workspaces[0].id
        }
      } else {
        this.currentWorkspaceId = null
      }

      return this.workspaces
    }
  },
  persist: true
})
