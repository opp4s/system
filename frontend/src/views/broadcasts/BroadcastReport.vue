<template>
  <transition name="slide-panel">
    <div class="fixed inset-0 z-45 flex justify-end">
      <!-- Backdrop -->
      <div 
        @click="$emit('close')"
        class="absolute inset-0 bg-slate-900/40 backdrop-blur-sm transition-opacity duration-300 animate-fade-in"
      ></div>

      <!-- Painel do Relatório (Slide-in) -->
      <div class="relative w-full max-w-2xl h-full bg-white shadow-2xl flex flex-col z-10 animate-slide-in-right">
        <!-- Header -->
        <header class="h-16 px-6 border-b border-gray-100 flex items-center justify-between shrink-0 bg-gray-50/50">
          <div>
            <span class="text-xs font-bold text-gray-400 uppercase tracking-wider block">Relatório de Transmissão</span>
            <h2 class="text-xs font-bold text-gray-800 truncate max-w-[320px] mt-0.5" v-if="report">
              {{ report.name }}
            </h2>
          </div>
          <button 
            @click="$emit('close')"
            class="p-2 text-gray-400 hover:text-gray-650 hover:bg-gray-150 rounded-xl transition-all"
          >
            <component :is="X" class="h-4 w-4" />
          </button>
        </header>

        <!-- Corpo do Relatório -->
        <div class="flex-1 overflow-y-auto p-6 space-y-6 text-left bg-slate-50/30">
          <div v-if="loading" class="space-y-4">
            <div class="h-32 bg-white border border-gray-150 rounded-3xl animate-pulse"></div>
            <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
              <div v-for="i in 4" :key="i" class="h-20 bg-white border border-gray-150 rounded-3xl animate-pulse"></div>
            </div>
            <div class="h-44 bg-white border border-gray-150 rounded-3xl animate-pulse"></div>
          </div>

          <div v-else-if="!report" class="text-center py-12 text-xs text-gray-400 italic">
            Erro ao carregar o relatório desta transmissão.
          </div>

          <div v-else class="space-y-6">
            <!-- Header Informações Principais -->
            <div class="bg-white border border-gray-150 rounded-3xl p-5 shadow-sm space-y-3.5">
              <div class="flex items-center justify-between">
                <div>
                  <span class="text-[9px] font-bold text-gray-400 uppercase tracking-wider block">Status do Broadcast</span>
                  <span 
                    class="inline-flex items-center px-2.5 py-0.5 rounded-full text-[9px] font-extrabold uppercase tracking-wider mt-1.5"
                    :class="getStatusBadgeClass(report.status)"
                  >
                    {{ getStatusLabel(report.status) }}
                  </span>
                </div>
                <div class="text-right">
                  <span class="text-[9px] font-bold text-gray-400 uppercase tracking-wider block">Data de Envio</span>
                  <span class="text-xs font-bold text-gray-800 block mt-1.5">
                    {{ formatFriendlyTime(report.sent_at) || 'Não enviado' }}
                  </span>
                </div>
              </div>

              <!-- Barra de Progresso Visual (Enviados vs Total) -->
              <div class="space-y-1.5 pt-2">
                <div class="flex justify-between text-[10px] font-bold">
                  <span class="text-gray-400">Progresso dos disparos</span>
                  <span class="text-slate-800">{{ percentSent }}% ({{ report.sent_count }} de {{ report.recipients_count }})</span>
                </div>
                <div class="w-full h-3 bg-gray-100 rounded-full overflow-hidden flex">
                  <div 
                    class="h-full bg-slate-900 transition-all duration-500 rounded-full" 
                    :style="{ width: percentSent + '%' }"
                  ></div>
                  <div 
                    class="h-full bg-rose-500 transition-all duration-500" 
                    :style="{ width: percentFailed + '%' }"
                  ></div>
                </div>
              </div>
            </div>

            <!-- Grid de KPIs (4 Cards) -->
            <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
              <!-- KPI 1: Destinatários -->
              <div class="bg-white border border-gray-150 rounded-3xl p-4.5 shadow-sm flex flex-col justify-between">
                <span class="text-[9px] font-bold text-gray-400 uppercase tracking-wider block">Audiência</span>
                <span class="text-lg font-black text-gray-900 block mt-1.5">{{ report.recipients_count }}</span>
                <span class="text-[9px] text-gray-400 font-bold mt-1">leads qualificados</span>
              </div>

              <!-- KPI 2: Enviados -->
              <div class="bg-white border border-gray-150 rounded-3xl p-4.5 shadow-sm flex flex-col justify-between">
                <span class="text-[9px] font-bold text-gray-400 uppercase tracking-wider block">Enviados</span>
                <div class="flex items-baseline space-x-1 mt-1.5">
                  <span class="text-lg font-black text-gray-900">{{ report.sent_count }}</span>
                  <span class="text-[10px] font-bold text-emerald-600">({{ percentSent }}%)</span>
                </div>
                <span class="text-[9px] text-gray-400 font-bold mt-1">mensagens disparadas</span>
              </div>

              <!-- KPI 3: Falhas -->
              <div class="bg-white border border-gray-150 rounded-3xl p-4.5 shadow-sm flex flex-col justify-between">
                <span class="text-[9px] font-bold text-gray-400 uppercase tracking-wider block">Falhas</span>
                <div class="flex items-baseline space-x-1 mt-1.5">
                  <span class="text-lg font-black text-rose-600">{{ report.failed_count }}</span>
                  <span class="text-[10px] font-bold text-rose-500">({{ percentFailed }}%)</span>
                </div>
                <span class="text-[9px] text-gray-400 font-bold mt-1">não entregues</span>
              </div>

              <!-- KPI 4: Entrega / Duração -->
              <div class="bg-white border border-gray-150 rounded-3xl p-4.5 shadow-sm flex flex-col justify-between">
                <span class="text-[9px] font-bold text-gray-400 uppercase tracking-wider block">Taxa / Duração</span>
                <span class="text-lg font-black text-slate-800 block mt-1.5">
                  {{ report.delivery_rate || 0 }}%
                </span>
                <span class="text-[9px] text-gray-400 font-bold mt-1">
                  Tempo: {{ formatDuration(report.duration_seconds) }}
                </span>
              </div>
            </div>

            <!-- Tabela de Falhas de Envio -->
            <div class="space-y-2">
              <div class="flex items-center justify-between">
                <span class="text-[10px] font-bold text-gray-400 uppercase tracking-wider">Erros e Ocorrências</span>
                
                <!-- Botão de Reenviar para Falhas -->
                <button
                  v-if="report.failed_count > 0"
                  @click="handleResendFailed"
                  type="button"
                  class="px-3 py-1.5 bg-rose-50 hover:bg-rose-100 text-rose-700 border border-rose-100 rounded-xl text-[9px] font-bold transition-all flex items-center space-x-1"
                >
                  <component :is="RefreshCcw" class="h-3 w-3 shrink-0" />
                  <span>Reenviar para falhas</span>
                </button>
              </div>

              <!-- Tabela -->
              <div class="border border-gray-150 rounded-2xl overflow-hidden shadow-sm bg-white overflow-x-auto">
                <table class="min-w-full divide-y divide-gray-100 text-left">
                  <thead class="bg-gray-50/70">
                    <tr class="text-[9px] font-extrabold text-gray-400 uppercase tracking-wider">
                      <th class="px-4 py-2.5">Contato</th>
                      <th class="px-4 py-2.5">Telefone</th>
                      <th class="px-4 py-2.5">Motivo do Erro</th>
                    </tr>
                  </thead>
                  <tbody class="divide-y divide-gray-100 text-xs text-gray-700 font-semibold">
                    <tr v-if="!report.failures || report.failures.length === 0">
                      <td colspan="3" class="px-4 py-6 text-center text-[10px] text-gray-400 italic">
                        Nenhuma falha de entrega registrada para esta transmissão! 🎉
                      </td>
                    </tr>
                    <tr 
                      v-else
                      v-for="(fail, idx) in report.failures" 
                      :key="idx"
                      class="hover:bg-rose-50/10"
                    >
                      <td class="px-4 py-3 whitespace-nowrap text-slate-800">
                        {{ fail.contact_name }}
                      </td>
                      <td class="px-4 py-3 whitespace-nowrap text-gray-450 font-bold">
                        {{ fail.phone }}
                      </td>
                      <td class="px-4 py-3 text-rose-600 font-medium">
                        {{ fail.error_message }}
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </div>

        <!-- Footer -->
        <footer class="h-16 px-6 border-t border-gray-100 flex items-center justify-end shrink-0 bg-gray-50/50">
          <button 
            type="button" 
            @click="$emit('close')"
            class="px-4 py-2 border border-gray-250 text-gray-650 rounded-xl text-xs font-semibold hover:bg-gray-100 transition-colors"
          >
            Fechar Relatório
          </button>
        </footer>
      </div>
    </div>
  </transition>
