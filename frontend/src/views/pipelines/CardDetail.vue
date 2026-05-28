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
            <div class="flex items-center justify-between">
              <h3 class="text-xs font-bold text-gray-800 uppercase tracking-wider">Campos Personalizados</h3>
              
              <!-- Indicador de Status do Auto-save -->
              <span v-if="saveStatus" class="text-[10px] font-bold flex items-center transition-all">
                <span v-if="saveStatus === 'salvando'" class="text-slate-500 flex items-center">
                  <svg class="animate-spin h-3 w-3 mr-1 text-slate-500" fill="none" viewBox="0 0 24 24">
                    <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                    <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                  </svg>
                  Salvando...
                </span>
                <span v-else-if="saveStatus === 'salvo'" class="text-emerald-600 flex items-center">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M5 13l4 4L19 7" />
                  </svg>
                  Salvo
                </span>
                <span v-else-if="saveStatus === 'erro'" class="text-rose-600">Erro ao salvar</span>
              </span>
            </div>
            
            <div class="space-y-2">
              <div 
                v-for="(val, key) in localCustomFields" 
                :key="key"
                class="bg-white p-2.5 rounded-xl border border-gray-150 flex flex-col relative group/field shadow-sm hover:border-gray-250 transition-all duration-150"
              >
                <label class="text-[10px] font-bold text-gray-400 uppercase">{{ key }}</label>
                <input 
                  v-model="localCustomFields[key]"
                  type="text"
                  class="text-xs font-semibold text-gray-800 bg-transparent border-0 border-b border-transparent hover:border-gray-250 focus:border-slate-800 focus:outline-none focus:ring-0 w-full mt-0.5 p-0 transition-colors"
                />
                <button 
                  @click="removeField(key)"
                  type="button"
                  class="absolute right-2 top-2 p-1 text-gray-300 hover:text-rose-650 opacity-0 group-hover/field:opacity-100 transition-opacity rounded-lg hover:bg-gray-50"
                >
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                  </svg>
                </button>
              </div>
            </div>

            <!-- Formulário Adicionar Campo -->
            <div class="pt-2">
              <div v-if="isAddingField" class="space-y-2 bg-white p-3 rounded-xl border border-gray-200 shadow-sm animate-fade-in">
                <input 
                  v-model="newFieldKey" 
                  type="text" 
                  placeholder="Nome do campo (ex: CPF)" 
                  class="block w-full px-2.5 py-1.5 text-xs rounded-lg border border-gray-200 bg-gray-50 focus:outline-none focus:border-slate-800"
                />
                <input 
                  v-model="newFieldValue" 
                  type="text" 
                  placeholder="Valor" 
                  class="block w-full px-2.5 py-1.5 text-xs rounded-lg border border-gray-200 bg-gray-50 focus:outline-none focus:border-slate-800"
                />
                <div class="flex items-center justify-end space-x-1.5">
                  <button @click="isAddingField = false" type="button" class="px-2.5 py-1 text-[10px] text-gray-500 hover:text-gray-700">
                    Cancelar
                  </button>
                  <button @click="addNewField" type="button" class="px-2.5 py-1 text-[10px] bg-slate-900 text-white rounded-md font-semibold">
                    Adicionar
                  </button>
                </div>
              </div>
              <button 
                v-else 
                @click="isAddingField = true; newFieldKey = ''; newFieldValue = ''" 
                type="button" 
                class="w-full py-2.5 border border-dashed border-gray-300 hover:border-gray-400 rounded-xl text-xs font-bold text-gray-500 hover:text-gray-750 bg-white transition-all flex items-center justify-center space-x-1.5 shadow-sm"
              >
                <span>+ Adicionar Campo</span>
              </button>
            </div>
            
            <div v-if="!Object.keys(localCustomFields).length && !isAddingField" class="text-xs text-gray-400 italic">
              Nenhum campo personalizado cadastrado.
            </div>
          </div>
        </aside>

        <!-- Coluna Direita / Centro: Timeline de Atividades (Sprint 3) -->
        <section class="flex-1 flex flex-col bg-slate-50/50 overflow-hidden">
          <!-- Area de Mensagens / Chat -->
          <div 
            ref="timelineContainer" 
            class="flex-1 overflow-y-auto p-6 space-y-6 scroll-smooth"
          >
            <!-- Loader da Timeline -->
            <div v-if="pipelineStore.loading.timeline" class="space-y-4">
              <div v-for="i in 3" :key="i" class="h-20 bg-white border border-gray-150 rounded-2xl animate-pulse"></div>
            </div>

            <!-- Se a timeline estiver vazia -->
            <div v-else-if="pipelineStore.cardTimeline.length === 0" class="h-full flex flex-col items-center justify-center text-center text-sm text-gray-400 py-12">
              <component :is="MessageSquare" class="h-10 w-10 text-gray-300 mb-2" />
              <span>Nenhuma atividade ou mensagem registrada.</span>
            </div>

            <!-- Lista Agrupada por Data -->
            <div v-else class="space-y-6">
              <div 
                v-for="(events, dateGroup) in groupedTimeline" 
                :key="dateGroup"
                class="space-y-4"
              >
                <!-- Separador de data do chat -->
                <div class="flex justify-center my-4">
                  <span class="px-3 py-1 bg-gray-200/80 text-gray-600 rounded-full text-[10px] font-bold tracking-wide shadow-sm">
                    {{ dateGroup }}
                  </span>
                </div>

                <!-- Feed do Chat/Eventos -->
                <div class="space-y-3">
                  <template v-for="event in events" :key="event.id">
                    <!-- 1. Renderização de Mensagens (Tipo = message) -->
                    <div 
                      v-if="event.event_type === 'message'"
                      class="flex w-full"
                      :class="[
                        event.message_type === 'outgoing' 
                          ? 'justify-end' 
                          : (event.message_type === 'private' ? 'justify-center' : 'justify-start')
                      ]"
                    >
                      <!-- Bolha de Mensagem Outgoing (Enviada pelo Agente Zavy) -->
                      <div 
                        v-if="event.message_type === 'outgoing'"
                        class="max-w-[70%] bg-slate-900 text-white rounded-2xl rounded-tr-none px-4 py-2.5 shadow-sm space-y-1 relative"
                      >
                        <p class="text-xs leading-relaxed whitespace-pre-wrap">{{ event.content }}</p>
                        <div class="flex items-center justify-end space-x-1 text-[9px] text-slate-350">
                          <span>{{ formatTimeOnly(event.created_at) }}</span>
                          <span class="text-emerald-400">✓✓</span>
                        </div>
                      </div>

                      <!-- Bolha de Mensagem Incoming (Recebida do Cliente) -->
                      <div 
                        v-else-if="event.message_type === 'incoming'"
                        class="max-w-[70%] bg-white border border-gray-200 text-slate-800 rounded-2xl rounded-tl-none px-4 py-2.5 shadow-sm space-y-1.5"
                      >
                        <div class="flex items-center justify-between text-[9px] font-bold text-zavy-600">
                          <span>{{ event.sender_name || card?.contact_name || 'Cliente' }}</span>
                        </div>
                        <p class="text-xs leading-relaxed whitespace-pre-wrap">{{ event.content }}</p>
                        <div class="text-right text-[9px] text-gray-400">
                          {{ formatTimeOnly(event.created_at) }}
                        </div>
                      </div>

                      <!-- Bolha de Nota Interna (Privada) -->
                      <div 
                        v-else-if="event.message_type === 'private'"
                        class="max-w-[85%] bg-amber-50 border border-amber-200 text-amber-900 rounded-2xl px-4 py-3 shadow-inner space-y-1.5 text-left w-full mx-6"
                      >
                        <div class="flex items-center justify-between">
                          <span class="text-[9px] font-bold uppercase tracking-wider text-amber-700 flex items-center space-x-1">
                            <span class="w-1.5 h-1.5 rounded-full bg-amber-500"></span>
                            <span>Nota Interna</span>
                          </span>
                          <span class="text-[9px] text-amber-600 font-medium">{{ formatTimeOnly(event.created_at) }}</span>
                        </div>
                        <p class="text-xs leading-relaxed whitespace-pre-wrap">{{ event.content }}</p>
                        <div class="text-[9px] text-amber-600 font-semibold flex items-center space-x-1">
                          <span>Por: {{ event.user?.name || 'Agente' }}</span>
                        </div>
                      </div>
                    </div>

                    <!-- 2. Renderização de Eventos de Sistema (Criado, Movido, Atualizado) -->
                    <div v-else class="flex justify-center my-2.5">
                      <span class="px-3.5 py-1 bg-gray-200/50 text-gray-500 rounded-full text-[10px] font-semibold flex items-center space-x-1.5 border border-gray-150/40">
                        <component :is="getEventIcon(event.event_type)" class="h-3 w-3 shrink-0 text-gray-400" />
                        <span>{{ event.description }}</span>
                        <span v-if="event.user" class="text-gray-400 font-medium">• por {{ event.user.name }}</span>
                        <span class="text-gray-400 font-medium">• {{ formatTimeOnly(event.created_at) }}</span>
                      </span>
                    </div>
                  </template>
                </div>
              </div>
            </div>
          </div>

          <!-- Compositor de Mensagens / Notas (Sprint 3) -->
          <CardComposer :card="card" @message-sent="scrollToBottom" />
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
import { ref, computed, onMounted, onUnmounted, watch, nextTick } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { usePipelineStore } from '@/stores/pipeline'
import { usePipelineSocket } from '@/composables/usePipelineSocket'
import StageSwitcher from './StageSwitcher.vue'
import LossReasonModal from './LossReasonModal.vue'
import CardComposer from './CardComposer.vue'
import { X, Plus, MoveRight, HelpCircle, FileText, Send, MessageSquare } from 'lucide-vue-next'

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

