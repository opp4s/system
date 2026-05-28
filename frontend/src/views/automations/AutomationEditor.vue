<template>
  <transition name="slide-panel">
    <div class="fixed inset-0 z-45 flex justify-end">
      <!-- Backdrop -->
      <div 
        @click="handleClose"
        class="absolute inset-0 bg-slate-900/40 backdrop-blur-sm transition-opacity duration-300 animate-fade-in"
      ></div>

      <!-- Painel Principal do Editor (Slide-in) -->
      <div class="relative w-full max-w-4xl h-full bg-white shadow-2xl flex flex-col z-10 animate-slide-in-right">
        <!-- Header Fixo -->
        <header class="h-16 px-6 border-b border-gray-100 flex items-center justify-between shrink-0 bg-white z-20">
          <div class="flex items-center space-x-3">
            <div class="p-2 bg-slate-900 text-white rounded-xl">
              <component :is="Zap" class="h-4.5 w-4.5" />
            </div>
            <div>
              <h2 class="text-xs font-bold text-gray-900 leading-none">
                {{ isEdit ? 'Editar Automação Comercial' : 'Criar Nova Automação' }}
              </h2>
              <p class="text-[10px] text-gray-400 mt-0.5">Defina gatilhos, condições e ações em um fluxo visual simples.</p>
            </div>
          </div>

          <!-- Navegação por Passos (Steps) -->
          <nav class="hidden md:flex items-center space-x-2 text-[10px] font-bold">
            <div 
              v-for="(step, idx) in steps" 
              :key="step.key"
              class="flex items-center space-x-1.5"
            >
              <span 
                class="h-5 w-5 rounded-full flex items-center justify-center text-[10px] border transition-all"
                :class="[
                  currentStepIndex === idx
                    ? 'bg-slate-900 border-slate-900 text-white shadow-smScale'
                    : currentStepIndex > idx
                      ? 'bg-slate-50 border-slate-900 text-slate-900'
                      : 'bg-white border-gray-200 text-gray-400'
                ]"
              >
                {{ idx + 1 }}
              </span>
              <span 
                class="transition-colors"
                :class="currentStepIndex === idx ? 'text-gray-900' : 'text-gray-400'"
              >
                {{ step.label }}
              </span>
              <!-- Seta divisória -->
              <span v-if="idx < steps.length - 1" class="text-gray-300 mx-1 font-normal">→</span>
            </div>
          </nav>

          <button 
            @click="handleClose"
            class="p-2 text-gray-400 hover:text-gray-650 hover:bg-gray-100 rounded-xl transition-all"
          >
            <component :is="X" class="h-4 w-4" />
          </button>
        </header>

        <!-- Corpo do Editor (Área de Rolagem) -->
        <main class="flex-1 overflow-y-auto p-6 bg-slate-50/30">
          <div class="max-w-2xl mx-auto py-4">
            
            <!-- STEP 1: GATILHO (TRIGGER) -->
            <section v-if="currentStepIndex === 0" class="animate-fade-in-up space-y-6">
              <TriggerSelector v-model="localAutomation" />
            </section>

            <!-- STEP 2: CONDIÇÕES (CONDITIONS) -->
            <section v-else-if="currentStepIndex === 1" class="animate-fade-in-up space-y-6">
              <ConditionBuilder v-model="localAutomation.conditions" :pipeline-id="pipelineId" />
            </section>

            <!-- STEP 3: AÇÕES (ACTIONS) - Placeholder Estruturado para o Dia 17 -->
            <section v-else-if="currentStepIndex === 2" class="animate-fade-in-up space-y-6">
              <div class="space-y-1.5">
                <h3 class="text-xs font-bold text-gray-900">3. O que esta automação deve fazer? (Ações)</h3>
                <p class="text-[11px] text-gray-400">Escolha uma ou mais ações que serão executadas sequencialmente quando o gatilho for disparado.</p>
              </div>

              <ActionConfigurator v-model="localAutomation.actions" />
            </section>

            <!-- STEP 4: REVISÃO & SALVAMENTO (REVIEW) -->
            <section v-else-if="currentStepIndex === 3" class="animate-fade-in-up space-y-6">
              <AutomationPreview v-model="localAutomation" :show-errors="showValidationErrors" />
            </section>

          </div>
        </main>

        <!-- Footer Fixo do Editor (Navegação Avançar/Voltar) -->
        <footer class="h-16 px-6 border-t border-gray-100 flex items-center justify-between shrink-0 bg-gray-50/50 z-20">
          <div>
            <button
              v-if="currentStepIndex > 0"
              @click="prevStep"
              type="button"
              class="px-4 py-2 border border-gray-250 hover:bg-gray-100 text-gray-650 rounded-xl text-xs font-bold transition-all flex items-center space-x-1"
            >
              <span>Voltar</span>
            </button>
          </div>

          <div class="flex items-center space-x-2.5">
            <button
              @click="handleClose"
              type="button"
              class="px-4 py-2 text-gray-500 hover:text-gray-700 text-xs font-bold"
            >
              Cancelar
            </button>

            <!-- Avançar / Salvar -->
            <button
              v-if="currentStepIndex < steps.length - 1"
              @click="nextStep"
              type="button"
              class="px-5 py-2 bg-slate-900 hover:bg-slate-800 text-white rounded-xl text-xs font-bold transition-all shadow flex items-center space-x-1"
            >
              <span>Avançar</span>
            </button>

            <button
              v-else
              @click="handleSave"
              :disabled="automationStore.loading.mutation"
              type="button"
              class="px-5 py-2 bg-slate-900 hover:bg-slate-850 text-white disabled:bg-slate-400 rounded-xl text-xs font-bold transition-all shadow flex items-center space-x-1.5"
            >
              <component :is="Loader2" v-if="automationStore.loading.mutation" class="h-3.5 w-3.5 animate-spin" />
              <span>Salvar Automação</span>
            </button>
          </div>
        </footer>
      </div>
    </div>
  </transition>
