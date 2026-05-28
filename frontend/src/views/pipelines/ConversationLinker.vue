<template>
  <div class="bg-white p-4 rounded-2xl border border-gray-150 shadow-sm space-y-3">
    <div class="flex items-center justify-between">
      <h3 class="text-xs font-bold text-gray-800 uppercase tracking-wider flex items-center space-x-1.5">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-emerald-600 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
          <path stroke-linecap="round" stroke-linejoin="round" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
        </svg>
        <span>Conexão WhatsApp</span>
      </h3>
    </div>

    <!-- Caso possua conversa vinculada -->
    <div v-if="card.conversation_id" class="space-y-3">
      <div class="bg-emerald-50 border border-emerald-100 rounded-xl p-3 flex items-start space-x-2.5">
        <component :is="Check" class="h-4 w-4 text-emerald-600 shrink-0 mt-0.5" />
        <div class="flex-1 min-w-0">
          <p class="text-xs font-bold text-emerald-800">Conversa Vinculada</p>
          <p class="text-[10px] text-emerald-600 mt-0.5">
            ID no Chatwoot: <span class="font-mono font-bold">#{{ card.conversation_id }}</span>
          </p>
        </div>
      </div>

      <!-- Botão / Controles de Desvinculação com Confirmação Inline -->
      <div class="flex items-center justify-end">
        <div v-if="confirmingUnlink" class="flex items-center space-x-1.5 bg-rose-50 border border-rose-100 px-2.5 py-1.5 rounded-xl animate-scale-up">
          <span class="text-[10px] font-bold text-rose-800 mr-1.5">Tem certeza?</span>
          <button 
            type="button" 
            @click="confirmingUnlink = false" 
            class="px-2 py-1 text-[10px] bg-white hover:bg-gray-50 border border-gray-250 text-gray-700 rounded-lg font-semibold"
          >
            Não
          </button>
          <button 
            type="button" 
            @click="handleUnlink" 
            :disabled="loading"
            class="px-2 py-1 text-[10px] bg-rose-600 hover:bg-rose-700 text-white rounded-lg font-bold flex items-center"
          >
            <component v-if="loading" :is="Loader2" class="h-3 w-3 animate-spin mr-1" />
            <span>Sim, desvincular</span>
          </button>
        </div>

        <button
          v-else
          type="button"
          @click="confirmingUnlink = true"
          class="text-[10px] font-bold text-rose-600 hover:text-rose-800 px-3 py-1.5 hover:bg-rose-50 border border-rose-150 rounded-xl transition-all"
        >
          Desvincular Conversa
        </button>
      </div>
    </div>

    <!-- Caso NÃO possua conversa vinculada -->
    <div v-else class="space-y-2">
      <p class="text-[10px] text-gray-400 leading-normal">
        Nenhuma conversa WhatsApp vinculada a este negócio comercial. Conecte um chat para visualizar a timeline e enviar respostas.
      </p>
      <button
        type="button"
        @click="openLinkerModal"
        class="w-full py-2.5 border border-dashed border-gray-300 hover:border-zavy-500 rounded-xl text-xs font-bold text-gray-500 hover:text-zavy-700 bg-white hover:bg-zavy-50/10 transition-all flex items-center justify-center space-x-1.5 shadow-sm"
      >
        <component :is="Link" class="h-3.5 w-3.5" />
        <span>+ Vincular Conversa</span>
      </button>
    </div>

    <!-- Modal de Vinculação de Conversa -->
    <div v-if="showModal" class="fixed inset-0 z-50 flex items-center justify-center p-4">
      <!-- Backdrop -->
      <div @click="showModal = false" class="absolute inset-0 bg-slate-900/60 backdrop-blur-sm"></div>

      <!-- Container do Modal -->
      <div class="relative bg-white rounded-3xl shadow-2xl max-w-md w-full p-6 z-10 animate-scale-up border border-gray-100 flex flex-col max-h-[80vh]">
        <!-- Header -->
        <header class="flex items-center justify-between pb-3 border-b border-gray-100 shrink-0">
          <div>
            <h3 class="text-base font-bold text-gray-900">Vincular Conversa do WhatsApp</h3>
            <p class="text-[10px] text-gray-400 mt-0.5">Selecione uma conversa ativa do Chatwoot para vincular a este negócio.</p>
          </div>
          <button 
            @click="showModal = false" 
            class="p-1.5 text-gray-400 hover:text-gray-600 rounded-lg hover:bg-gray-50 transition-colors"
          >
            <component :is="X" class="h-4.5 w-4.5" />
          </button>
        </header>

        <!-- Campo de Filtro Rápido no Modal -->
        <div class="py-3 border-b border-gray-50 shrink-0">
          <div class="relative">
            <input 
              v-model="modalFilter"
              type="text" 
              placeholder="Buscar por nome ou mensagem..."
              class="block w-full px-3 py-2 rounded-xl border border-gray-200 focus:outline-none focus:border-slate-800 focus:ring-1 focus:ring-slate-800 text-xs bg-gray-50/20"
            />
          </div>
        </div>

        <!-- Lista de Conversas -->
        <div class="flex-1 overflow-y-auto py-3 space-y-2 max-h-[40vh] pr-1">
          <div v-if="loadingConversations" class="flex flex-col items-center justify-center py-8 space-y-2">
            <component :is="Loader2" class="h-6 w-6 text-slate-850 animate-spin" />
            <span class="text-xs text-gray-400">Buscando conversas no Chatwoot...</span>
          </div>

          <div v-else-if="filteredConversations.length === 0" class="text-center py-8 text-xs text-gray-400 italic">
            Nenhuma conversa recente disponível para vinculação.
          </div>

          <div v-else class="space-y-2">
            <div
              v-for="conv in filteredConversations"
              :key="conv.id"
              @click="handleLink(conv.id)"
              class="p-3 border border-gray-150 hover:border-zavy-500 rounded-2xl cursor-pointer hover:bg-zavy-50/5 transition-all text-left flex flex-col space-y-1.5 shadow-sm hover:shadow"
            >
              <div class="flex items-center justify-between text-[9px] font-bold">
                <span class="text-zavy-600 uppercase font-mono">ID: #{{ conv.id }}</span>
                <span class="text-gray-400">{{ formatTime(conv.updated_at) }}</span>
              </div>
              <div class="text-xs font-bold text-gray-800 flex items-center space-x-1.5">
                <div class="w-1.5 h-1.5 rounded-full bg-emerald-500 shrink-0"></div>
                <span class="truncate">{{ conv.contact_name }}</span>
              </div>
              <p class="text-[10px] text-gray-500 truncate leading-relaxed">
                {{ conv.last_message }}
              </p>
            </div>
          </div>
        </div>

        <!-- Footer do Modal -->
        <footer class="pt-3 border-t border-gray-100 flex items-center justify-end shrink-0">
          <button 
            type="button" 
            @click="showModal = false"
            class="px-4 py-2 border border-gray-200 text-gray-650 rounded-xl text-xs font-semibold hover:bg-gray-50 transition-colors"
          >
            Fechar
          </button>
        </footer>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { usePipelineStore } from '@/stores/pipeline'