// Instancia o socket para tempo real
const socket = usePipelineSocket()
const timelineContainer = ref(null)

const loadTimeline = async () => {
  if (route.params.id && cardId.value) {
    await pipelineStore.fetchCardTimeline(route.params.id, cardId.value)
    scrollToBottom()
  }
}

// Escuta teclado Esc para fechar
const handleKeyDown = (e) => {
  if (e.key === 'Escape') {
    closeDetail()
  }
}

const onNewMessageReceived = () => {
  scrollToBottom()
}

onMounted(() => {
  window.addEventListener('keydown', handleKeyDown)
  loadTimeline()
  
  // Conecta ao ActionCable via WebSocket para updates em tempo real
  if (route.params.id) {
    socket.connect(route.params.id, cardId.value)
  }

  // Escuta evento customizado de nova mensagem para fazer scroll
  window.addEventListener('zavy-new-message', onNewMessageReceived)
})

onUnmounted(() => {
  window.removeEventListener('keydown', handleKeyDown)
  window.removeEventListener('zavy-new-message', onNewMessageReceived)
  socket.disconnect()
})

const scrollToBottom = () => {
  nextTick(() => {
    if (timelineContainer.value) {
      timelineContainer.value.scrollTop = timelineContainer.value.scrollHeight
    }
  })
}