</template>

<script setup>
import { ref, watch, onMounted } from 'vue'
import { useAutomationStore } from '@/stores/automation'
import { usePipelineStore } from '@/stores/pipeline'
import { useToast } from '@/composables/useToast'
import TriggerSelector from './TriggerSelector.vue'
import ActionConfigurator from './ActionConfigurator.vue'
import ConditionBuilder from './ConditionBuilder.vue'
import AutomationPreview from './AutomationPreview.vue'
import { 
  Zap, 
  X, 
  Loader2 
} from 'lucide-vue-next'

const props = defineProps({
  automation: {
    type: Object,
    required: false,
    default: null
  },
  pipelineId: {
    type: [Number, String],
    required: true
  }
})

const emit = defineEmits(['close', 'saved'])

const automationStore = useAutomationStore()
const pipelineStore = usePipelineStore()
const toast = useToast()

const isEdit = ref(false)
const currentStepIndex = ref(0)
const showValidationErrors = ref(false)

// Configuração do Fluxo
const steps = [
  { key: 'trigger', label: 'Gatilho' },
  { key: 'conditions', label: 'Condições' },
  { key: 'actions', label: 'Ações' },
  { key: 'review', label: 'Revisão' }
]

// Dados locais reativos da automação sendo criada/editada
const localAutomation = ref({
  name: '',
  trigger_type: '',
  trigger_config: {},
  conditions: [],
  actions: [],
  active: true
})

onMounted(() => {
  // Captura Esc para fechar o editor
  window.addEventListener('keydown', handleKeyDown)
})

watch(
  () => props.automation,
  (newVal) => {
    if (newVal) {
      isEdit.value = true
      localAutomation.value = JSON.parse(JSON.stringify(newVal)) // clone profundo
    } else {
      isEdit.value = false
      localAutomation.value = {
        name: '',
        trigger_type: '',
        trigger_config: {},
        conditions: [],
        actions: [],
        active: true
      }
    }
    currentStepIndex.value = 0
    showValidationErrors.value = false
  },
  { immediate: true }
)

const handleKeyDown = (e) => {
  if (e.key === 'Escape') {
    handleClose()
  }
}

const handleClose = () => {
  window.removeEventListener('keydown', handleKeyDown)
  emit('close')
}

