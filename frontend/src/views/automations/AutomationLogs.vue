<template>
  <div class="w-full h-full flex flex-col">
    <!-- Estado de Loading (Skeleton) -->
    <div v-if="loading" class="space-y-4 w-full">
      <div class="border border-gray-150 rounded-2xl overflow-hidden shadow-sm">
        <table class="min-w-full divide-y divide-gray-100 bg-white">
          <thead class="bg-gray-50/70">
            <tr>
              <th v-for="i in 4" :key="i" class="px-4 py-3 text-left">
                <div class="h-3 bg-gray-200 rounded-md w-16 animate-pulse"></div>
              </th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-100">
            <tr v-for="row in 3" :key="row">
              <td class="px-4 py-4"><div class="h-3.5 bg-gray-150 rounded-md w-24 animate-pulse"></div></td>
              <td class="px-4 py-4"><div class="h-3.5 bg-gray-150 rounded-md w-32 animate-pulse"></div></td>
              <td class="px-4 py-4"><div class="h-5 bg-gray-150 rounded-full w-16 animate-pulse"></div></td>
              <td class="px-4 py-4"><div class="h-3.5 bg-gray-150 rounded-md w-48 animate-pulse"></div></td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Estado Vazio (Sem Logs) -->
    <div 
      v-else-if="!logs || logs.length === 0" 
      class="text-center py-16 px-6 bg-white border border-dashed border-gray-200 rounded-3xl flex flex-col items-center justify-center space-y-3"
    >
      <span class="text-3xl select-none animate-bounce">📋</span>
      <div class="space-y-1">
        <span class="font-bold text-gray-700 text-xs block">Nenhum disparo registrado</span>
        <span class="text-[10px] text-gray-400 block max-w-xs leading-normal">
          Esta automação ainda não foi acionada por nenhum lead ou evento no pipeline.
        </span>
      </div>
    </div>

    <!-- Tabela de Logs (Estado Ativo) -->
    <div v-else class="border border-gray-150 rounded-2xl overflow-hidden shadow-sm bg-white overflow-x-auto">
      <table class="min-w-full divide-y divide-gray-100 text-left">
        <thead class="bg-gray-50/80">
          <tr class="text-[10px] font-extrabold text-gray-400 uppercase tracking-wider">
            <th scope="col" class="px-4 py-3">Data/Hora</th>
            <th scope="col" class="px-4 py-3">Negócio</th>
            <th scope="col" class="px-4 py-3">Status</th>
            <th scope="col" class="px-4 py-3">Ações Executadas</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-gray-100 text-xs text-gray-700 font-medium">
          <tr 
            v-for="log in logs" 
            :key="log.id" 
            class="hover:bg-slate-50/50 transition-colors"
          >
            <!-- Data/Hora -->
            <td class="px-4 py-3.5 whitespace-nowrap text-gray-450 text-[10px] font-bold">
              {{ formatFriendlyTime(log.created_at) }}
            </td>

            <!-- Negócio (Lead) -->
            <td class="px-4 py-3.5">
              <div class="flex items-center space-x-1.5 min-w-[120px]">
                <component :is="Briefcase" class="h-3.5 w-3.5 text-gray-400 shrink-0" />
                <a 
                  @click.prevent="$emit('goToCard', log.card_id)"
                  href="#" 
                  class="text-violet-650 hover:text-violet-850 hover:underline font-bold truncate max-w-[130px] flex items-center space-x-0.5"
                  title="Ver detalhes do negócio"
                >
                  <span>{{ log.card_title || `Negócio #${log.card_id}` }}</span>
                  <component :is="ExternalLink" class="h-2.5 w-2.5 inline shrink-0" />
                </a>
              </div>
            </td>

            <!-- Status -->
            <td class="px-4 py-3.5 whitespace-nowrap">
              <span 
                class="inline-flex items-center px-2 py-0.5 rounded-full text-[9px] font-extrabold uppercase tracking-wider"
                :class="log.status === 'success' ? 'bg-emerald-50 text-emerald-700' : 'bg-rose-50 text-rose-700'"
              >
                <component 
                  :is="log.status === 'success' ? CheckCircle2 : XCircle" 
                  class="h-3 w-3 mr-1 shrink-0" 
                />
                {{ log.status === 'success' ? 'Sucesso' : 'Falha' }}
              </span>
            </td>

            <!-- Resumo das Ações -->
            <td class="px-4 py-3.5 max-w-xs">
              <div class="space-y-1">
                <div 
                  v-for="(summary, idx) in log.actions_summary" 
                  :key="idx"
                  class="text-[10px] leading-relaxed text-gray-650 font-semibold flex items-start space-x-1"
                >
                  <span class="text-slate-400 select-none shrink-0">•</span>
                  <span class="break-words">{{ summary }}</span>
                </div>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script setup>
import { Briefcase, ExternalLink, CheckCircle2, XCircle } from 'lucide-vue-next'

const props = defineProps({
  logs: {
    type: Array,
    required: true,
    default: () => []
  },
  loading: {
    type: Boolean,
    default: false
  }
})

defineEmits(['goToCard'])

const formatFriendlyTime = (isoString) => {
  if (!isoString) return ''
  const date = new Date(isoString)
  const day = date.getDate().toString().padStart(2, '0')
  const month = (date.getMonth() + 1).toString().padStart(2, '0')
  const hours = date.getHours().toString().padStart(2, '0')
  const minutes = date.getMinutes().toString().padStart(2, '0')
  return `${day}/${month} às ${hours}:${minutes}`
}
</script>
