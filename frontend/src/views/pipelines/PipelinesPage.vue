<template>
  <div class="flex h-[calc(100vh-4rem)] overflow-hidden bg-gray-50/50">
    <!-- Sidebar Interna (Lista de Pipelines) -->
    <aside class="w-64 bg-white border-r border-gray-200 flex flex-col shrink-0">
      <!-- Header da Sidebar Interna -->
      <div class="p-4 border-b border-gray-100 flex items-center justify-between">
        <span class="text-sm font-bold text-gray-800 uppercase tracking-wider">Pipelines</span>
        <span class="px-2 py-0.5 text-xs font-semibold bg-zavy-50 text-zavy-600 rounded-full">
          {{ pipelineStore.pipelines.length }}
        </span>
      </div>

      <!-- Lista de Pipelines -->
      <div class="flex-1 overflow-y-auto p-3 space-y-1">
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

      <!-- Rodapé da Sidebar com atalho para configurações -->
      <div class="p-3 border-t border-gray-100 bg-gray-50/50">
        <router-link
          to="/pipelines/settings"
          class="flex items-center space-x-2.5 px-3 py-2.5 rounded-xl text-sm font-semibold text-gray-600 hover:text-gray-900 hover:bg-white border border-transparent hover:border-gray-200 transition-all duration-200 shadow-sm hover:shadow"
        >
          <component :is="Settings" class="h-4 w-4 text-gray-500" />
          <span>Ajustes de Funil</span>
        </router-link>
      </div>
    </aside>

    <!-- Área Principal do Kanban -->
    <div class="flex-1 flex flex-col min-w-0 bg-[#F8FAFC]">
      <!-- Header do Painel Principal -->
      <header class="bg-white border-b border-gray-200 px-6 py-4 flex flex-col sm:flex-row sm:items-center sm:justify-between space-y-3 sm:space-y-0 shrink-0 shadow-sm">
        <!-- Título / Infos do Pipeline -->
        <div class="truncate">
          <div class="flex items-center space-x-2">
            <h1 class="text-xl font-bold text-gray-900 truncate">
              {{ pipelineStore.currentPipeline?.name || 'Carregando funil...' }}
            </h1>
            <!-- Cor do pipeline -->
            <span 
              v-if="pipelineStore.currentPipeline"
              class="w-3 h-3 rounded-full" 
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
            class="flex items-center space-x-2 px-4 py-2 border border-gray-200 rounded-xl text-sm font-semibold text-gray-600 hover:text-gray-900 hover:bg-gray-50 hover:border-gray-300 transition-all duration-150"
            :class="{'bg-gray-100 border-gray-300 text-gray-900': filtersOpen}"
          >
            <component :is="Filter" class="h-4 w-4" />
            <span>Filtros</span>
            <!-- Badge contador de filtros ativos (placeholder por enquanto) -->
            <span class="w-2 h-2 rounded-full bg-zavy-500"></span>
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

      <!-- Espaço para Relação de Filtros (Dia 10) -->
      <div v-if="filtersOpen" class="bg-white border-b border-gray-200 px-6 py-4 shrink-0 transition-all duration-200">
        <p class="text-xs text-gray-400">Filtros avançados do Kanban estarão disponíveis no Dia 10.</p>
      </div>

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
  </div>
</template>

<script setup>
import { ref, watch, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { usePipelineStore } from '@/stores/pipeline'
import CreateCardModal from './CreateCardModal.vue'
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

const navigateToPipeline = (id) => {
  router.push({ name: 'pipelines-detail', params: { id } })
}

const toggleFinalStages = () => {
  pipelineStore.showFinalStages = !pipelineStore.showFinalStages
}

const toggleFilters = () => {
  filtersOpen.value = !filtersOpen.value
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
      navigateToPipeline(pipelineStore.pipelines[0].id)
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
