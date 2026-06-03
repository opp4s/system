<template>
  <div class="h-screen flex bg-gray-50 overflow-hidden font-sans">
    <!-- Sidebar para Desktop -->
    <Sidebar class="hidden md:flex h-full" />

    <!-- Sidebar Drawer para Mobile -->
    <div v-if="mobileSidebarOpen" class="fixed inset-0 z-50 md:hidden flex">
      <!-- Backdrop -->
      <div @click="mobileSidebarOpen = false" class="fixed inset-0 bg-slate-900/60 backdrop-blur-sm transition-opacity duration-200"></div>
      
      <!-- Gaveta Lateral -->
      <div class="relative flex flex-col w-60 h-full bg-[#1E1E2E] shadow-2xl transition-transform duration-200">
        <Sidebar class="h-full border-r-0" :force-expand="true" />
      </div>
    </div>

    <!-- Main Content Container -->
    <div class="flex-1 flex flex-col min-w-0 overflow-hidden">
      <!-- Topbar clara -->
      <header class="h-16 bg-white border-b border-gray-100 flex items-center justify-between px-6 shrink-0 z-10">
        <div class="flex items-center space-x-4">
          <!-- Botão Toggle para Mobile -->
          <button @click="mobileSidebarOpen = true" class="md:hidden p-2 text-gray-500 hover:text-gray-700 hover:bg-gray-100 rounded-xl transition-all duration-150">
            <component :is="Menu" class="h-6 w-6" />
          </button>
          
          <!-- Breadcrumbs -->
          <div class="text-sm font-medium text-gray-500 flex items-center space-x-2">
            <span>Zavy</span>
            <span class="text-gray-300">/</span>
            <span class="text-gray-900 font-semibold capitalize">{{ currentRouteName }}</span>
          </div>
        </div>

        <div class="flex items-center space-x-4">
          <!-- Busca Global (Placeholder) -->
          <div class="relative hidden sm:block">
            <component :is="Search" class="absolute left-3 top-2.5 h-4 w-4 text-gray-400" />
            <input type="text" placeholder="Buscar no CRM..." class="w-64 pl-9 pr-4 py-2 text-sm rounded-xl border border-gray-200 focus:outline-none focus:border-zavy-500 focus:ring-1 focus:ring-zavy-500 bg-gray-50/50" />
          </div>

          <!-- Ícone de Notificações -->
          <button class="relative p-2 text-gray-400 hover:text-gray-600 hover:bg-gray-50 rounded-xl transition-all duration-150">
            <component :is="Bell" class="h-5 w-5" />
            <span class="absolute top-1.5 right-1.5 h-2 w-2 bg-rose-500 rounded-full ring-2 ring-white"></span>
          </button>

          <!-- Divisor -->
          <div class="h-6 w-px bg-gray-200"></div>

          <!-- Avatar e Perfil do Usuário com Dropdown -->
          <div class="relative">
            <button @click="profileDropdownOpen = !profileDropdownOpen" class="flex items-center space-x-2.5 p-1.5 hover:bg-gray-50 rounded-xl transition-all duration-150">
              <div class="h-8 w-8 rounded-lg bg-zavy-500 text-white flex items-center justify-center font-bold text-sm shadow-sm uppercase">
                {{ userInitials }}
              </div>
              <span class="hidden md:inline text-sm font-semibold text-gray-700">{{ userName }}</span>
              <component :is="ChevronDown" class="h-4 w-4 text-gray-400" />
            </button>

            <!-- Dropdown Menu -->
            <div v-if="profileDropdownOpen" class="absolute right-0 mt-2 w-48 bg-white border border-gray-100 rounded-2xl shadow-xl py-2 z-50">
              <button class="w-full text-left px-4 py-2 text-sm text-gray-700 hover:bg-gray-50 flex items-center space-x-2">
                <component :is="User" class="h-4 w-4 text-gray-400" />
                <span>Meu Perfil</span>
              </button>
              <button @click="handleLogout" class="w-full text-left px-4 py-2 text-sm text-rose-600 hover:bg-rose-50/50 flex items-center space-x-2">
                <component :is="LogOut" class="h-4 w-4 text-rose-500" />
                <span>Sair</span>
              </button>
            </div>
          </div>
        </div>
      </header>

      <!-- Content Area -->
      <main class="flex-1 overflow-y-auto p-6 md:p-8 bg-slate-50/50">
        <router-view />
      </main>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import Sidebar from '@/components/Sidebar.vue'
import { useAuth } from '@/composables/useAuth'
import { useAuthStore } from '@/stores/auth'
import { 
  Menu, 
  Search, 
  Bell, 
  ChevronDown, 
  User, 
  LogOut 
} from 'lucide-vue-next'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()
const { currentUser } = useAuth()

const mobileSidebarOpen = ref(false)
const profileDropdownOpen = ref(false)

const currentRouteName = computed(() => {
  return route.name || ''
})

const userName = computed(() => {
  return currentUser.value?.name || 'Usuário Zavy'
})

const userInitials = computed(() => {
  const name = currentUser.value?.name || 'U'
  return name.substring(0, 1).toUpperCase()
})

const handleLogout = () => {
  authStore.logout()
  router.push({ name: 'login' })
}
</script>
