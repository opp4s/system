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
        v-for="stage in pipelineStore.visibleStages"
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
              {{ (localCards[stage.id] || []).length }}
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

        <!-- Lista de Cards da Etapa (Drag-and-Drop integrado) -->
        <div class="flex-1 flex flex-col overflow-hidden relative">
          <draggable
            v-model="localCards[stage.id]"
            group="cards"
            item-key="id"
            @change="onDragChange($event, stage.id)"
            class="flex-1 overflow-y-auto p-3 space-y-3 min-h-[150px] custom-scrollbar"
            ghost-class="opacity-30"
            drag-class="rotate-1"
            animation="200"
            :scroll="true"
            :scroll-sensitivity="100"
            :scroll-speed="20"
          >
            <template #item="{ element: card }">
              <div
                @click="openCardDetail(card.id)"
                class="bg-white border border-gray-200 hover:border-slate-350 rounded-xl p-4 shadow-sm hover:shadow transition-all duration-200 cursor-pointer flex flex-col space-y-3 group select-none active:cursor-grabbing"
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
                  <h4 class="text-sm font-bold text-gray-900 group-hover:text-slate-700 transition-colors duration-150">
                    {{ card.title }}
                  </h4>
                </div>

                <!-- Contato e Conexão de Conversa -->
                <div v-if="card.contact_name" class="flex items-center justify-between text-xs text-gray-500">
                  <div class="flex items-center space-x-1.5 min-w-0">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 text-gray-400 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                    </svg>
                    <span class="truncate font-medium text-gray-700">{{ card.contact_name }}</span>
                  </div>
                  
                  <!-- Ícone de WhatsApp se o card possui conversa vinculada -->
                  <div 
                    v-if="card.conversation_id" 
                    class="flex items-center text-emerald-600 bg-emerald-50 px-1.5 py-0.5 rounded text-[10px] font-bold shrink-0 space-x-0.5"
                    title="WhatsApp Vinculado"
                  >
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 text-emerald-650" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
                    </svg>
                    <span>Zap</span>
                  </div>
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
            </template>
          </draggable>

          <!-- Coluna Vazia Placeholder -->
          <div 
            v-if="!localCards[stage.id] || localCards[stage.id].length === 0" 
            class="absolute inset-x-3 top-3 pointer-events-none border border-dashed border-gray-300 rounded-xl flex items-center justify-center text-xs text-gray-400 h-24"
          >
            Nenhum card nesta etapa
          </div>
        </div>
      </div>
    </div>

    <!-- Modal de Motivo de Perda -->
    <LossReasonModal
      :show="showLossModal"
      :card-title="pendingMove?.cardTitle"
      @confirm="handleConfirmLoss"
      @cancel="handleCancelLoss"
    />

    <!-- Rota aninhada para Slide-in de Detalhes do Card -->
    <router-view />
  </div>
</template>

<script setup>
import { ref, watch, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { usePipelineStore } from '@/stores/pipeline'
import draggable from 'vuedraggable'
import LossReasonModal from './LossReasonModal.vue'

const route = useRoute()
const router = useRouter()
const pipelineStore = usePipelineStore()

// Cartões agrupados locais editáveis pelo draggable
const localCards = ref({})

// Modal de perda e movimentação pendente
const showLossModal = ref(false)
const pendingMove = ref(null)

const formatCurrency = (value, currency = 'BRL') => {
  if (value === undefined || value === null) return 'R$ 0,00'
  return new Intl.NumberFormat('pt-BR', {
    style: 'currency',
    currency: currency
  }).format(value)
}

const getStageTotal = (stageId) => {
  const cards = localCards.value[stageId] || []
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

// Sincroniza dados locais com a store do Pinia
const syncLocalCards = () => {
  pipelineStore.stages.forEach(stage => {
    localCards.value[stage.id] = pipelineStore.cards.filter(c => c.stage_id === stage.id)
  })
}

// Escuta mudanças nos cards da store
watch(() => pipelineStore.cards, () => {
  syncLocalCards()
}, { deep: true })

// Escuta mudanças nas etapas (ex: ao trocar de pipeline)
watch(() => pipelineStore.stages, () => {
  syncLocalCards()
}, { deep: true, immediate: true })

// Handler para manipulação de drag-and-drop
const onDragChange = async (event, targetStageId) => {
  if (event.added) {
    const card = event.added.element
    const newIndex = event.added.newIndex
    const fromStageId = card.stage_id

    const targetStage = pipelineStore.stages.find(s => s.id === targetStageId)

    if (targetStage && targetStage.stage_type === 'lose') {
      // Se for dropado em coluna "lost" (Perdido), abre o modal
      pendingMove.value = {
        cardId: card.id,
        cardTitle: card.title,
        fromStageId,
        toStageId: targetStageId,
        newIndex
      }
      showLossModal.value = true
    } else {
      // Se for etapa padrão ou ganha, envia direto
      try {
        await pipelineStore.moveCard(card.id, fromStageId, targetStageId, newIndex)
      } catch (error) {
        // Rollback automático disparado pela reatividade da store + watch
      }
    }
  }
}

// Confirma perda do lead e salva a justificativa nos custom fields
const handleConfirmLoss = async (reason) => {
  if (!pendingMove.value) return
  const { cardId, fromStageId, toStageId, newIndex } = pendingMove.value
  
  showLossModal.value = false

  try {
    // 1. Move o card no backend
    await pipelineStore.moveCard(cardId, fromStageId, toStageId, newIndex)
    
    // 2. Registra o motivo de perda nos custom fields do card
    const cardIdx = pipelineStore.cards.findIndex(c => c.id === cardId)
    if (cardIdx !== -1) {
      if (!pipelineStore.cards[cardIdx].custom_fields) {
        pipelineStore.cards[cardIdx].custom_fields = {}
      }
      pipelineStore.cards[cardIdx].custom_fields['Motivo da Perda'] = reason
    }
  } catch (error) {
    // Rollback feito na store
  } finally {
    pendingMove.value = null
  }
}

// Cancela o modal de perda e reverte a movimentação visual
const handleCancelLoss = () => {
  syncLocalCards()
  showLossModal.value = false
  pendingMove.value = null
}

onMounted(() => {
  syncLocalCards()
})
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

/* Otimização da velocidade de rolagem interna das colunas */
.custom-scrollbar {
  scrollbar-width: thin;
  scrollbar-color: #cbd5e1 #f1f5f9;
}
</style>
