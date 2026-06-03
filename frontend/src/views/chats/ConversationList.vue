<template>
  <div class="flex flex-col h-full bg-white border-r border-gray-150">
    <!-- Header de Busca -->
    <div class="p-4 border-b border-gray-100 shrink-0">
      <div class="relative">
        <span class="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none text-gray-400">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
          </svg>
        </span>
        <input 
          v-model="searchQuery"
          type="text" 
          placeholder="Buscar contato ou conversa..."
          class="w-full pl-9 pr-4 py-2 text-xs border border-gray-200 rounded-xl bg-gray-50/50 focus:outline-none focus:bg-white focus:border-slate-800 focus:ring-1 focus:ring-slate-800 transition-all"
        />
      </div>
    </div>

    <!-- Lista de Conversas -->
    <div class="flex-1 overflow-y-auto divide-y divide-gray-50">
      <!-- Loading State -->
      <div v-if="loading" class="p-4 space-y-3">
        <div v-for="i in 5" :key="i" class="flex items-center space-x-3 animate-pulse">
          <div class="h-10 w-10 bg-gray-200 rounded-full"></div>
          <div class="flex-1 space-y-2">
            <div class="h-3.5 bg-gray-200 rounded w-1/2"></div>
            <div class="h-2.5 bg-gray-200 rounded w-5/6"></div>
          </div>
        </div>
      </div>

      <!-- Empty State -->
      <div v-else-if="filteredConversations.length === 0" class="p-8 text-center text-xs text-gray-400 italic">
        Nenhuma conversa encontrada.
      </div>

      <!-- Itens de Conversa -->
      <div 
        v-else
        v-for="conv in filteredConversations" 
        :key="conv.id"
        @click="selectConversation(conv)"
        class="flex items-center justify-between p-3.5 cursor-pointer transition-all hover:bg-slate-50 relative border-l-2"
        :class="[
          selectedCardId === conv.card_id 
            ? 'bg-sky-50/60 border-sky-500 hover:bg-sky-50/80' 
            : 'border-transparent'
        ]"
      >
        <!-- Conteúdo do Item -->
        <div class="flex items-center space-x-3 min-w-0 flex-1">
          <!-- Avatar Circular -->
          <div class="relative shrink-0 h-10 w-10 rounded-full bg-slate-100 flex items-center justify-center font-bold text-slate-600 border border-slate-200 uppercase text-sm select-none">
            {{ getInitials(conv.contact_name) }}
            <!-- Status indicator (bolinha) se o canal estiver conectado -->
            <span 
              v-if="conv.has_unread"
              class="absolute bottom-0 right-0 h-3 w-3 rounded-full bg-emerald-500 border-2 border-white"
            ></span>
          </div>

          <!-- Nome do Contato & Última Mensagem -->
          <div class="min-w-0 flex-1">
            <div class="flex items-center justify-between">
              <span class="text-xs font-black text-slate-800 truncate">{{ conv.contact_name }}</span>
              <span class="text-[10px] font-medium text-slate-400 shrink-0 pl-1 select-none">
                {{ formatTime(conv.last_message_at) }}
              </span>
            </div>
            
            <p 
              class="text-[11px] truncate mt-0.5"
              :class="conv.has_unread ? 'text-slate-900 font-extrabold' : 'text-slate-450 text-gray-500'"
            >
              {{ conv.last_message }}
            </p>
          </div>
        </div>

        <!-- Indicador de Não Lidas ou Tags -->
        <div class="flex flex-col items-end space-y-1.5 shrink-0 pl-2 select-none">
          <!-- Badge Unread -->
          <span 
            v-if="conv.unread_count > 0"
            class="h-5 min-w-[20px] px-1.5 rounded-full bg-emerald-500 text-white font-extrabold text-[10px] flex items-center justify-center shadow-sm shadow-emerald-500/10"
          >
            {{ conv.unread_count }}
          </span>
          
          <!-- Tipo do Funil / Badge da Etapa -->
          <span 
            v-if="conv.stage_name" 
            class="px-1.5 py-0.5 rounded text-[8px] font-black uppercase tracking-wider text-white shrink-0"
            :style="{ backgroundColor: conv.stage_color || '#64748B' }"
          >
            {{ conv.stage_name }}
          </span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { usePipelineStore } from '@/stores/pipeline'