// Navegação de passos com validações completas por etapa (polish)
const nextStep = () => {
  if (currentStepIndex.value === 0) {
    // Validação Passo 1: Gatilho
    if (!localAutomation.value.trigger_type) {
      toast.error('Escolha um gatilho para avançar.')
      return
    }
    
    const cfg = localAutomation.value.trigger_config
    if (localAutomation.value.trigger_type === 'card_enters_stage' && !cfg.stage_id) {
      toast.error('Selecione uma etapa para o gatilho.')
      return
    }
    if (localAutomation.value.trigger_type === 'time_in_stage' && (!cfg.stage_id || !cfg.days)) {
      toast.error('Selecione a etapa e o número de dias de estagnação.')
      return
    }
    if (localAutomation.value.trigger_type === 'card_updated' && !cfg.field) {
      toast.error('Selecione o campo a ser monitorado.')
      return
    }
  } else if (currentStepIndex.value === 1) {
    // Validação Passo 2: Condições
    const conditions = localAutomation.value.conditions || []
    for (let i = 0; i < conditions.length; i++) {
      const cond = conditions[i]
      if (!cond.field) {
        toast.error(`Condição #${i + 1}: Selecione o campo.`)
        return
      }
      if (!cond.operator) {
        toast.error(`Condição #${i + 1}: Selecione o operador.`)
        return
      }
      const showVal = cond.operator !== 'present' && cond.operator !== 'blank'
      if (showVal && (cond.value === null || cond.value === undefined || cond.value === '')) {
        toast.error(`Condição #${i + 1}: Digite um valor de comparação.`)
        return
      }
    }
  } else if (currentStepIndex.value === 2) {
    // Validação Passo 3: Ações
    const actions = localAutomation.value.actions || []
    if (actions.length === 0) {
      toast.error('Adicione pelo menos uma ação para prosseguir.')
      return
    }
    for (let i = 0; i < actions.length; i++) {
      const act = actions[i]
      const cfg = act.action_config || {}
      
      if (act.action_type === 'send_whatsapp' && !cfg.template) {
        toast.error(`Ação #${i + 1} (WhatsApp): O template da mensagem não pode ficar vazio.`)
        return
      }
      if (act.action_type === 'move_card' && !cfg.stage_id) {
        toast.error(`Ação #${i + 1} (Mover Negócio): Selecione a etapa de destino.`)
        return
      }
      if (act.action_type === 'assign_agent') {
        if (!cfg.assignment_type) {
          toast.error(`Ação #${i + 1} (Atribuir Agente): Escolha a regra de atribuição.`)
          return
        }
        if (cfg.assignment_type === 'specific' && !cfg.agent_id) {
          toast.error(`Ação #${i + 1} (Atribuir Agente): Selecione o agente específico.`)
          return
        }
      }
      if (act.action_type === 'create_task') {
        if (!cfg.title) {
          toast.error(`Ação #${i + 1} (Criar Tarefa): Digite o título da tarefa.`)
          return
        }
        if (cfg.due_in_days === undefined || cfg.due_in_days === null || cfg.due_in_days < 0) {
          toast.error(`Ação #${i + 1} (Criar Tarefa): Insira um prazo de vencimento válido.`)
          return
        }
      }
      if (act.action_type === 'webhook') {
        if (!cfg.url) {
          toast.error(`Ação #${i + 1} (Webhook): Digite a URL do webhook.`)
          return
        }
        if (!cfg.url.startsWith('http://') && !cfg.url.startsWith('https://')) {
          toast.error(`Ação #${i + 1} (Webhook): A URL deve iniciar com http:// ou https://`)
          return
        }
      }
      if (act.action_type === 'update_field') {
        if (!cfg.field) {
          toast.error(`Ação #${i + 1} (Atualizar Campo): Escolha o campo para atualização.`)
          return
        }
        if (cfg.value === undefined || cfg.value === null || cfg.value === '') {
          toast.error(`Ação #${i + 1} (Atualizar Campo): Digite o novo valor para o campo.`)
          return
        }
      }
    }
  }
  
  if (currentStepIndex.value < steps.length - 1) {
    currentStepIndex.value++
  }
}

const prevStep = () => {
  if (currentStepIndex.value > 0) {
    currentStepIndex.value--
  }
}

// Salva a automação na store com validação completa (polish)
const handleSave = async () => {
  showValidationErrors.value = true
  if (!localAutomation.value.name) {
    toast.error('Nomeie sua automação para salvá-la.')
    return
  }

  // Validação final de integridade de gatilho e ações
  if (!localAutomation.value.trigger_type) {
    toast.error('O gatilho da automação não foi selecionado.')
    return
  }
  if (!localAutomation.value.actions || localAutomation.value.actions.length === 0) {
    toast.error('Adicione pelo menos uma ação para poder salvar.')
    return
  }

  try {
    const saved = await automationStore.saveAutomation(props.pipelineId, localAutomation.value)
    if (saved) {
      toast.success(isEdit.value ? 'Automação atualizada!' : 'Automação criada com sucesso!')
      window.removeEventListener('keydown', handleKeyDown)
      emit('saved', saved)
    }
  } catch (error) {
    toast.error('Erro ao salvar a automação comercial.')
  }
}

