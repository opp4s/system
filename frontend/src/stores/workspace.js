import { defineStore } from 'pinia'

export const useWorkspaceStore = defineStore('workspace', {
  state: () => ({
    workspaces: [
      { id: 1, name: 'Workspace Principal', role: 'admin', plan: 'Pro' },
      { id: 2, name: 'Workspace Secundário', role: 'membro', plan: 'Grátis' }
    ],
    currentWorkspaceId: 1
  }),
  getters: {
    currentWorkspace: (state) => {
      return state.workspaces.find((w) => w.id === state.currentWorkspaceId) || state.workspaces[0]
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

    // Cria um novo workspace simulado com atraso de rede
    async createWorkspace(name) {
      await new Promise((resolve) => setTimeout(resolve, 800))

      if (!name.trim()) {
        throw new Error('O nome do workspace não pode estar vazio.')
      }

      const newId = Date.now()
      const newWorkspace = {
        id: newId,
        name: name,
        role: 'admin',
        plan: 'Pro'
      }

      this.workspaces.push(newWorkspace)
      this.currentWorkspaceId = newId

      return newWorkspace
    },

    // Simulação de carregamento de workspaces do servidor
    async fetchWorkspaces() {
      await new Promise((resolve) => setTimeout(resolve, 600))
      return this.workspaces
    }
  },
  persist: true
})
