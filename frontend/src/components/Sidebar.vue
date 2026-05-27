<template>
  <aside class="w-60 bg-[#1E1E2E] text-slate-300 flex flex-col h-full border-r border-slate-800 shrink-0">
    <!-- Header / Logo -->
    <div class="h-16 flex items-center px-6 border-b border-slate-800/80">
      <div class="flex items-center space-x-2 text-white font-extrabold text-xl">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-zavy-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M13 10V3L4 14h7v7l9-11h-7z" />
        </svg>
        <span class="tracking-tight">Zavy<span class="text-zavy-500">.</span></span>
      </div>
    </div>

    <!-- Navegação -->
    <nav class="flex-1 px-3 py-4 space-y-1 overflow-y-auto">
      <router-link
        v-for="item in menuItems"
        :key="item.path"
        :to="item.path"
        class="flex items-center space-x-3 px-4 py-3 rounded-xl text-sm font-medium transition-all duration-150"
        :class="isActive(item.path) 
          ? 'bg-zavy-500/10 text-zavy-400 font-semibold' 
          : 'text-slate-400 hover:bg-slate-800/40 hover:text-slate-200'"
      >
        <component :is="item.icon" class="h-5 w-5" />
        <span>{{ item.name }}</span>
      </router-link>
    </nav>

    <!-- Workspace Switcher no Rodapé -->
    <div class="p-3 border-t border-slate-800/80 bg-slate-900/20">
      <WorkspaceSwitcher />
    </div>
  </aside>
</template>

<script setup>
import { ref } from 'vue'
import { useRoute } from 'vue-router'
import WorkspaceSwitcher from '@/components/WorkspaceSwitcher.vue'
import { 
  LayoutDashboard, 
  GitFork, 
  Users, 
  Radio, 
  Zap, 
  Settings
} from 'lucide-vue-next'

const route = useRoute()

const menuItems = ref([
  { name: 'Dashboard', path: '/dashboard', icon: LayoutDashboard },
  { name: 'Pipelines', path: '/pipelines', icon: GitFork },
  { name: 'Contatos', path: '/contacts', icon: Users },
  { name: 'Broadcast', path: '/broadcast', icon: Radio },
  { name: 'Automações', path: '/automations', icon: Zap },
  { name: 'Configurações', path: '/settings', icon: Settings },
])

const isActive = (path) => {
  return route.path === path
}
</script>
