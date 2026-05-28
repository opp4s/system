import { useUiStore } from '@/stores/ui'

export function useToast() {
  const uiStore = useUiStore()

  const success = (message, duration) => {
    uiStore.addToast(message, 'success', duration)
  }

  const error = (message, duration) => {
    uiStore.addToast(message, 'error', duration)
  }

  const info = (message, duration) => {
    uiStore.addToast(message, 'info', duration)
  }

  const warning = (message, duration) => {
    uiStore.addToast(message, 'warning', duration)
  }

  return {
    success,
    error,
    info,
    warning,
    toasts: uiStore.toasts
  }
}
