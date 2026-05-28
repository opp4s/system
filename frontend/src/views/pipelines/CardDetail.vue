<template>
  <div class="fixed inset-0 z-50 flex justify-end">
    <!-- Backdrop de Fundo -->
    <div 
      @click="closeDetail"
      class="absolute inset-0 bg-slate-900/40 backdrop-blur-sm transition-opacity duration-300"
    ></div>

    <!-- Painel Slide-in Lateral (ocupando 70% de largura no desktop) -->
    <div 
      class="relative w-full md:w-[70vw] lg:w-[65vw] h-full bg-white shadow-2xl flex flex-col z-10 animate-slide-in-right transition-transform duration-300"
    >
      <!-- Header do Slide-in -->
      <header class="h-16 px-6 border-b border-gray-100 flex items-center justify-between shrink-0 bg-gray-50/50">
        <div class="flex items-center space-x-3">
          <span class="px-2.5 py-1 text-xs font-bold bg-slate-950 text-white rounded-lg">Negócio #{{ cardId }}</span>
          <span class="text-gray-400">/</span>
          <span class="text-sm font-semibold text-gray-500">Detalhes do Lead</span>
        </div>

        <button 
          @click="closeDetail"
          class="p-2 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-xl transition-all duration-150"
        >
          <component :is="X" class="h-5 w-5" />
        </button>
      </header>

      <!-- Corpo do Detalhe -->
      <div v-if="card" class="flex-1 flex flex-col md:flex-row overflow-hidden">
        <!-- Coluna Esquerda: Dados do Card (Painel de 320px) -->
        <aside class="w-full md:w-80 border-b md:border-b-0 md:border-r border-gray-100 overflow-y-auto p-6 flex flex-col space-y-6 bg-gray-50/30">
          <!-- Título do negócio -->
          <div>
            <label class="text-[10px] font-bold text-gray-400 uppercase tracking-wider">Título do Negócio</label>
            <h2 class="text-base font-bold text-gray-900 mt-1">{{ card.title }}</h2>
          </div>

          <!-- Estágio Atual (StageSwitcher integrado) -->
          <div>
            <label class="text-[10px] font-bold text-gray-400 uppercase tracking-wider block mb-1.5">Etapa do Funil</label>
            <StageSwitcher 
              :active-stage-id="card.stage_id"
              @change-stage="handleStageChange"
            />
          </div>

          <!-- Valor e Moeda -->
          <div>
            <label class="text-[10px] font-bold text-gray-400 uppercase tracking-wider">Valor da Oportunidade</label>
            <div class="text-lg font-extrabold text-gray-900 mt-0.5">
              {{ formatCurrency(card.value, card.currency) }}
            </div>
          </div>

          <!-- Separador -->
          <div class="border-t border-gray-100"></div>

          <!-- Dados do Contato Principal -->
          <div class="space-y-4">
            <h3 class="text-xs font-bold text-gray-800 uppercase tracking-wider">Contato Principal</h3>
            
            <div>
              <label class="text-[10px] font-bold text-gray-400 uppercase">Nome</label>
              <div class="text-sm font-semibold text-gray-800 mt-0.5">{{ card.contact_name || 'Não informado' }}</div>
            </div>

            <div>
              <label class="text-[10px] font-bold text-gray-400 uppercase">Telefone</label>
              <div class="text-sm font-medium text-gray-800 mt-0.5">{{ card.contact_phone || 'Não informado' }}</div>
            </div>

            <div>
              <label class="text-[10px] font-bold text-gray-400 uppercase">E-mail</label>
              <div class="text-sm font-medium text-gray-800 mt-0.5 break-all">{{ card.contact_email || 'Não informado' }}</div>
            </div>
          </div>

          <!-- Separador -->
          <div class="border-t border-gray-100"></div>

          <!-- Campos Personalizados (Custom Fields) -->
          <div class="space-y-4">
            <h3 class="text-xs font-bold text-gray-800 uppercase tracking-wider">Campos Personalizados</h3>
            
            <div 
              v-for="(val, key) in card.custom_fields" 
              :key="key"
              class="bg-white p-2.5 rounded-xl border border-gray-150"
            >
              <label class="text-[10px] font-bold text-gray-400 uppercase block">{{ key }}</label>
              <span class="text-xs font-semibold text-gray-700 block mt-0.5">{{ val }}</span>
            </div>
            
            <div v-if="!Object.keys(card.custom_fields || {}).length" class="text-xs text-gray-400 italic">
              Nenhum campo personalizado cadastrado.
            </div>
          </div>
        </aside>

        <!-- Coluna Direita / Centro: Timeline de Atividades -->
        <section class="flex-1 flex flex-col bg-white overflow-hidden">
          <!-- Timeline Area -->
          <div class="flex-1 overflow-y-auto p-6 space-y-6">
            <div class="flex items-center justify-between">
              <h3 class="text-sm font-bold text-gray-800 uppercase tracking-wider">Histórico de Atividades</h3>
            </div>

            <!-- Loader da Timeline -->
            <div v-if="pipelineStore.loading.timeline" class="space-y-4">
              <div v-for="i in 3" :key="i" class="h-20 bg-gray-50 border border-gray-100 rounded-2xl animate-pulse"></div>
            </div>

            <!-- Lista de Atividades do Negócio -->
            <div v-else class="relative pl-6 border-l-2 border-slate-100 space-y-6">
              <div 
                v-for="event in pipelineStore.cardTimeline"
                :key="event.id"
                class="relative"
              >
                <!-- Ícone correspondente ao evento -->
                <span 
                  class="absolute -left-[31px] top-1 text-white rounded-full p-1 border-2 border-white"
                  :class="getEventIconBg(event.event_type)"
                >
                  <component :is="getEventIcon(event.event_type)" class="h-3 w-3" />
                </span>

                <!-- Caixa do Evento -->
                <div class="bg-gray-50 border border-gray-100 rounded-2xl p-4 hover:shadow-sm transition-shadow duration-150">
                  <div class="flex items-center justify-between">
                    <span class="text-xs font-bold text-gray-900">{{ event.title }}</span>
                    <span class="text-[10px] text-gray-400 font-medium">{{ formatEventDate(event.created_at) }}</span>
                  </div>
                  <p class="text-xs text-gray-600 mt-1">{{ event.description }}</p>
                  
                  <!-- Usuário que realizou a ação -->
                  <div v-if="event.user" class="text-[10px] text-gray-400 font-semibold mt-2 flex items-center space-x-1">
                    <span class="w-1.5 h-1.5 rounded-full bg-slate-400"></span>
                    <span>Realizado por: {{ event.user.name }}</span>
                  </div>
                </div>
              </div>

              <!-- Se a timeline estiver vazia -->
              <div v-if="pipelineStore.cardTimeline.length === 0" class="text-center py-8 text-sm text-gray-400">
                Nenhuma atividade registrada para este negócio.
              </div>
            </div>
          </div>

          <!-- Compositor de Mensagens / Notas (Footer placeholder) -->
          <footer class="p-4 border-t border-gray-150 bg-gray-50/50">
            <div class="flex items-center space-x-2">
              <input 
                type="text" 
                placeholder="Escreva uma nota interna ou envie mensagem..." 
                disabled
                class="flex-1 bg-white border border-gray-200 rounded-xl px-4 py-2.5 text-sm focus:outline-none cursor-not-allowed opacity-60" 
              />
              <button 
                disabled 
                class="p-2.5 bg-slate-900 text-white rounded-xl cursor-not-allowed opacity-50"
              >
                <component :is="Send" class="h-4 w-4" />
              </button>
            </div>
            <p class="text-[10px] text-center text-gray-400 mt-1.5">
              Composer de mensagens funcional a partir do Sprint 3 (Canais de Chat).
            </p>
          </footer>
        </section>
      </div>

      <!-- Loader caso o card esteja sendo carregado -->
      <div v-else class="flex-1 flex items-center justify-center">
        <span class="text-sm text-gray-500">Buscando informações do card...</span>
      </div>
    </div>

    <!-- Modal de Motivo de Perda interno do detalhe -->
    <LossReasonModal
      :show="showLossModal"
      :card-title="card?.title"
      @confirm="handleConfirmLoss"
      @cancel="handleCancelLoss"
    />
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { usePipelineStore } from '@/stores/pipeline'
import StageSwitcher from './StageSwitcher.vue'
import LossReasonModal from './LossReasonModal.vue'
import { X, Plus, MoveRight, HelpCircle, FileText, Send } from 'lucide-vue-next'

