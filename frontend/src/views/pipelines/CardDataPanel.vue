<template>
  <aside class="w-full h-full overflow-y-auto p-5 flex flex-col space-y-5 bg-gray-50/30">
    
    <!-- Seletor de Tabs (Dados, Campos, Histórico) -->
    <div class="flex border-b border-gray-200 shrink-0 bg-transparent -mx-5 px-5">
      <button 
        v-for="tab in ['dados', 'campos', 'historico']" 
        :key="tab"
        @click="activeTab = tab"
        class="pb-2.5 text-xs font-black uppercase tracking-wider border-b-2 transition-all mr-5 focus:outline-none"
        :class="activeTab === tab ? 'border-slate-900 text-slate-900' : 'border-transparent text-gray-400 hover:text-gray-600'"
      >
        {{ tab === 'dados' ? 'Dados' : tab === 'campos' ? 'Campos' : 'Histórico' }}
      </button>
    </div>

    <!-- TAB 1: DADOS PRINCIPAIS -->
    <div v-if="activeTab === 'dados' && card" class="space-y-3 flex-1">
      <!-- Título do negócio -->
      <div class="border-b border-slate-100 pb-3 mb-3">
        <label class="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">Título do Negócio</label>
        <div v-if="!isEditingTitle" @click="isEditingTitle = true" class="text-xs font-semibold text-slate-850 cursor-pointer hover:bg-slate-100/60 px-2 py-1 rounded-lg min-h-[1.75rem] flex items-center transition-colors">
          {{ card.title }}
        </div>
        <input
          v-else
          v-model="editingTitle"
          @blur="saveTitle"
          @keyup.enter="saveTitle"
          type="text"
          autofocus
          class="text-xs font-semibold text-slate-850 w-full border border-slate-200 focus:outline-none focus:border-slate-800 rounded-xl px-2.5 py-1 bg-white"
        />
      </div>

      <!-- Estágio Atual (StageSwitcher integrado) -->
      <div class="border-b border-slate-100 pb-3 mb-3">
        <label class="text-[10px] font-bold text-slate-400 uppercase tracking-wider block mb-1">Etapa do Funil</label>
        <StageSwitcher 
          :active-stage-id="card.stage_id"
          @change-stage="handleStageChange"
        />
      </div>

      <!-- Valor e Moeda -->
      <div class="border-b border-slate-100 pb-3 mb-3">
        <label class="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">Valor da Oportunidade</label>
        <div v-if="!isEditingValue" @click="isEditingValue = true" class="text-xs font-semibold text-slate-850 cursor-pointer hover:bg-slate-100/60 px-2 py-1 rounded-lg min-h-[1.75rem] flex items-center transition-colors">
          {{ formatCurrency(card.value, card.currency) }}
        </div>
        <div v-else class="flex items-center space-x-1.5">
          <span class="text-xs font-bold text-slate-400">R$</span>
          <input
            v-model.number="editingValue"
            @blur="saveValue"
            @keyup.enter="saveValue"
            type="number"
            autofocus
            class="text-xs font-semibold text-slate-850 w-full border border-slate-200 focus:outline-none focus:border-slate-800 rounded-xl px-2.5 py-1 bg-white"
          />
        </div>
      </div>

      <!-- Dados do Contato Principal -->
      <div class="space-y-3">
        <div class="flex items-center justify-between pb-1">
          <h3 class="text-xs font-bold text-slate-850 uppercase tracking-wider">Contato Principal</h3>
          <span v-if="contactSaveStatus" class="text-[9px] font-bold text-emerald-600 bg-emerald-50 px-2 py-0.5 rounded-full">
            {{ contactSaveStatus }}
          </span>
        </div>
        
        <div class="border-b border-slate-100 pb-3 mb-3">
          <label class="text-[10px] font-bold text-slate-400 uppercase block">Nome</label>
          <div v-if="!isEditingContactName" @click="isEditingContactName = true" class="text-xs font-semibold text-slate-850 cursor-pointer hover:bg-slate-100/60 px-2 py-1 rounded-lg min-h-[1.75rem] flex items-center transition-colors">
            {{ card.contact_name || 'Não informado (clique para editar)' }}
          </div>
          <input
            v-else
            v-model="editingContactName"
            @blur="saveContactName"
            @keyup.enter="saveContactName"
            type="text"
            autofocus
            class="text-xs font-semibold text-slate-850 w-full border border-slate-200 focus:outline-none focus:border-slate-800 rounded-xl px-2.5 py-1 bg-white"
          />
        </div>

        <div class="border-b border-slate-100 pb-3 mb-3">
          <label class="text-[10px] font-bold text-slate-400 uppercase block">Telefone</label>
          <div v-if="!isEditingContactPhone" @click="isEditingContactPhone = true" class="text-xs font-semibold text-slate-850 cursor-pointer hover:bg-slate-100/60 px-2 py-1 rounded-lg min-h-[1.75rem] flex items-center justify-between transition-colors group/phone">
            <span>{{ card.contact_phone || 'Não informado (clique para editar)' }}</span>
            <button @click.stop="addSecondaryPhone" class="p-1 opacity-0 group-hover/phone:opacity-100 hover:bg-slate-200 rounded text-slate-500 transition-all" title="Adicionar telefone secundário">
              <component :is="Plus" class="h-3 w-3" />
            </button>
          </div>
          <input
            v-else
            v-model="editingContactPhone"
            @blur="saveContactPhone"
            @keyup.enter="saveContactPhone"
            type="text"
            autofocus
            class="text-xs font-semibold text-slate-850 w-full border border-slate-200 focus:outline-none focus:border-slate-800 rounded-xl px-2.5 py-1 bg-white"
          />
        </div>

        <div class="border-b border-slate-100 pb-3 mb-3">
          <label class="text-[10px] font-bold text-slate-400 uppercase block">E-mail</label>
          <div v-if="!isEditingContactEmail" @click="isEditingContactEmail = true" class="text-xs font-semibold text-slate-850 cursor-pointer hover:bg-slate-100/60 px-2 py-1 rounded-lg min-h-[1.75rem] flex items-center justify-between transition-colors group/email">
            <span class="break-all">{{ card.contact_email || 'Não informado (clique para editar)' }}</span>
            <button @click.stop="addSecondaryEmail" class="p-1 opacity-0 group-hover/email:opacity-100 hover:bg-slate-200 rounded text-slate-500 transition-all" title="Adicionar e-mail secundário">
              <component :is="Plus" class="h-3 w-3" />
            </button>
          </div>
          <input
            v-else
            v-model="editingContactEmail"
            @blur="saveContactEmail"
            @keyup.enter="saveContactEmail"
            type="email"
            autofocus
            class="text-xs font-semibold text-slate-850 w-full border border-slate-200 focus:outline-none focus:border-slate-800 rounded-xl px-2.5 py-1 bg-white"
          />
        </div>
      </div>
      
      <!-- Canal de Comunicação -->
      <div class="border-t border-slate-100 pt-4 mt-4">
        <h3 class="text-xs font-bold text-slate-850 uppercase tracking-wider mb-2">Canal de Comunicação</h3>
        
        <div v-if="card.whatsapp_instance" class="space-y-1">
          <div class="flex items-center space-x-1.5 text-xs font-semibold text-slate-800">
            <span>📱</span>
            <span>{{ formatPhone(card.whatsapp_instance.phone || card.whatsapp_instance.phone_number) }}</span>
          </div>
          
          <div class="flex items-center space-x-1.5 pl-5 text-[11px] text-slate-500">
            <span v-if="card.whatsapp_instance.name" class="font-medium">{{ card.whatsapp_instance.name }}</span>
            <span v-if="card.whatsapp_instance.name">•</span>
            <div class="flex items-center space-x-1">
              <span 
                class="w-2 h-2 rounded-full inline-block"
                :class="card.whatsapp_instance.status === 'connected' ? 'bg-green-500' : 'bg-red-500'"
              ></span>
              <span :class="card.whatsapp_instance.status === 'connected' ? 'text-green-700' : 'text-red-500 font-semibold'">
                {{ card.whatsapp_instance.status === 'connected' ? 'Conectado' : 'Desconectado' }}
              </span>
            </div>
          </div>
        </div>
        
        <div v-else class="text-xs text-slate-400 italic pl-1">
          Canal não definido
        </div>
      </div>
    </div>

    <!-- TAB 2: CAMPOS PERSONALIZADOS (TIPADOS) -->
    <div v-else-if="activeTab === 'campos'" class="space-y-4 flex-1">
      <div class="flex items-center justify-between">
        <h3 class="text-xs font-bold text-gray-800 uppercase tracking-wider">Campos Definidos</h3>
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
        </span>
      </div>

      <!-- Lista de Campos Baseados nas Definições do Funil -->
      <div class="space-y-3 pt-2">
        <div 
          v-for="field in pipelineStore.customFields" 
          :key="field.id"
          class="border-b border-slate-100 pb-3 mb-3"
        >
          <label class="text-[10px] font-bold text-slate-400 uppercase tracking-wider block mb-1">{{ field.name }}</label>
          
          <!-- Tipo: text -->
          <input 
            v-if="field.field_type === 'text'"
            v-model="localCustomFields[field.name]"
            type="text"
            @blur="triggerAutoSave"
            class="block w-full px-2.5 py-1 rounded-xl border border-slate-200 focus:outline-none focus:border-slate-800 text-xs text-slate-850 transition-all bg-white"
            placeholder="Preencher texto..."
          />

          <!-- Tipo: number -->
          <input 
            v-else-if="field.field_type === 'number'"
            v-model.number="localCustomFields[field.name]"
            type="number"
            @blur="triggerAutoSave"
            class="block w-full px-2.5 py-1 rounded-xl border border-slate-200 focus:outline-none focus:border-slate-800 text-xs text-slate-850 transition-all bg-white"
            placeholder="0"
          />

          <!-- Tipo: select -->
          <select 
            v-else-if="field.field_type === 'select'"
            v-model="localCustomFields[field.name]"
            @change="triggerAutoSave"
            class="block w-full px-2.5 py-1 rounded-xl border border-slate-200 focus:outline-none focus:border-slate-800 text-xs text-slate-850 transition-all bg-white"
          >
            <option :value="undefined">Selecione...</option>
            <option v-for="opt in field.options" :key="opt" :value="opt">{{ opt }}</option>
          </select>

          <!-- Tipo: boolean -->
          <div v-else-if="field.field_type === 'boolean'" class="flex items-center space-x-2 py-1">
            <input 
              v-model="localCustomFields[field.name]"
              type="checkbox"
              @change="triggerAutoSave"
              class="h-4 w-4 rounded border-gray-300 text-slate-900 focus:ring-slate-900"
            />
            <span class="text-xs text-gray-650 font-semibold">Sim / Confirmado</span>
          </div>

          <!-- Tipo: date -->
          <input 
            v-else-if="field.field_type === 'date'"
            v-model="localCustomFields[field.name]"
            type="date"
            @change="triggerAutoSave"
            class="block w-full px-2.5 py-1 rounded-xl border border-slate-200 focus:outline-none focus:border-slate-800 text-xs text-slate-850 transition-all bg-white"
          />
        </div>

        <!-- Lista vazia state -->
        <div v-if="pipelineStore.customFields.length === 0" class="text-center py-8 text-xs text-gray-400 italic">
          Nenhum campo personalizado definido para este funil nas configurações.
        </div>
      </div>
    </div>

    <!-- TAB 3: HISTÓRICO DE EVENTOS -->
    <div v-else-if="activeTab === 'historico'" class="space-y-3.5 flex-1 overflow-y-auto">
      <h3 class="text-xs font-bold text-gray-800 uppercase tracking-wider mb-2">Auditoria do Lead</h3>
      
      <div class="space-y-3 max-h-[400px] overflow-y-auto pr-1">
        <div 
          v-for="event in systemEvents" 
          :key="event.id" 
          class="p-3 bg-white rounded-2xl border border-gray-150 shadow-sm space-y-1.5 transition-all"
        >
          <div class="flex items-center space-x-2 text-[9px] text-gray-400 font-bold uppercase tracking-wider">
            <component :is="getEventIcon(event.event_type)" class="h-3.5 w-3.5 text-gray-400" />
            <span>{{ formatFriendlyDate(event.created_at) }}</span>
          </div>
          <p class="text-xs text-slate-750 font-semibold leading-normal">{{ event.description }}</p>
          <p v-if="event.user" class="text-[9px] text-gray-400 font-semibold">Alterado por: {{ event.user.name }}</p>
        </div>
        
        <div v-if="systemEvents.length === 0" class="text-center py-10 text-xs text-gray-400 italic">
          Nenhum histórico registrado no sistema.
        </div>
      </div>
    </div>

    <!-- Modal de Motivo de Perda interno do painel -->
    <LossReasonModal
      :show="showLossModal"
      :card-title="card?.title"
      :loss-reasons="lossReasons"
      @confirm="handleConfirmLoss"
      @cancel="handleCancelLoss"
    />
  </aside>
