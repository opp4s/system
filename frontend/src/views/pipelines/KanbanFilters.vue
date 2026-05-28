<template>
  <div class="bg-white border-b border-gray-200 px-6 py-5 shrink-0 transition-all duration-300 shadow-inner">
    <div class="max-w-7xl mx-auto space-y-4">
      <div class="flex items-center justify-between">
        <div class="flex items-center space-x-2 text-slate-800">
          <component :is="Filter" class="h-4 w-4 text-zavy-600" />
          <h4 class="text-xs font-bold uppercase tracking-wider">Filtros Ativos</h4>
        </div>
        <button
          v-if="pipelineStore.activeFiltersCount > 0"
          @click="clearAll"
          class="text-xs font-bold text-rose-600 hover:text-rose-700 hover:underline flex items-center space-x-1"
        >
          <span>Limpar todos os filtros</span>
          <span class="px-1.5 py-0.5 rounded-full bg-rose-50 text-[10px]">{{ pipelineStore.activeFiltersCount }}</span>
        </button>
      </div>

      <!-- Grid de Filtros -->
      <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-4 gap-4">
        <!-- Responsável -->
        <div class="space-y-1.5">
          <label class="text-[10px] font-bold text-gray-400 uppercase tracking-wider block">Responsável</label>
          <select
            v-model="localFilters.user"
            class="block w-full px-3 py-2 rounded-xl border border-gray-250 focus:outline-none focus:border-zavy-500 focus:ring-1 focus:ring-zavy-500 bg-gray-50/50 text-xs text-gray-800 transition-all"
          >
            <option value="">Todos os agentes</option>
            <option v-for="agent in uniqueAgents" :key="agent" :value="agent">
              {{ agent }}
            </option>
          </select>
        </div>

        <!-- Tipo de Etapa -->
        <div class="space-y-1.5">
          <label class="text-[10px] font-bold text-gray-400 uppercase tracking-wider block">Tipo de Etapa</label>
          <select
            v-model="localFilters.stageType"
            class="block w-full px-3 py-2 rounded-xl border border-gray-250 focus:outline-none focus:border-zavy-500 focus:ring-1 focus:ring-zavy-500 bg-gray-50/50 text-xs text-gray-800 transition-all"
          >
            <option value="">Todas as etapas</option>
            <option value="intermediate">Intermediária</option>
            <option value="win">Fechado Ganho (Win)</option>
            <option value="lose">Fechado Perdido (Lose)</option>
          </select>
        </div>

        <!-- Valor do Card (Faixa) -->
        <div class="space-y-1.5">
          <label class="text-[10px] font-bold text-gray-400 uppercase tracking-wider block">Valor Comercial (R$)</label>
          <div class="flex items-center space-x-2">
            <input
              type="number"
              v-model.number="localFilters.valueMin"
              placeholder="Mín"
              class="block w-1/2 px-3 py-2 rounded-xl border border-gray-250 focus:outline-none focus:border-zavy-500 focus:ring-1 focus:ring-zavy-500 bg-gray-50/50 text-xs text-gray-800 transition-all"
            />
            <span class="text-gray-400 text-xs">-</span>
            <input
              type="number"
              v-model.number="localFilters.valueMax"
              placeholder="Máx"
              class="block w-1/2 px-3 py-2 rounded-xl border border-gray-250 focus:outline-none focus:border-zavy-500 focus:ring-1 focus:ring-zavy-500 bg-gray-50/50 text-xs text-gray-800 transition-all"
            />
          </div>
        </div>

        <!-- Tempo na Etapa (Faixa) -->
        <div class="space-y-1.5">
          <label class="text-[10px] font-bold text-gray-400 uppercase tracking-wider block">Dias na Etapa</label>
          <div class="flex items-center space-x-2">
            <input
              type="number"
              v-model.number="localFilters.daysMin"
              placeholder="Min dias"
              class="block w-1/2 px-3 py-2 rounded-xl border border-gray-250 focus:outline-none focus:border-zavy-500 focus:ring-1 focus:ring-zavy-500 bg-gray-50/50 text-xs text-gray-800 transition-all"
            />
            <span class="text-gray-400 text-xs">-</span>
            <input
              type="number"
              v-model.number="localFilters.daysMax"
              placeholder="Max dias"
              class="block w-1/2 px-3 py-2 rounded-xl border border-gray-250 focus:outline-none focus:border-zavy-500 focus:ring-1 focus:ring-zavy-500 bg-gray-50/50 text-xs text-gray-800 transition-all"
            />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { reactive, watch, computed } from 'vue'
import { usePipelineStore } from '@/stores/pipeline'
import { Filter } from 'lucide-vue-next'

const pipelineStore = usePipelineStore()

// Sincroniza estado inicial dos filtros
const localFilters = reactive({
  user: pipelineStore.filters.user || '',
  valueMin: pipelineStore.filters.valueMin,
  valueMax: pipelineStore.filters.valueMax,
  daysMin: pipelineStore.filters.daysMin,
  daysMax: pipelineStore.filters.daysMax,
  stageType: pipelineStore.filters.stageType || ''
})

// Lista única de agentes presentes nos cards carregados
const uniqueAgents = computed(() => {
  const agents = new Set()
  pipelineStore.cards.forEach(card => {
    if (card.user && card.user.name) {
      agents.add(card.user.name)
    }
  })
  return Array.from(agents).sort()
})

// Observa mudanças locais e atualiza a store
watch(
  () => ({ ...localFilters }),
  (newFilters) => {
    pipelineStore.setFilters(newFilters)
  },
  { deep: true }
)

// Observa se a store foi limpa externamente
watch(
  () => pipelineStore.filters,
  (storeFilters) => {
    localFilters.user = storeFilters.user || ''
    localFilters.valueMin = storeFilters.valueMin
    localFilters.valueMax = storeFilters.valueMax
    localFilters.daysMin = storeFilters.daysMin
    localFilters.daysMax = storeFilters.daysMax
    localFilters.stageType = storeFilters.stageType || ''
  },
  { deep: true }
)

const clearAll = () => {
  pipelineStore.clearFilters()
}
</script>