</template>

<script setup>
import { computed } from 'vue'
import { useToast } from '@/composables/useToast'
import { X, RefreshCcw } from 'lucide-vue-next'

const props = defineProps({
  report: {
    type: Object,
    default: null
  },
  loading: {
    type: Boolean,
    default: false
  }
})

defineEmits(['close'])
const toast = useToast()

const percentSent = computed(() => {
  if (!props.report || !props.report.recipients_count) return 0
  return Math.round((props.report.sent_count / props.report.recipients_count) * 100)
})

const percentFailed = computed(() => {
  if (!props.report || !props.report.recipients_count) return 0
  return Math.round((props.report.failed_count / props.report.recipients_count) * 100)
})

const getStatusBadgeClass = (status) => {
  switch (status) {
    case 'completed': return 'bg-emerald-50 text-emerald-700 border border-emerald-100'
    case 'running': return 'bg-blue-50 text-blue-700 border border-blue-100 animate-pulse'
    case 'scheduled': return 'bg-amber-50 text-amber-700 border border-amber-100'
    case 'cancelled': return 'bg-gray-100 text-gray-600 border border-gray-200'
    default: return 'bg-gray-50 text-gray-400 border border-gray-150'
  }
}

const getStatusLabel = (status) => {
  switch (status) {
    case 'completed': return 'Concluído'
    case 'running': return 'Enviando...'
    case 'scheduled': return 'Agendado'
    case 'cancelled': return 'Cancelado'
    case 'draft': return 'Rascunho'
    default: return status
  }
}