</template>

<script setup>
import { ref, computed, watch, onMounted } from 'vue'
import { usePipelineStore } from '@/stores/pipeline'
import StageSwitcher from './StageSwitcher.vue'
import LossReasonModal from './LossReasonModal.vue'
import { Plus, MoveRight, HelpCircle, FileText } from 'lucide-vue-next'

const props = defineProps({
  cardId: {
    type: Number,
    required: true
  },
  pipelineId: {
    type: Number,
    required: true
  }
})

const pipelineStore = usePipelineStore()

const activeTab = ref('dados')
const card = computed(() => {
  return pipelineStore.cards.find(c => c.id === props.cardId)
})

// Modal de perda e estágio pendente
const showLossModal = ref(false)
const pendingStageChange = ref(null)

const pendingStage = computed(() => {
  if (!pendingStageChange.value) return null
  return pipelineStore.stages.find(s => s.id === pendingStageChange.value)
})

const lossReasons = computed(() => {
  return pendingStage.value?.loss_reasons || []
})

// Estados locais de edição inline com auto-save no blur
const isEditingTitle = ref(false)
const editingTitle = ref('')
const isEditingValue = ref(false)
const editingValue = ref(0)
const isEditingContactName = ref(false)
const editingContactName = ref('')
const isEditingContactPhone = ref(false)
const editingContactPhone = ref('')
const isEditingContactEmail = ref(false)
const editingContactEmail = ref('')