const route = useRoute()
const router = useRouter()
const pipelineStore = usePipelineStore()

const cardId = computed(() => Number(route.params.cardId))

const card = computed(() => {
  return pipelineStore.cards.find(c => c.id === cardId.value)
})

// Modal de perda e estágio pendente
const showLossModal = ref(false)
const pendingStageChange = ref(null)

const formatCurrency = (value, currency = 'BRL') => {
  if (value === undefined || value === null) return 'R$ 0,00'
  return new Intl.NumberFormat('pt-BR', {
    style: 'currency',
    currency: currency
  }).format(value)
}

// Retorna ícone conforme o tipo de evento
const getEventIcon = (type) => {
  switch (type) {
    case 'card_created': return Plus
    case 'card_moved': return MoveRight
    case 'card_updated': return FileText
    default: return HelpCircle
  }
}

// Retorna cor do ícone conforme o tipo de evento
const getEventIconBg = (type) => {
  switch (type) {
    case 'card_created': return 'bg-emerald-500'
    case 'card_moved': return 'bg-blue-500'
    case 'card_updated': return 'bg-amber-500'
    default: return 'bg-slate-500'
  }
}

// Formatação amigável das datas da timeline em português
const formatEventDate = (isoString) => {
  if (!isoString) return ''
  const date = new Date(isoString)
  const today = new Date()
  const yesterday = new Date(today)
  yesterday.setDate(yesterday.getDate() - 1)

  const hours = date.getHours().toString().padStart(2, '0')
  const minutes = date.getMinutes().toString().padStart(2, '0')

  if (date.toDateString() === today.toDateString()) {
    return `Hoje às ${hours}:${minutes}`
  } else if (date.toDateString() === yesterday.toDateString()) {
    return `Ontem às ${hours}:${minutes}`
  } else {
    const day = date.getDate().toString().padStart(2, '0')
    const month = (date.getMonth() + 1).toString().padStart(2, '0')
    const year = date.getFullYear()
    return `${day}/${month}/${year} às ${hours}:${minutes}`
  }
}

