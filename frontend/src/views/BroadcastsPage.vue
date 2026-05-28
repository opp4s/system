<template>
  <div class="flex-1 flex flex-col h-full overflow-hidden bg-slate-50/30">
    <!-- Header -->
    <header class="h-16 px-6 border-b border-gray-100 flex items-center justify-between shrink-0 bg-white">
      <div class="flex items-center space-x-3">
        <div class="p-2 bg-slate-900 text-white rounded-xl">
          <component :is="Megaphone" class="h-5 w-5 animate-pulse" />
        </div>
        <div>
          <h1 class="text-base font-extrabold text-gray-900 tracking-tight">Transmissões (Broadcast)</h1>
          <p class="text-xs text-gray-400">Envie campanhas de mensagens automatizadas no WhatsApp para bases qualificadas.</p>
        </div>
      </div>

      <button
        @click="openNewBroadcast"
        type="button"
        class="px-4 py-2 bg-slate-900 hover:bg-slate-800 text-white rounded-xl text-xs font-bold shadow transition-all flex items-center space-x-1.5"
      >
        <component :is="Plus" class="h-3.5 w-3.5" />
        <span>Novo Broadcast</span>
      </button>
    </header>

    <!-- Conteúdo Central -->
    <div class="flex-1 overflow-y-auto p-6 text-left">
      <div v-if="broadcastStore.loading.list" class="grid grid-cols-1 md:grid-cols-2 gap-6 animate-pulse">
        <div v-for="i in 4" :key="i" class="h-44 bg-white border border-gray-150 rounded-3xl"></div>
      </div>

      <div 
        v-else-if="broadcastStore.broadcasts.length === 0" 
        class="h-full flex flex-col items-center justify-center text-center text-sm text-gray-400 py-16 bg-white rounded-3xl border border-dashed border-gray-200"
      >
        <component :is="Megaphone" class="h-12 w-12 text-gray-300 mb-3" />
        <span class="font-semibold text-gray-700">Nenhum broadcast criado</span>
        <span class="text-xs text-gray-400 mt-1 max-w-xs leading-normal">
          Monte campanhas e dispare mensagens personalizadas para seus leads do pipeline de forma rápida.
        </span>
        <button
          @click="openNewBroadcast"
          type="button"
          class="mt-4 px-4 py-2 border border-slate-900 hover:bg-slate-50 text-slate-900 rounded-xl text-xs font-bold transition-all"
        >
          Criar Primeira Transmissão
        </button>
      </div>

      <!-- Grid de Broadcasts -->
      <div v-else class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div 
          v-for="b in broadcastStore.broadcasts" 
          :key="b.id"
          class="bg-white border border-gray-150 rounded-3xl p-5 shadow-sm hover:shadow-md hover:border-gray-250 transition-all flex flex-col relative group"
        >
          <!-- Status e Nome -->
          <div class="flex items-start justify-between space-x-3 mb-3">
            <div class="min-w-0">
              <h3 class="text-xs font-bold text-gray-900 leading-snug group-hover:text-slate-800 transition-colors truncate">
                {{ b.name }}
              </h3>
              <p class="text-[9px] text-gray-400 mt-0.5 font-bold">ID: #{{ b.id }}</p>
            </div>
            
            <span 
              class="inline-flex items-center px-2 py-0.5 rounded-full text-[9px] font-extrabold uppercase tracking-wider shrink-0"
              :class="getStatusBadgeClass(b.status)"
            >
              {{ getStatusLabel(b.status) }}
            </span>
          </div>

          <!-- Mensagem (Preview) -->
          <p class="text-[11px] text-gray-450 leading-relaxed font-semibold italic bg-slate-50 border border-gray-100 rounded-2xl p-3 mb-4 truncate flex-1">
            "{{ b.message }}"
          </p>

          <!-- Métricas de Envio -->
          <div class="grid grid-cols-3 gap-2.5 bg-slate-50/50 border border-gray-150/40 rounded-2xl p-3 mb-4 text-center">
            <div>
              <span class="text-[8px] font-bold text-gray-400 uppercase tracking-wider block">Destinatários</span>
              <span class="text-xs font-black text-gray-800 block mt-0.5">{{ b.recipients_count }}</span>
            </div>
            <div>
              <span class="text-[8px] font-bold text-emerald-500 uppercase tracking-wider block">Enviados</span>
              <span class="text-xs font-black text-emerald-700 block mt-0.5">{{ b.sent_count }}</span>
            </div>
            <div>
              <span class="text-[8px] font-bold text-rose-500 uppercase tracking-wider block">Falhas</span>
              <span class="text-xs font-black text-rose-700 block mt-0.5">{{ b.failed_count }}</span>
            </div>
          </div>

          <!-- Rodapé do Card -->
          <footer class="pt-3.5 border-t border-gray-100 flex items-center justify-between text-[10px] text-gray-400 shrink-0">
            <!-- Data de Agendamento ou Envio -->
            <div class="font-bold">
              <span v-if="b.status === 'scheduled' && b.scheduled_at">
                Agenda: {{ formatFriendlyTime(b.scheduled_at) }}
              </span>
              <span v-else-if="b.sent_at">
                Enviado: {{ formatFriendlyTime(b.sent_at) }}
              </span>
              <span v-else class="text-gray-300 italic">
                Não agendado (Rascunho)
              </span>
            </div>

            <!-- Ações -->
            <div class="flex items-center space-x-1.5 opacity-90 group-hover:opacity-100 transition-opacity">
              <!-- Editar (Somente Rascunhos) -->
              <button 
                v-if="b.status === 'draft'"
                @click="editBroadcast(b)" 
                type="button" 
                class="p-1 text-slate-500 hover:text-slate-800 hover:bg-gray-100 rounded-lg transition-colors"
                title="Editar Rascunho"
              >
                <component :is="Edit2" class="h-3.5 w-3.5" />
              </button>

              <!-- Cancelar (Agendado ou Enviando) -->
              <button 
                v-if="b.status === 'scheduled' || b.status === 'running'"
                @click="cancelBroadcast(b.id)" 
                type="button" 
                class="px-2.5 py-1 text-rose-600 hover:text-rose-700 hover:bg-rose-50 border border-rose-100 rounded-lg font-bold transition-all text-[9px] uppercase tracking-wider"
                title="Cancelar Disparo"
              >
                Cancelar
              </button>

              <!-- Ver Relatório (Enviados, Falhados ou Cancelados) -->
              <button 
                v-if="b.status !== 'draft'"
                @click="openReport(b.id)" 
                type="button" 
                class="px-2.5 py-1 text-slate-700 hover:text-slate-900 hover:bg-gray-100 border border-gray-200 rounded-lg font-bold transition-all text-[9px] uppercase tracking-wider"
                title="Ver Relatório Técnico"
              >
                Relatório
              </button>
            </div>
          </footer>
        </div>
      </div>
    </div>

    <!-- Modais / Gavetas Laterais -->
    <CreateBroadcastModal
      v-if="showCreateModal"
      :broadcast="selectedBroadcast"
      @close="closeCreateModal"
      @saved="onBroadcastSaved"
    />

    <BroadcastReport
      v-if="showReportModal"
      :report="broadcastStore.activeReport"
      :loading="broadcastStore.loading.report"
      @close="closeReportModal"
    />
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useBroadcastStore } from '@/stores/broadcast'
import { useToast } from '@/composables/useToast'
import CreateBroadcastModal from './broadcasts/CreateBroadcastModal.vue'
import BroadcastReport from './broadcasts/BroadcastReport.vue'
import { 
  Megaphone, 
  Plus, 
  Edit2, 
  Loader2 
} from 'lucide-vue-next'