const contactSaveStatus = ref('') // 'salvando', 'salvo', ''

// --- LÓGICA DE CAMPOS PERSONALIZADOS ---
const localCustomFields = ref({})
const saveStatus = ref('') // '', 'salvando', 'salvo'

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

// Sincroniza estados de edição com o card ativo
watch(() => card.value, (newCard) => {
  if (newCard) {
    if (!isEditingTitle.value) editingTitle.value = newCard.title || ''
    if (!isEditingValue.value) editingValue.value = newCard.value || 0
    if (!isEditingContactName.value) editingContactName.value = newCard.contact_name || ''
    if (!isEditingContactPhone.value) editingContactPhone.value = newCard.contact_phone || ''
    if (!isEditingContactEmail.value) editingContactEmail.value = newCard.contact_email || ''
    
    localCustomFields.value = { ...(newCard.custom_fields || {}) }
  }
}, { immediate: true, deep: true })

// Ações de salvamento inline
const saveTitle = async () => {
  isEditingTitle.value = false
  const trimmed = editingTitle.value.trim()
  if (trimmed && trimmed !== card.value.title) {
    showContactSaving()
    await pipelineStore.updateCard(props.cardId, { title: trimmed })
    hideContactSaving()
  }
}

const saveValue = async () => {
  isEditingValue.value = false
  const val = Number(editingValue.value)
  if (!isNaN(val) && val !== card.value.value) {
    showContactSaving()
    await pipelineStore.updateCard(props.cardId, { value: val })
    hideContactSaving()
  }
}

