<template>
  <div class="relative w-full">
    <!-- Botão Seletor Principal -->
    <button 
      @click="isDropdownOpen = !isDropdownOpen"
      class="w-full flex items-center rounded-xl bg-slate-800/30 hover:bg-slate-800/60 border border-slate-850 transition-all duration-150 text-left focus:outline-none"
      :class="isCollapsed ? 'justify-center p-2' : 'justify-between p-2.5'"
    >
      <div class="flex items-center min-w-0" :class="isCollapsed ? '' : 'space-x-3'">
        <!-- Avatar Workspace Ativo (Iniciais) -->
        <div class="h-8 w-8 rounded-lg bg-zavy-600 text-white flex items-center justify-center font-bold text-sm shrink-0 uppercase">
          {{ getInitials(workspaceStore.currentWorkspace.name) }}
        </div>
        <div v-if="!isCollapsed" class="min-w-0">
          <p class="text-xs font-semibold text-white truncate">{{ workspaceStore.currentWorkspace.name }}</p>
          <p class="text-[10px] text-slate-500 truncate">Plano {{ workspaceStore.currentWorkspace.plan }}</p>
        </div>
      </div>
      <component :is="ChevronDown" v-if="!isCollapsed" class="h-4 w-4 text-slate-500 shrink-0 ml-1" />
    </button>

    <!-- Dropdown Menu -->
    <div 
      v-if="isDropdownOpen" 
      class="absolute bg-[#252538] border border-slate-800 rounded-xl shadow-2xl py-2 z-50 overflow-hidden"
      :class="isCollapsed ? 'bottom-0 left-16 w-48' : 'bottom-14 left-0 w-full'"
    >
      <div class="px-3 py-1.5 text-[10px] font-semibold text-slate-500 uppercase tracking-wider">
        Seus Workspaces
      </div>
      
      <!-- Lista de Workspaces -->
      <div class="max-h-40 overflow-y-auto mt-1 px-1.5 space-y-0.5">
        <button
          v-for="w in workspaceStore.workspaces"
          :key="w.id"
          @click="selectWorkspace(w.id)"
          class="w-full flex items-center justify-between p-2 rounded-lg text-left text-xs font-medium transition-colors focus:outline-none"
          :class="w.id === workspaceStore.currentWorkspaceId 
            ? 'bg-zavy-500/15 text-zavy-400 font-semibold' 
            : 'text-slate-400 hover:bg-slate-800/50 hover:text-slate-200'"
        >
          <span class="truncate">{{ w.name }}</span>
          <component :is="Check" v-if="w.id === workspaceStore.currentWorkspaceId" class="h-3.5 w-3.5 text-zavy-500 shrink-0 ml-2" />
        </button>
      </div>

      <div class="border-t border-slate-800/80 my-2"></div>
      
      <!-- Botão Criar Novo -->
      <div class="px-1.5">
        <button
          @click="openCreateModal"
          class="w-full flex items-center space-x-2 p-2 rounded-lg text-xs font-medium text-slate-400 hover:bg-slate-800/50 hover:text-slate-200 transition-colors focus:outline-none"
        >
          <component :is="Plus" class="h-4 w-4 text-slate-500" />
          <span>Criar novo workspace</span>
        </button>
      </div>
    </div>

    <!-- Modal de Criação (Overlay) -->
    <div 
      v-if="isModalOpen" 
      class="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-slate-950/60 backdrop-blur-sm transition-all duration-200"
    >
      <div 
        @click.stop
        class="bg-white rounded-3xl max-w-sm w-full p-6 shadow-2xl border border-gray-100 space-y-4 text-gray-900"
      >
        <div>
          <h3 class="text-lg font-bold text-gray-900">Novo Workspace</h3>
          <p class="text-xs text-gray-500 mt-1">Crie um novo ambiente de trabalho para seus leads e automações.</p>
        </div>

        <div>
          <label class="block text-xs font-semibold text-gray-505 mb-1">Nome do Workspace</label>
          <input 
            v-model="newWorkspaceName"
            type="text"
            required
            placeholder="Ex: Minha Empresa"
            class="block w-full px-4 py-2.5 rounded-xl border border-gray-200 focus:outline-none focus:border-zavy-500 focus:ring-1 focus:ring-zavy-500 sm:text-xs bg-gray-50/50"
            @keyup.enter="handleCreateWorkspace"
            :disabled="isCreating"
          />
        </div>

        <div class="flex items-center space-x-3 pt-2">
          <button 
            @click="isModalOpen = false"
            class="flex-1 px-4 py-2.5 border border-gray-250 hover:bg-gray-50 rounded-xl text-xs font-semibold text-gray-650 transition-colors focus:outline-none"
            :disabled="isCreating"
          >
            Cancelar
          </button>
          <button 
            @click="handleCreateWorkspace"
            class="flex-1 flex justify-center items-center px-4 py-2.5 bg-zavy-600 hover:bg-zavy-700 text-white rounded-xl text-xs font-semibold shadow-md transition-all focus:outline-none disabled:opacity-50"
            :disabled="isCreating || !newWorkspaceName.trim()"
          >
            <!-- Spinner -->
            <svg v-if="isCreating" class="animate-spin -ml-1 mr-2 h-4 w-4 text-white" fill="none" viewBox="0 0 24 24">
              <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
              <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
            </svg>
            <span>{{ isCreating ? 'Criando...' : 'Criar' }}</span>
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useWorkspaceStore } from '@/stores/workspace'
import { useUiStore } from '@/stores/ui'
import { useToast } from '@/composables/useToast'
import { ChevronDown, Check, Plus } from 'lucide-vue-next'

const props = defineProps({
  forceExpand: {
    type: Boolean,
    default: false
  }
})

const workspaceStore = useWorkspaceStore()
const uiStore = useUiStore()
const toast = useToast()

const isCollapsed = computed(() => {
  return uiStore.sidebarCollapsed && !props.forceExpand
})

const isDropdownOpen = ref(false)
const isModalOpen = ref(false)
const isCreating = ref(false)
const newWorkspaceName = ref('')

const getInitials = (name) => {
  if (!name) return 'W'
  const parts = name.trim().split(' ')
  if (parts.length > 1) {
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase()
  }
  return name.substring(0, 2).toUpperCase()
}

const selectWorkspace = (id) => {
  workspaceStore.switchWorkspace(id)
  isDropdownOpen.value = false
  toast.info(`Workspace alterado para: ${workspaceStore.currentWorkspace.name}`)
}

const openCreateModal = () => {
  newWorkspaceName.value = ''
  isDropdownOpen.value = false
  isModalOpen.value = true
}

const handleCreateWorkspace = async () => {
  if (!newWorkspaceName.value.trim() || isCreating.value) return

  isCreating.value = true
  try {
    const created = await workspaceStore.createWorkspace(newWorkspaceName.value)
    toast.success(`Workspace "${created.name}" criado com sucesso!`)
    isModalOpen.value = false
  } catch (error) {
    toast.error(error.message || 'Falha ao criar workspace.')
  } finally {
    isCreating.value = false
  }
}
</script>