// Rola para baixo sempre que a timeline mudar
watch(() => pipelineStore.cardTimeline, () => {
  scrollToBottom()
}, { deep: true })

// Extrai apenas a hora e minuto formatados
const formatTimeOnly = (isoString) => {
  if (!isoString) return ''
  const date = new Date(isoString)
  const hours = date.getHours().toString().padStart(2, '0')
  const minutes = date.getMinutes().toString().padStart(2, '0')
  return `${hours}:${minutes}`
}

// Agrupador e formatador de datas da timeline
const getFriendlyDateKey = (dateStr) => {
  const date = new Date(dateStr)
  const today = new Date()
  const yesterday = new Date()
  yesterday.setDate(today.getDate() - 1)
  
  if (date.toDateString() === today.toDateString()) {
    return 'Hoje'
  } else if (date.toDateString() === yesterday.toDateString()) {
    return 'Ontem'
  } else {
    return date.toLocaleDateString('pt-BR', { day: 'numeric', month: 'long' })
  }
}

const groupedTimeline = computed(() => {
  const groups = {}
  pipelineStore.cardTimeline.forEach(event => {
    const dateKey = getFriendlyDateKey(event.created_at)
    if (!groups[dateKey]) {
      groups[dateKey] = []
    }
    groups[dateKey].push(event)
  })
  return groups
})

// --- LÓGICA DE CAMPOS PERSONALIZADOS (DIA 9) ---
const localCustomFields = ref({})
const saveStatus = ref('') // '', 'salvando', 'salvo', 'erro'
const isAddingField = ref(false)
const newFieldKey = ref('')
const newFieldValue = ref('')

// Sincroniza custom fields locais do card da store
watch(() => card.value, (newCard) => {
  if (newCard) {
    localCustomFields.value = { ...newCard.custom_fields }
  } else {
    localCustomFields.value = {}
  }
}, { immediate: true, deep: true })

let autoSaveTimeout = null

// Dispara o salvamento automático com de-bounce de 700ms
const triggerAutoSave = () => {
  saveStatus.value = 'salvando'
  
  if (autoSaveTimeout) {
    clearTimeout(autoSaveTimeout)
  }
  
  autoSaveTimeout = setTimeout(async () => {
    try {
      await pipelineStore.updateCard(cardId.value, {
        custom_fields: { ...localCustomFields.value }
      })
      saveStatus.value = 'salvo'
      
      // Limpa indicador de salvo após 2 segundos
      setTimeout(() => {
        if (saveStatus.value === 'salvo') {
          saveStatus.value = ''
        }
      }, 2000)
    } catch (error) {
      saveStatus.value = 'erro'
    }
  }, 700)
}

// Watcher com verificação profunda para salvar apenas se houver mudanças reais
watch(localCustomFields, (newVal) => {
  if (!card.value) return
  
  const storeFields = card.value.custom_fields || {}
  
  // Verifica diferença chave-valor
  const hasChanges = Object.keys(newVal).some(key => newVal[key] !== storeFields[key]) ||
                     Object.keys(storeFields).some(key => newVal[key] !== storeFields[key])
                     
  if (hasChanges) {
    triggerAutoSave()
  }
}, { deep: true })

const addNewField = () => {
  const key = newFieldKey.value.trim()
  const val = newFieldValue.value.trim()
  if (key && val) {
    localCustomFields.value[key] = val
    isAddingField.value = false
    newFieldKey.value = ''
    newFieldValue.value = ''
  }
}

const removeField = (key) => {
  delete localCustomFields.value[key]
}
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