const broadcastStore = useBroadcastStore()
const toast = useToast()

const showCreateModal = ref(false)
const showReportModal = ref(false)
const selectedBroadcast = ref(null)

onMounted(async () => {
  await broadcastStore.fetchBroadcasts()
})

const openNewBroadcast = () => {
  selectedBroadcast.value = null
  showCreateModal.value = true
}

const editBroadcast = (broadcast) => {
  selectedBroadcast.value = broadcast
  showCreateModal.value = true
}

const closeCreateModal = () => {
  showCreateModal.value = false
  selectedBroadcast.value = null
}

const onBroadcastSaved = async () => {
  closeCreateModal()
  await broadcastStore.fetchBroadcasts()
}

// Cancelar envio programado
const cancelBroadcast = async (id) => {
  if (!confirm('Deseja realmente cancelar este disparo de transmissão?')) return
  
  try {
    await broadcastStore.cancelBroadcast(id)
    toast.warning('Transmissão cancelada.')
  } catch (error) {
    toast.error('Erro ao cancelar transmissão.')
  }
}

// Abrir relatório
const openReport = async (id) => {
  showReportModal.value = true
  await broadcastStore.fetchReport(id)
}

const closeReportModal = () => {
  showReportModal.value = false
  broadcastStore.activeReport = null
}

// Helpers Formatação & Status
const getStatusBadgeClass = (status) => {
  switch (status) {
    case 'completed': return 'bg-emerald-50 text-emerald-700 border border-emerald-100'
    case 'running': return 'bg-blue-50 text-blue-700 border border-blue-100 animate-pulse'
    case 'scheduled': return 'bg-amber-50 text-amber-700 border border-amber-100'
    case 'cancelled': return 'bg-gray-100 text-gray-500 border border-gray-200'
    case 'draft': return 'bg-slate-100 text-slate-700 border border-slate-200'
    default: return 'bg-gray-50 text-gray-400 border border-gray-150'
  }
}

const getStatusLabel = (status) => {
  switch (status) {
    case 'completed': return 'Concluído'
    case 'running': return 'Disparando'
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
</script>
