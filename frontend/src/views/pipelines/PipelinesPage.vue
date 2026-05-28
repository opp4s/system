<template>
  <div class="flex h-[calc(100vh-4rem)] overflow-hidden bg-gray-50/50">
    <!-- Sidebar Interna (Lista de Pipelines) -->
    <aside class="w-64 bg-white border-r border-gray-200 flex flex-col shrink-0 h-full">
      <!-- Header da Sidebar Interna -->
      <div class="p-4 border-b border-gray-100 flex items-center justify-between">
        <div class="flex items-center space-x-2">
          <span class="text-sm font-bold text-gray-800 uppercase tracking-wider">Pipelines</span>
          <span class="px-2 py-0.5 text-xs font-semibold bg-zavy-50 text-zavy-600 rounded-full">
            {{ pipelineStore.pipelines.length }}
          </span>
        </div>
        <!-- Ajustes de Funil no Header -->
        <router-link
          to="/pipelines/settings"
          class="p-1.5 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-xl transition-all duration-150"
          title="Ajustes de Funil"
        >
          <component :is="Settings" class="h-4 w-4" />
        </router-link>
      </div>

      <!-- Lista de Pipelines -->
      <div class="flex-1 overflow-y-auto p-3 flex flex-col justify-between">
        <div class="space-y-1">
          <!-- Skeleton Loader quando carregando pipelines -->
          <div v-if="pipelineStore.loading.pipelines" class="space-y-2">
            <div v-for="i in 2" :key="i" class="h-11 bg-gray-100 rounded-xl animate-pulse"></div>
          </div>

          <template v-else>
            <button
              v-for="pipeline in pipelineStore.pipelines"
              :key="pipeline.id"
              @click="navigateToPipeline(pipeline.id)"
              class="w-full flex items-center justify-between px-4 py-3 rounded-xl text-left text-sm font-medium transition-all duration-200"
              :class="[
                pipelineStore.currentPipelineId === pipeline.id
                  ? 'bg-slate-900 text-white shadow-md shadow-slate-900/10'
                  : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'
              ]"
            >
              <div class="flex items-center space-x-3 truncate">
                <!-- Indicador de cor do pipeline -->
                <span 
                  class="w-2.5 h-2.5 rounded-full shrink-0" 
                  :style="{ backgroundColor: pipeline.color || '#3B82F6' }"
                ></span>
                <span class="truncate font-semibold">{{ pipeline.name }}</span>
              </div>
              
              <component 
                :is="ChevronRight" 
                class="h-4 w-4 shrink-0 opacity-60" 
                :class="pipelineStore.currentPipelineId === pipeline.id ? 'text-white' : 'text-gray-400'"
              />
            </button>
          </template>
        </div>

        <!-- Botão Novo Pipeline (sempre visível no fim da lista) -->
        <button 
          @click="showNewPipelineModal = true" 
          class="w-full flex items-center justify-center space-x-2 px-3 py-2.5 mt-4 rounded-xl text-xs font-semibold text-zavy-600 hover:text-zavy-700 hover:bg-zavy-50 border border-dashed border-zavy-300 transition-all duration-205 shrink-0"
        >
          <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
          </svg>
          <span>Novo Pipeline</span>
        </button>
      </div>
    </aside>

    <!-- Área Principal do Kanban -->
    <div class="flex-1 flex flex-col min-w-0 bg-[#F8FAFC]">
      <!-- Header do Painel Principal -->
      <header class="bg-white border-b border-gray-200 px-6 py-4 flex flex-col sm:flex-row sm:items-center sm:justify-between space-y-3 sm:space-y-0 shrink-0 shadow-sm">
        <!-- Título / Infos do Pipeline -->
        <div class="truncate">
          <div class="flex items-center space-x-2">
            <!-- Modo de Edição Inline -->
            <input
              v-if="isEditingName"
              ref="nameInputRef"
              v-model="editingName"
              @blur="savePipelineName"
              @keyup.enter="savePipelineName"
              @keyup.esc="isEditingName = false"
              type="text"
              class="text-xl font-bold text-gray-900 border-b-2 border-slate-900 focus:outline-none bg-transparent px-1 py-0.5 max-w-[250px]"
            />
            <!-- Modo Leitura -->
            <h1 
              v-else
              @click="startEditingName"
              class="text-xl font-bold text-gray-900 truncate cursor-pointer hover:bg-gray-100 rounded px-1 transition-colors flex items-center gap-1 group"
              title="Clique para editar nome do funil"
            >
              {{ pipelineStore.currentPipeline?.name || 'Carregando funil...' }}
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-gray-400 opacity-0 group-hover:opacity-100 transition-opacity shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z" />
              </svg>
            </h1>
            <!-- Cor do pipeline -->
            <span 
              v-if="pipelineStore.currentPipeline"
              class="w-3 h-3 rounded-full shrink-0" 
              :style="{ backgroundColor: pipelineStore.currentPipeline.color || '#3B82F6' }"
            ></span>
          </div>
          <p class="text-xs text-gray-500 truncate mt-0.5">
            {{ pipelineStore.currentPipeline?.description || 'Gerencie seus leads e oportunidades de vendas.' }}
          </p>
        </div>

        <!-- Controles do Header -->
        <div class="flex items-center space-x-3 self-end sm:self-auto">
          <!-- Toggle Etapas Finais (Membro da equipe ou admin) -->
          <div class="flex items-center bg-gray-50 border border-gray-200 rounded-xl px-3 py-1.5 transition-all duration-200">
            <span class="text-xs font-semibold text-gray-600 mr-3">Etapas finais</span>
            <button
              @click="toggleFinalStages"
              class="relative inline-flex h-6 w-11 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none focus:ring-2 focus:ring-slate-900 focus:ring-offset-2"
              :class="pipelineStore.showFinalStages ? 'bg-slate-900' : 'bg-gray-200'"
            >
              <span
                class="pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out"
                :class="pipelineStore.showFinalStages ? 'translate-x-5' : 'translate-x-0'"
              ></span>
            </button>
          </div>

          <!-- Botão de Filtros -->
          <button 
            @click="toggleFilters"
            class="flex items-center space-x-2 px-4 py-2 border border-gray-200 rounded-xl text-sm font-semibold text-gray-650 hover:text-gray-900 hover:bg-gray-50 hover:border-gray-300 transition-all duration-150 relative"
            :class="{'bg-slate-100 border-slate-350 text-slate-900': filtersOpen || pipelineStore.activeFiltersCount > 0}"
          >
            <component :is="Filter" class="h-4 w-4" />
            <span>Filtros</span>
            <!-- Badge contador de filtros ativos -->
            <span 
              v-if="pipelineStore.activeFiltersCount > 0"
              class="ml-1 flex items-center justify-center px-1.5 py-0.5 rounded-full bg-slate-900 text-[10px] font-bold text-white min-w-[18px]"
            >
              {{ pipelineStore.activeFiltersCount }}
            </span>
          </button>

          <!-- Botão Criar Card -->
          <button
            @click="openCreateCardModal"
            class="flex items-center space-x-2 px-4 py-2 bg-slate-900 hover:bg-slate-800 text-white rounded-xl text-sm font-semibold shadow-md shadow-slate-900/10 hover:shadow-lg transition-all duration-150"
          >
            <component :is="Plus" class="h-4 w-4" />
            <span>Novo card</span>
          </button>
        </div>
      </header>

      <!-- Painel de Filtros Deslizante -->
      <transition
        enter-active-class="transition duration-200 ease-out"
        enter-from-class="transform -translate-y-2 opacity-0"
        enter-to-class="transform translate-y-0 opacity-100"
        leave-active-class="transition duration-150 ease-in"
        leave-from-class="transform translate-y-0 opacity-100"
        leave-to-class="transform -translate-y-2 opacity-0"
      >
        <KanbanFilters v-if="filtersOpen" />
      </transition>

      <!-- Conteúdo do Board (Renderiza o KanbanBoard.vue via rotas) -->
      <div class="flex-1 overflow-hidden relative">
        <router-view v-if="pipelineStore.currentPipelineId" />
        
        <!-- Estado sem pipeline selecionado -->
        <div v-else class="h-full flex flex-col items-center justify-center p-8 bg-gray-50/50">
          <component :is="Columns3" class="h-16 w-16 text-gray-300 mb-4 animate-bounce" />
          <h3 class="text-lg font-bold text-gray-800">Nenhum pipeline carregado</h3>
          <p class="text-sm text-gray-500 mt-1 max-w-sm text-center">
            Certifique-se de que existem pipelines criados neste workspace ou aguarde o sincronismo da API.
          </p>
        </div>
      </div>
    </div>

    <!-- Modal de Criação de Card -->
    <CreateCardModal
      :show="showCreateModal"
      :default-stage-id="pipelineStore.stages[0]?.id"
      @close="showCreateModal = false"
    />

    <!-- Modal de Criação de Novo Pipeline -->
    <div v-if="showNewPipelineModal" class="fixed inset-0 z-50 flex items-center justify-center p-4 animate-fade-in">
      <div 
        @click="showNewPipelineModal = false"
        class="absolute inset-0 bg-slate-900/60 backdrop-blur-sm transition-opacity duration-300"
      ></div>

      <div 
        class="relative bg-white rounded-3xl shadow-2xl max-w-md w-full overflow-hidden p-6 z-10 border border-gray-100 flex flex-col transform scale-100 transition-all duration-300"
      >
        <header class="flex items-center justify-between pb-4 border-b border-gray-100 shrink-0">
          <div>
            <h3 class="text-lg font-bold text-gray-900">Novo Funil de Vendas</h3>
            <p class="text-xs text-gray-400 mt-0.5">Crie um novo pipeline para gerenciar seus negócios.</p>
          </div>
          <button 
            @click="showNewPipelineModal = false"
            class="p-2 text-gray-400 hover:text-gray-650 hover:bg-gray-100 rounded-xl transition-all duration-150"
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </header>

        <form @submit.prevent="handleCreatePipeline" class="py-4 space-y-4">
          <div>
            <label for="pipeline-name" class="block text-xs font-bold text-gray-700 uppercase tracking-wider mb-1">Nome do Pipeline *</label>
            <input
              id="pipeline-name"
              v-model="newPipelineName"
              type="text"
              required
              class="block w-full px-4 py-3 rounded-xl border border-gray-300 focus:outline-none focus:border-slate-800 focus:ring-1 focus:ring-slate-800 bg-gray-50/30 text-sm text-gray-900 transition-all"
              placeholder="Ex: Comercial, Vendas Outbound..."
            />
          </div>

          <footer class="flex items-center justify-end space-x-3 pt-4 border-t border-gray-100">
            <button 
              type="button" 
              @click="showNewPipelineModal = false"
              class="px-4 py-2 text-sm font-semibold text-gray-600 hover:text-gray-800 transition-colors"
            >
              Cancelar
            </button>
            <button 
              type="submit" 
              class="px-5 py-2.5 bg-slate-900 hover:bg-slate-800 text-white rounded-xl text-sm font-semibold shadow-md shadow-slate-900/10 hover:shadow-lg transition-all duration-150 flex items-center space-x-2"
              :disabled="pipelineStore.loading.pipelines"
            >
              <span v-if="pipelineStore.loading.pipelines">Criando...</span>
              <span v-else>Criar Pipeline</span>
            </button>
          </footer>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, watch, onMounted, nextTick } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { usePipelineStore } from '@/stores/pipeline'
