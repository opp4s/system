import { computed } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { useWorkspaceStore } from '@/stores/workspace'

export function useAuth() {
  const authStore = useAuthStore()
  const workspaceStore = useWorkspaceStore()

  const isLoggedIn = computed(() => !!authStore.token)
  const currentUser = computed(() => authStore.user)
  
  // Retorna a role (função) do usuário logado no workspace atual
  const currentRole = computed(() => {
    return workspaceStore.currentWorkspace?.role || 'membro'
  })

  return {
    isLoggedIn,
    currentUser,
    currentRole
  }
}
