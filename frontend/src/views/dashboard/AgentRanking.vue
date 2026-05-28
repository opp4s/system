<template>
  <div class="bg-white border border-gray-150 rounded-3xl p-5 shadow-sm space-y-4">
    <div class="flex items-center justify-between">
      <h3 class="text-xs font-bold text-gray-900 uppercase tracking-wider">Performance da Equipe (Ranking)</h3>
      <span class="text-[9px] font-bold text-gray-400 uppercase">Período Selecionado</span>
    </div>

    <!-- Skeletons Loading -->
    <div v-if="loading" class="space-y-3">
      <div v-for="i in 3" :key="i" class="h-12 bg-gray-100 rounded-xl animate-pulse"></div>
    </div>

    <!-- Empty State -->
    <div v-else-if="!agents || agents.length === 0" class="text-center py-10 text-xs text-gray-400 italic">
      Sem dados de desempenho dos agentes para este período.
    </div>

    <!-- Tabela Ativa -->
    <div v-else class="border border-gray-150 rounded-2xl overflow-hidden shadow-sm bg-white overflow-x-auto">
      <table class="min-w-full divide-y divide-gray-100 text-left">
        <thead class="bg-gray-50/70 text-[9px] font-extrabold text-gray-400 uppercase tracking-wider select-none">
          <tr>
            <th class="px-4 py-3">Agente</th>
            <th 
              @click="toggleSort('cards_won')"
              class="px-4 py-3 cursor-pointer hover:text-slate-800 transition-colors"
            >
              <div class="flex items-center space-x-1">
                <span>Ganhos</span>
                <span class="text-[8px]">{{ getSortIcon('cards_won') }}</span>
              </div>
            </th>
            <th 
              @click="toggleSort('value_won')"
              class="px-4 py-3 cursor-pointer hover:text-slate-800 transition-colors"
            >
              <div class="flex items-center space-x-1">
                <span>Valor Ganho</span>
                <span class="text-[8px]">{{ getSortIcon('value_won') }}</span>
              </div>
            </th>
            <th 
              @click="toggleSort('avg_time_days')"
              class="px-4 py-3 cursor-pointer hover:text-slate-800 transition-colors"
            >
              <div class="flex items-center space-x-1">
                <span>Tempo Médio</span>
                <span class="text-[8px]">{{ getSortIcon('avg_time_days') }}</span>
              </div>
            </th>
          </tr>
        </thead>
        <tbody class="divide-y divide-gray-100 text-xs text-gray-700 font-semibold">
          <tr 
            v-for="(agent, idx) in sortedAgents" 
            :key="agent.id" 
            class="hover:bg-slate-50/50 transition-colors"
            :class="idx === 0 ? 'bg-amber-50/5' : ''"
          >
            <!-- Perfil / Nome -->
            <td class="px-4 py-3.5 whitespace-nowrap">
              <div class="flex items-center space-x-3">
                <div class="relative">
                  <img 
                    :src="agent.avatar" 
                    class="h-8 w-8 rounded-full border border-gray-200 object-cover" 
                    :alt="agent.name" 
                  />
                  <!-- Coroa Gold para o Top Performer -->
                  <span 
                    v-if="idx === 0" 
                    class="absolute -top-2.5 -left-1.5 text-base select-none rotate-[340deg]"
                    title="Top Performer"
                  >
                    👑
                  </span>
                </div>
                <div>
                  <span class="font-extrabold text-slate-800 block">{{ agent.name }}</span>
                  <span v-if="idx === 0" class="text-[9px] text-amber-600 font-bold uppercase tracking-wider block leading-none mt-0.5">Top Performer</span>
                </div>
              </div>
            </td>

            <!-- Cards Ganhos -->
            <td class="px-4 py-3.5 whitespace-nowrap text-slate-900 font-black">
              {{ agent.cards_won }}
            </td>

            <!-- Valor Ganho -->
            <td class="px-4 py-3.5 whitespace-nowrap text-emerald-700 font-extrabold">
              {{ formatCurrency(agent.value_won) }}
            </td>

            <!-- Tempo Médio (Ciclo) -->
            <td class="px-4 py-3.5 whitespace-nowrap text-gray-500">
              {{ agent.avg_time_days }} dias
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'

const props = defineProps({
  agents: {
    type: Array,
    required: true,
    default: () => []
  },
  loading: {
    type: Boolean,
    default: false
  }
})

// Estado de ordenação padrão (Ganhos descrescente)
const sortBy = ref('cards_won')
const sortDesc = ref(true)

const toggleSort = (field) => {
  if (sortBy.value === field) {
    sortDesc.value = !sortDesc.value
  } else {
    sortBy.value = field
    sortDesc.value = true
  }
}

const getSortIcon = (field) => {
  if (sortBy.value !== field) return '↕️'
  return sortDesc.value ? '▼' : '▲'
}

const sortedAgents = computed(() => {
  if (!props.agents) return []
  return [...props.agents].sort((a, b) => {
    let fieldA = a[sortBy.value]
    let fieldB = b[sortBy.value]
    
    if (sortBy.value === 'avg_time_days') {
      // Para o tempo médio, menor tempo é melhor (ordem inversa de destaque)
      return sortDesc.value ? fieldB - fieldA : fieldA - fieldB
    }
    
    return sortDesc.value ? fieldB - fieldA : fieldA - fieldB
  })
})

const formatCurrency = (val) => {
  return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(val || 0)
}
</script>