import CreateCardModal from './CreateCardModal.vue'
import KanbanFilters from './KanbanFilters.vue'
import { 
  ChevronRight, 
  Settings, 
  ChevronDown, 
  Filter, 
  Plus, 
  Columns3 
} from 'lucide-vue-next'

const route = useRoute()
const router = useRouter()
const pipelineStore = usePipelineStore()

const filtersOpen = ref(false)
const showCreateModal = ref(false)
const showNewPipelineModal = ref(false)
const newPipelineName = ref("")

// Edição inline do pipeline
const isEditingName = ref(false)
const editingName = ref("")
const nameInputRef = ref(null)

const startEditingName = () => {
  if (!pipelineStore.currentPipeline) return
  editingName.value = pipelineStore.currentPipeline.name
  isEditingName.value = true
  nextTick(() => {
    nameInputRef.value?.focus()
  })
}

const savePipelineName = async () => {
  if (!isEditingName.value) return
  isEditingName.value = false
  
  const trimmed = editingName.value.trim()
  if (!trimmed || trimmed === pipelineStore.currentPipeline?.name) return
  
  try {
    await pipelineStore.updatePipeline(pipelineStore.currentPipelineId, { name: trimmed })
    await pipelineStore.fetchPipelines()
  } catch (error) {
    console.error("Erro ao salvar nome do pipeline:", error)
  }
}

