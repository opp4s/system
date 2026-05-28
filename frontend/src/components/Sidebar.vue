<template>
  <aside 
    class="bg-[#1E1E2E] text-slate-300 flex flex-col h-full border-r border-slate-800 shrink-0 transition-all duration-300"
    :class="isCollapsed ? 'w-20' : 'w-60'"
  >
    <!-- Header / Logo -->
    <div class="h-16 flex items-center justify-between px-4 border-b border-slate-800/80">
      <div class="flex items-center space-x-2 text-white font-extrabold text-xl overflow-hidden">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-zavy-500 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M13 10V3L4 14h7v7l9-11h-7z" />
        </svg>
        <span v-if="!isCollapsed" class="tracking-tight transition-all duration-200">
          Zavy<span class="text-zavy-500">.</span>
        </span>
      </div>
      
      <!-- Botão Toggle de Desktop -->
      <button 
        @click="uiStore.toggleSidebar"
        class="hidden md:block text-slate-500 hover:text-slate-300 transition-colors focus:outline-none"
      >
        <svg v-if="isCollapsed" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
        </svg>
        <svg v-else class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
        </svg>
      </button>
    </div>

    <!-- Navegação -->
    <nav class="flex-1 px-3 py-4 space-y-1 overflow-y-auto">
      <router-link
        v-for="item in menuItems"
        :key="item.path"
        :to="item.path"
        class="flex items-center rounded-xl text-sm font-medium transition-all duration-150"
        :class="[
          isActive(item.path) 
            ? 'bg-zavy-500/10 text-zavy-400 font-semibold' 
            : 'text-slate-400 hover:bg-slate-800/40 hover:text-slate-200',
          isCollapsed ? 'justify-center p-3' : 'space-x-3 px-4 py-3'
        ]"
        :title="isCollapsed ? item.name : ''"
      >
        <component :is="item.icon" class="h-5 w-5 shrink-0" />
        <span v-if="!isCollapsed" class="truncate">{{ item.name }}</span>
      </router-link>
    </nav>

    <!-- Workspace Switcher no Rodapé -->
    <div class="p-3 border-t border-slate-800/80 bg-slate-900/20">
      <WorkspaceSwitcher :force-expand="forceExpand" />
    </div>
  </aside>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useRoute } from 'vue-router'
import { useUiStore } from '@/stores/ui'
import WorkspaceSwitcher from '@/components/WorkspaceSwitcher.vue'
import { 
  LayoutDashboard, 
  Columns3, 
  Users, 
  Radio, 
  Zap, 
  Settings
} from 'lucide-vue-next'

const props = defineProps({
  forceExpand: {
    type: Boolean,
    default: false
  }
})

const route = useRoute()
const uiStore = useUiStore()

const isCollapsed = computed(() => {
  return uiStore.sidebarCollapsed && !props.forceExpand
})

const menuItems = ref([
  { name: 'Dashboard', path: '/dashboard', icon: LayoutDashboard },
  { name: 'Pipelines', path: '/pipelines', icon: Columns3 },
  { name: 'Contatos', path: '/contacts', icon: Users },
  { name: 'Broadcast', path: '/broadcast', icon: Radio },
  { name: 'Automações', path: '/automations', icon: Zap },
  { name: 'Configurações', path: '/settings', icon: Settings },
])

const isActive = (path) => {
  return route.path === path
}
</script>