import api from '@/plugins/axios'

const props = defineProps({
  selectedCardId: {
    type: Number,
    default: null
  }
})

const emits = defineEmits(['select'])

const pipelineStore = usePipelineStore()
const searchQuery = ref('')
const loading = ref(false)
const conversations = ref([])

const getInitials = (name) => {
  if (!name) return '?'
  const parts = name.trim().split(/\s+/)
  if (parts.length === 1) return parts[0].slice(0, 2)
  return (parts[0][0] + parts[parts.length - 1][0]).slice(0, 2)
}

const formatTime = (timeStr) => {
  if (!timeStr) return ''
  const date = new Date(timeStr)
  const today = new Date()
  
  if (date.toDateString() === today.toDateString()) {
    const hh = date.getHours().toString().padStart(2, '0')
    const mm = date.getMinutes().toString().padStart(2, '0')
    return `${hh}:${mm}`
  }
  
  const yesterday = new Date()
  yesterday.setDate(today.getDate() - 1)
  if (date.toDateString() === yesterday.toDateString()) {
    return 'Ontem'
  }
  
  return date.toLocaleDateString('pt-BR', { day: '2-digit', month: '2-digit' })
}

const filteredConversations = computed(() => {
  const q = searchQuery.value.trim().toLowerCase()
  if (!q) return conversations.value
  return conversations.value.filter(c => 
    (c.contact_name || '').toLowerCase().includes(q) || 
    (c.last_message || '').toLowerCase().includes(q)
  )
})

const selectConversation = (conv) => {
  emits('select', conv)
}

const loadConversations = async () => {
  loading.value = true
  try {
    // 1. Tentar GET /api/v1/conversations
    const response = await api.get('/api/v1/conversations?status=open')
    const list = response.data.data || response.data
    conversations.value = list.map(c => ({
      id: c.id,
      card_id: c.card_id,
      pipeline_id: c.pipeline_id,
      contact_name: c.contact_name || `Lead #${c.card_id}`,
      last_message: c.last_message || 'Nenhuma mensagem...',
      last_message_at: c.last_message_at || c.created_at,
      unread_count: c.unread_count || 0,
      has_unread: c.unread_count > 0,
      stage_name: c.stage_name,
      stage_color: c.stage_color
    }))
  } catch (error) {
    console.warn("Rota GET /api/v1/conversations não disponível. Montando lista via fallback de cards.", error)
    
    // Fallback: Busca pipelines e depois carrega os cards de cada pipeline
    try {
      await pipelineStore.fetchPipelines()
      const cardsList = []
      
      for (const pipeline of pipelineStore.pipelines) {
        await pipelineStore.fetchCards(pipeline.id)
        
        // Obter os cards que pertencem a esse pipeline do pipelineStore.cards
        const pipeCards = pipelineStore.cards.filter(c => c.pipeline_id === pipeline.id)
        cardsList.push(...pipeCards)
      }
      
      // Filtrar cards que possuem nome de contato ou telefone (leads válidos para chat)
      const validCards = cardsList.filter(c => c.contact_name || c.contact_phone)
      
      // Mapear para o formato esperado
      conversations.value = validCards.map(c => {
        // Encontra a data mais recente de atividade
        const lastTime = c.updated_at || c.created_at
        
        // Simular mensagens não lidas aleatórias ou com base no metadata do card para fins de teste
        const unreadCount = c.conversation?.unread_count || (c.id % 7 === 0 ? 2 : 0)
        
        return {
          id: c.conversation?.id || c.id,
          card_id: c.id,
          pipeline_id: c.pipeline_id,
          contact_name: c.contact_name || `Lead #${c.id}`,
          last_message: c.custom_fields?.['Última Mensagem'] || 'Clique para visualizar...',
          last_message_at: lastTime,
          unread_count: unreadCount,
          has_unread: unreadCount > 0,
          stage_name: c.stage_name || 'Estágio',
          stage_color: c.stage_color || '#3B82F6'
        }
      })
      
      // Ordenar por última mensagem decrescente (mais recente primeiro)
      conversations.value.sort((a, b) => new Date(b.last_message_at) - new Date(a.last_message_at))
    } catch (e) {
      console.error("Erro no fallback de busca de conversas:", e)
    }
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  loadConversations()
})
</script>