const navigateToPipeline = (id) => {
  router.push({ name: 'pipelines-detail', params: { id } })
}

const toggleFinalStages = () => {
  pipelineStore.showFinalStages = !pipelineStore.showFinalStages
}

const toggleFilters = () => {
  filtersOpen.value = !filtersOpen.value
}

const handleCreatePipeline = async () => {
  if (!newPipelineName.value.trim()) return
  try {
    const p = await pipelineStore.createPipeline({ name: newPipelineName.value.trim() })
    if (p && p.id) {
      await pipelineStore.fetchPipelines()
      navigateToPipeline(p.id)
      showNewPipelineModal.value = false
      newPipelineName.value = ""
    }
  } catch (e) {
    console.error("Erro ao criar novo pipeline:", e)
  }
}

const openCreateCardModal = () => {
  showCreateModal.value = true
}

// Inicialização e sincronismo de rotas com a store
onMounted(async () => {
  await pipelineStore.fetchPipelines()
  
  if (pipelineStore.pipelines.length > 0) {
    const routeId = route.params.id
    if (!routeId) {
      // Se acessar /pipelines diretamente, redireciona para o primeiro pipeline
      pipelineStore.selectPipeline(pipelineStore.pipelines[0].id); navigateToPipeline(pipelineStore.pipelines[0].id)
    } else {
      // Se acessar com ID na URL, seleciona aquele pipeline
      await pipelineStore.selectPipeline(Number(routeId))
    }
  }
})

// Observa mudanças no ID do pipeline na URL (ex: ao clicar na sidebar interna)
watch(() => route.params.id, async (newId) => {
  if (newId) {
    await pipelineStore.selectPipeline(Number(newId))
  }
})
</script>
