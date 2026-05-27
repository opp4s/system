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

    <!-- Workspace Switcher no Rodapé (Placeholder) -->
    <div class="p-3 border-t border-slate-800/80 bg-slate-900/20">
      <button class="w-full flex items-center justify-between p-2.5 rounded-xl bg-slate-800/30 hover:bg-slate-800/60 border border-slate-850 transition-all duration-150 text-left">
        <div class="flex items-center space-x-3 min-w-0">
          <div class="h-8 w-8 rounded-lg bg-zavy-600 text-white flex items-center justify-center font-bold text-sm shrink-0">
            ZW
          </div>
          <div class="min-w-0">
            <p class="text-xs font-semibold text-white truncate">Workspace Principal</p>
            <p class="text-[10px] text-slate-500 truncate">Plano Pro</p>
          </div>
        </div>
        <component :is="ChevronDown" class="h-4 w-4 text-slate-500 shrink-0 ml-1" />
      </button>
    </div>
  </aside>
</template>

<script setup>
import { ref } from 'vue'
import { useRoute } from 'vue-router'
import { 
  LayoutDashboard, 
  GitFork, 
  Users, 
  Radio, 
  Zap, 
  Settings, 
  ChevronDown 
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