const saveContactName = async () => {
  isEditingContactName.value = false
  const trimmed = editingContactName.value.trim()
  if (trimmed !== card.value.contact_name) {
    showContactSaving()
    await pipelineStore.updateCard(props.cardId, { contact_name: trimmed })
    hideContactSaving()
  }
}

const saveContactPhone = async () => {
  isEditingContactPhone.value = false
  const trimmed = editingContactPhone.value.trim()
  if (trimmed !== card.value.contact_phone) {
    showContactSaving()
    await pipelineStore.updateCard(props.cardId, { contact_phone: trimmed })
    hideContactSaving()
  }
}

const saveContactEmail = async () => {
  isEditingContactEmail.value = false
  const trimmed = editingContactEmail.value.trim()
  if (trimmed !== card.value.contact_email) {
    showContactSaving()
    await pipelineStore.updateCard(props.cardId, { contact_email: trimmed })
    hideContactSaving()
  }
}

const showContactSaving = () => {
  contactSaveStatus.value = 'salvando...'
}

const hideContactSaving = () => {
  contactSaveStatus.value = 'salvo!'
  setTimeout(() => {
    contactSaveStatus.value = ''
  }, 1500)
}

// Simuladores de telefones/emails múltiplos
const addSecondaryPhone = () => {
  const phone = prompt('Digite o telefone secundário:')
  if (phone && phone.trim()) {
    const key = `Telefone ${Object.keys(localCustomFields.value).filter(k => k.startsWith('Telefone')).length + 2}`
    localCustomFields.value[key] = phone.trim()
    triggerAutoSave()
  }
}

