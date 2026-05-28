<template>
  <div class="h-full flex flex-col overflow-hidden">
    <!-- Loader global do Board -->
    <div v-if="pipelineStore.loading.stages || pipelineStore.loading.cards" class="flex-1 flex items-center justify-center bg-gray-50/20">
      <div class="flex flex-col items-center space-y-4">
        <svg class="animate-spin h-8 w-8 text-slate-900" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
        </svg>
        <span class="text-sm font-semibold text-gray-500">Carregando quadro de negócios...</span>
      </div>
    </div>

    <!-- Quadro Kanban -->
    <div v-else class="flex-1 overflow-x-auto overflow-y-hidden flex p-6 space-x-4 select-none">
      <div
        v-for="stage in pipelineStore.stages"
        :key="stage.id"
        class="w-80 flex flex-col h-full bg-slate-50 border border-gray-200/80 rounded-2xl shrink-0"
      >
        <!-- Header da Coluna -->
        <header class="p-4 border-b border-gray-100 flex flex-col shrink-0">
          <div class="flex items-center justify-between">
            <div class="flex items-center space-x-2 truncate">
              <!-- Indicador de cor do estágio -->
              <span 
                class="w-3 h-3 rounded-full shrink-0" 
                :style="{ backgroundColor: stage.color || '#CBD5E1' }"
              ></span>
              <h3 class="text-sm font-bold text-gray-800 truncate">{{ stage.name }}</h3>
            </div>
            
            <span class="px-2 py-0.5 text-xs font-bold bg-gray-200/60 text-gray-600 rounded-full shrink-0">
              {{ (pipelineStore.cardsByStage[stage.id] || []).length }}
            </span>
          </div>

          <!-- Total de Valor da Etapa -->
          <div class="text-xs font-semibold text-gray-500 mt-1 flex items-center justify-between">
            <span>Total da etapa:</span>
            <span class="text-gray-900 font-bold">
              {{ formatCurrency(getStageTotal(stage.id)) }}
            </span>
          </div>
        </header>

        <!-- Lista de Cards da Etapa -->
        <div class="flex-1 overflow-y-auto p-3 space-y-3">
          <div
            v-for="card in (pipelineStore.cardsByStage[stage.id] || [])"
            :key="card.id"
            @click="openCardDetail(card.id)"
            class="bg-white border border-gray-200 hover:border-gray-300 rounded-xl p-4 shadow-sm hover:shadow transition-all duration-200 cursor-pointer flex flex-col space-y-3 group"
          >
            <!-- Título e Tags -->
            <div>
              <div class="flex flex-wrap gap-1 mb-2">
                <span 
                  v-for="tag in card.labels" 
                  :key="tag"
                  class="px-2 py-0.5 text-[10px] font-bold rounded bg-slate-100 text-slate-600 uppercase tracking-wider"
                >
                  {{ tag }}
                </span>
              </div>
              <h4 class="text-sm font-bold text-gray-900 group-hover:text-zavy-600 transition-colors duration-150">
                {{ card.title }}
              </h4>
            </div>

            <!-- Contato -->
            <div v-if="card.contact_name" class="flex items-center space-x-1.5 text-xs text-gray-500">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 text-gray-400 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
              </svg>
              <span class="truncate font-medium">{{ card.contact_name }}</span>
            </div>

            <!-- Rodapé do Card (Valor, Dias, Agente) -->
            <footer class="flex items-center justify-between pt-2 border-t border-gray-100">
              <!-- Valor -->
              <span class="text-xs font-extrabold text-gray-900">
                {{ formatCurrency(card.value, card.currency) }}
              </span>

              <div class="flex items-center space-x-2 shrink-0">
                <!-- Dias na Etapa -->
                <span 
                  class="text-[10px] font-semibold px-1.5 py-0.5 rounded bg-gray-100 text-gray-500"
                  :title="`${card.days_in_stage} dias nesta etapa`"
                >
                  {{ card.days_in_stage }}d
                </span>
                
                <!-- Avatar do Agente -->
                <div 
                  class="h-6 w-6 rounded-full bg-slate-100 border border-gray-200 text-slate-700 flex items-center justify-center text-[10px] font-bold uppercase shrink-0"
                  :title="card.user?.name || 'Sem responsável'"
                >
                  {{ getInitials(card.user?.name || 'SR') }}
                </div>
              </div>
            </footer>
          </div>

          <!-- Coluna Vazia Placeholder -->
          <div 
            v-if="(pipelineStore.cardsByStage[stage.id] || []).length === 0" 
            class="h-24 border border-dashed border-gray-300 rounded-xl flex items-center justify-center text-xs text-gray-400"
          >
            Nenhum card nesta etapa
          </div>
        </div>
      </div>
    </div>

    <!-- Rota aninhada para Slide-in de Detalhes do Card (Dia 8) -->
    <router-view />
  </div>
</template>

<script setup>
import { useRoute, useRouter } from 'vue-router'
import { usePipelineStore } from '@/stores/pipeline'

const route = useRoute()
const router = useRouter()
const pipelineStore = usePipelineStore()

const formatCurrency = (value, currency = 'BRL') => {
  if (value === undefined || value === null) return 'R$ 0,00'
  return new Intl.NumberFormat('pt-BR', {
    style: 'currency',
    currency: currency
  }).format(value)
}

const getStageTotal = (stageId) => {
  const cards = pipelineStore.cardsByStage[stageId] || []
  return cards.reduce((sum, card) => sum + (card.value || 0), 0)
}

const getInitials = (name) => {
  if (!name) return 'SR'
  return name.split(' ').map(n => n[0]).join('').substring(0, 2).toUpperCase()
}

const openCardDetail = (cardId) => {
  router.push({
    name: 'card-detail',
    params: { 
      id: pipelineStore.currentPipelineId,
      cardId: cardId 
    }
  })
}
</script>

<style scoped>
/* Scroll horizontal mais suave para Webkit */
::-webkit-scrollbar {
  height: 8px;
  width: 8px;
}
::-webkit-scrollbar-track {
  background: #f1f5f9;
}
::-webkit-scrollbar-thumb {
  background: #cbd5e1;
  border-radius: 9999px;
}
::-webkit-scrollbar-thumb:hover {
  background: #94a3b8;
}
</style>