import { useToast } from '@/composables/useToast'
import { 
  Check, 
  Link, 
  X, 
  Loader2 
} from 'lucide-vue-next'
import api from '@/plugins/axios'

const props = defineProps({
  card: {
    type: Object,
    required: true
  }
})

const pipelineStore = usePipelineStore()
const toast = useToast()

const showModal = ref(false)
const modalFilter = ref('')
const confirmingUnlink = ref(false)
const loading = ref(false)
const loadingConversations = ref(false)
const conversations = ref([])

// Mock de conversas disponíveis no Chatwoot
const MOCK_CONVERSATIONS = [
  { id: 101, contact_name: 'Guilherme Rosa', last_message: 'Olá, gostaria de saber os valores do plano comercial.', updated_at: '2026-05-28T04:20:00Z' },
  { id: 102, contact_name: 'Beatriz Martins', last_message: 'Pode me enviar o contrato de adesão, por favor?', updated_at: '2026-05-28T03:45:00Z' },
  { id: 103, contact_name: 'Lucas Ferreira', last_message: 'Ainda está disponível a promoção de kickoff?', updated_at: '2026-05-28T02:10:00Z' },
  { id: 104, contact_name: 'Fernanda Oliveira', last_message: 'Preciso de um suporte técnico no painel.', updated_at: '2026-05-27T18:30:00Z' }
]

const openLinkerModal = async () => {
  showModal.value = true
  loadingConversations.value = true
  
  try {
    // Tenta carregar as conversas ativas no Chatwoot
    // GET /api/v1/conversations
    const response = await api.get('/api/v1/conversations')
    conversations.value = response.data.data || response.data
  } catch (error) {
    console.warn('Endpoint GET /api/v1/conversations não disponível. Usando fallback mockado.', error)
    // TODO: replace mock
    conversations.value = [...MOCK_CONVERSATIONS]
  } finally {
    loadingConversations.value = false
  }
}

const filteredConversations = computed(() => {
  if (!modalFilter.value.trim()) return conversations.value
  const query = modalFilter.value.toLowerCase()
  return conversations.value.filter(c => 
    c.contact_name.toLowerCase().includes(query) ||
    c.last_message.toLowerCase().includes(query)
  )
})

const handleLink = async (convId) => {
  loading.value = true
  try {
    await pipelineStore.linkConversation(props.card.id, convId)
    toast.success(`Conversa #${convId} vinculada com sucesso!`)
    showModal.value = false
    
    // Atualiza a timeline do card para carregar as mensagens
    await pipelineStore.fetchCardTimeline(pipelineStore.currentPipelineId, props.card.id)
  } catch (error) {
    toast.error('Erro ao vincular conversa.')
  } finally {
    loading.value = false
  }
}

const handleUnlink = async () => {
  loading.value = true
  try {
    await pipelineStore.unlinkConversation(props.card.id)
    toast.success('Conversa desvinculada do card!')
    confirmingUnlink.value = false
    
    // Limpa timeline para remover mensagens do chatwoot se desejado
    await pipelineStore.fetchCardTimeline(pipelineStore.currentPipelineId, props.card.id)
  } catch (error) {
    toast.error('Erro ao desvincular conversa.')
  } finally {
    loading.value = false
  }
}

const formatTime = (isoString) => {
  if (!isoString) return ''
  const date = new Date(isoString)
  const hours = date.getHours().toString().padStart(2, '0')
  const minutes = date.getMinutes().toString().padStart(2, '0')
  return `${hours}:${minutes}`
}
</script>

<style scoped>
@keyframes scaleUp {
  from {
    opacity: 0;
    transform: scale(0.96);
  }
  to {
    opacity: 1;
    transform: scale(1);
  }
}
.animate-scale-up {
  animation: scaleUp 0.16s cubic-bezier(0.16, 1, 0.3, 1) forwards;
}
</style>