const formatFriendlyTime = (isoString) => {
  if (!isoString) return ''
  const date = new Date(isoString)
  const day = date.getDate().toString().padStart(2, '0')
  const month = (date.getMonth() + 1).toString().padStart(2, '0')
  const hours = date.getHours().toString().padStart(2, '0')
  const minutes = date.getMinutes().toString().padStart(2, '0')
  return `${day}/${month} às ${hours}:${minutes}`
}

const formatDuration = (secs) => {
  if (!secs) return 'N/A'
  if (secs < 60) return `${secs}s`
  const mins = Math.floor(secs / 60)
  const remainder = secs % 60
  return remainder > 0 ? `${mins}m ${remainder}s` : `${mins}m`
}

const handleResendFailed = () => {
  // Placeholder conforme instrução
  toast.success('Solicitação de reenvio iniciada para os contatos com falha!')
}
</script>

<style scoped>
.animate-fade-in {
  animation: fadeIn 0.2s cubic-bezier(0.16, 1, 0.3, 1) forwards;
}

@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}

@keyframes slideInRight {
  from {
    transform: translateX(100%);
  }
  to {
    transform: translateX(0);
  }
}
.animate-slide-in-right {
  animation: slideInRight 0.28s cubic-bezier(0.16, 1, 0.3, 1) forwards;
}
</style>