const closeDetail = () => {
  router.push({
    name: 'pipelines-detail',
    params: { id: route.params.id }
  })
}

// Gerencia mudança de etapa via switcher
const handleStageChange = async (targetStageId) => {
  if (!card.value) return
  const targetStage = pipelineStore.stages.find(s => s.id === targetStageId)

  if (targetStage && targetStage.stage_type === 'lose') {
    pendingStageChange.value = targetStageId
    showLossModal.value = true
  } else {
    try {
      await pipelineStore.moveCard(card.value.id, card.value.stage_id, targetStageId, 0)
      // Atualiza a timeline após mover
      await pipelineStore.fetchCardTimeline(route.params.id, cardId.value)
    } catch (error) {
      // Rollback na store
    }
  }
}

// Confirma perda do lead e atualiza a timeline
const handleConfirmLoss = async (reason) => {
  if (!card.value || !pendingStageChange.value) return
  const targetStageId = pendingStageChange.value
  showLossModal.value = false

  try {
    await pipelineStore.moveCard(card.value.id, card.value.stage_id, targetStageId, 0)
    
    // Atualiza justificativa nos custom fields
    const cardIdx = pipelineStore.cards.findIndex(c => c.id === card.value.id)
    if (cardIdx !== -1) {
      if (!pipelineStore.cards[cardIdx].custom_fields) {
        pipelineStore.cards[cardIdx].custom_fields = {}
      }
      pipelineStore.cards[cardIdx].custom_fields['Motivo da Perda'] = reason
    }

    // Atualiza a timeline
    await pipelineStore.fetchCardTimeline(route.params.id, cardId.value)
  } catch (error) {
    // Rollback na store
  } finally {
    pendingStageChange.value = null
  }
}

const handleCancelLoss = () => {
  showLossModal.value = false
  pendingStageChange.value = null
}

const loadTimeline = async () => {
  if (route.params.id && cardId.value) {
    await pipelineStore.fetchCardTimeline(route.params.id, cardId.value)
  }
}

// Escuta teclado Esc para fechar
const handleKeyDown = (e) => {
  if (e.key === 'Escape') {
    closeDetail()
  }
}

onMounted(() => {
  window.addEventListener('keydown', handleKeyDown)
  loadTimeline()
})

// Recarrega timeline caso mude o card selecionado
watch(cardId, () => {
  loadTimeline()
})
</script>

<style scoped>
@keyframes slideInRight {
  from {
    transform: translateX(100%);
  }
  to {
    transform: translateX(0);
  }
}
.animate-slide-in-right {
  animation: slideInRight 0.25s cubic-bezier(0.16, 1, 0.3, 1) forwards;
}
</style>
