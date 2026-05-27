import { defineStore } from 'pinia'

export const useUiStore = defineStore('ui', {
  state: () => ({
    toasts: []
  }),
  actions: {
    // Adiciona um toast e agenda a remoção automática
    addToast(message, type = 'success', duration = 4000) {
      const id = Date.now().toString(36) + Math.random().toString(36).substr(2, 5)
      this.toasts.push({ id, message, type })

      setTimeout(() => {
        this.removeToast(id)
      }, duration)
    },

    // Remove o toast imediatamente pelo ID
    removeToast(id) {
      this.toasts = this.toasts.filter((toast) => toast.id !== id)
    }
  }
})