// Tradução de Gatilho para Linguagem Natural
const getNaturalTriggerText = () => {
  const type = localAutomation.value.trigger_type
  const config = localAutomation.value.trigger_config

  switch (type) {
    case 'card_created':
      return 'Um novo negócio for criado no pipeline.'
    case 'card_enters_stage': {
      const stageName = getStageName(config?.stage_id)
      return `Um negócio for movido para a etapa: "${stageName}".`
    }
    case 'time_in_stage': {
      const stageName = getStageName(config?.stage_id)
      return `Um negócio ficar parado por mais de ${config?.days || 0} dias na etapa: "${stageName}".`
    }
    case 'card_updated': {
      const fieldLabel = getFieldLabel(config?.field)
      return `O campo "${fieldLabel}" de um negócio for modificado.`
    }
    default:
      return 'Nenhum gatilho selecionado.'
  }
}

const getStageName = (stageId) => {
  const stage = pipelineStore.stages.find(s => s.id === stageId)
  return stage ? stage.name : `Etapa #${stageId}`
}

const getFieldLabel = (field) => {
  if (!field) return 'específico'
  if (field.startsWith('custom_fields.')) {
    return field.replace('custom_fields.', '')
  }
  switch (field) {
    case 'title': return 'Título do Negócio'
    case 'value': return 'Valor Estimado'
    case 'contact_name': return 'Nome do Contato'
    case 'contact_email': return 'E-mail'
    case 'contact_phone': return 'Telefone (WhatsApp)'
    case 'user_id': return 'Agente Responsável'
    default: return field
  }
}

// Helpers para ações
const mockAgents = [
  { id: 10001, name: 'João Agente' },
  { id: 10002, name: 'Ana Souza' },
  { id: 10003, name: 'Carlos Consultor' },
  { id: 10004, name: 'Mariana Gerente' }
]

const getAgentName = (id) => {
  const agent = mockAgents.find(a => a.id === id)
  return agent ? agent.name : ''
}

const getActionIcon = (type) => {
  switch (type) {
    case 'send_whatsapp': return '💬'
    case 'move_card': return '🔀'
    case 'assign_agent': return '👤'
    case 'create_task': return '📋'
    case 'webhook': return '🔗'
    case 'update_field': return '✏️'
    default: return '⚙️'
  }
}

const getActionTypeLabel = (type) => {
  switch (type) {
    case 'send_whatsapp': return 'Enviar WhatsApp'
    case 'move_card': return 'Mover Negócio'
    case 'assign_agent': return 'Atribuir Agente'
    case 'create_task': return 'Criar Tarefa'
    case 'webhook': return 'Enviar Webhook API'
    case 'update_field': return 'Atualizar Campo'
    default: return 'Ação'
  }
}

const getNaturalActionText = (action) => {
  const type = action.action_type
  const config = action.action_config

  switch (type) {
    case 'send_whatsapp':
      return config.template 
        ? `Mensagem: "${config.template}"` 
        : 'Mensagem de WhatsApp não configurada'
    case 'move_card': {
      if (!config.stage_id) return 'Etapa de destino não selecionada'
      const stage = pipelineStore.stages.find(s => s.id === config.stage_id)
      return `Mover negócio para etapa: "${stage ? stage.name : `Etapa #${config.stage_id}`}"`
    }
    case 'assign_agent':
      return config.assignment_type === 'round_robin'
        ? 'Distribuir automaticamente por Round-robin'
        : `Atribuir para o agente específico: ${getAgentName(config.agent_id) || 'Selecionar corretor'}`
    case 'create_task':
      return config.title 
        ? `Criar tarefa: "${config.title}" (Vence em ${config.due_in_days || 0} dias úteis)` 
        : 'Criar tarefa em aberto'
    case 'webhook':
      return config.url 
        ? `Disparar Webhook HTTP POST para: ${config.url}` 
        : 'URL do Webhook não preenchida'
    case 'update_field': {
      if (!config.field) return 'Nenhum campo selecionado'
      const fieldName = getFieldLabel(config.field)
      return `Atualizar campo "${fieldName}" para: "${config.value || 'vazio'}"`
    }
    default:
      return 'Configuração da ação'
  }
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

@keyframes fadeInUp {
  from {
    opacity: 0;
    transform: translateY(12px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
.animate-fade-in-up {
  animation: fadeInUp 0.25s cubic-bezier(0.16, 1, 0.3, 1) forwards;
}

.shadow-smScale {
  box-shadow: 0 0 0 4px rgba(15, 23, 42, 0.1);
}
</style>