const addSecondaryEmail = () => {
  const email = prompt('Digite o e-mail secundário:')
  if (email && email.trim()) {
    const key = `E-mail ${Object.keys(localCustomFields.value).filter(k => k.startsWith('E-mail')).length + 2}`
    localCustomFields.value[key] = email.trim()
    triggerAutoSave()
  }
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
      await pipelineStore.fetchCardTimeline(props.pipelineId, props.cardId)
    } catch (error) {
      console.error(error)
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
    await pipelineStore.fetchCardTimeline(props.pipelineId, props.cardId)
  } catch (error) {
    console.error(error)
  } finally {
    pendingStageChange.value = null
  }
}

const handleCancelLoss = () => {
  showLossModal.value = false
  pendingStageChange.value = null
}

const loadCustomFieldDefinitions = async () => {
  if (props.pipelineId) {
    await pipelineStore.fetchCustomFields(Number(props.pipelineId))
  }
}

onMounted(() => {
  loadCustomFieldDefinitions()
})

watch(() => props.pipelineId, () => {
  loadCustomFieldDefinitions()
})

// Formatador amigável de datas
const formatFriendlyDate = (isoString) => {
  if (!isoString) return ''
  const date = new Date(isoString)
  return date.toLocaleDateString('pt-BR') + ' às ' + date.toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' })
}

const formatPhone = (phone) => {
  if (!phone) return '—'
  const clean = String(phone).replace(/\D/g, '')
  if (clean.length === 13) {
    return `+${clean.slice(0,2)} ${clean.slice(2,4)} ${clean.slice(4,9)}-${clean.slice(9)}`
  }
  if (clean.length === 12) {
    return `+${clean.slice(0,2)} ${clean.slice(2,4)} ${clean.slice(4,8)}-${clean.slice(8)}`
  }
  return phone.startsWith('+') ? phone : `+${clean}`
}

let autoSaveTimeout = null

// Dispara o salvamento automático com de-bounce de 500ms
const triggerAutoSave = () => {
  saveStatus.value = 'salvando'
  
  if (autoSaveTimeout) {
    clearTimeout(autoSaveTimeout)
  }
  
  autoSaveTimeout = setTimeout(async () => {
    try {
      await pipelineStore.updateCard(props.cardId, {
        custom_fields: { ...localCustomFields.value }
      })
      saveStatus.value = 'salvo'
      setTimeout(() => {
        if (saveStatus.value === 'salvo') {
          saveStatus.value = ''
        }
      }, 1500)
    } catch (error) {
      saveStatus.value = ''
    }
  }, 500)
}

// Histórico de auditoria do sistema
const systemEvents = computed(() => {
  const list = pipelineStore.cardTimeline.filter(event => {
    const type = event.event_type
    return type !== 'chatwoot_message' && type !== 'message' && type !== 'message_sent'
  })
  // Ordena decrescente para histórico
  return [...list].sort((a, b) => new Date(b.created_at) - new Date(a.created_at))
})
</script>
