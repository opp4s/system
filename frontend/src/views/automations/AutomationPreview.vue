<template>
  <div class="space-y-6">
    <div class="space-y-1.5">
      <h3 class="text-xs font-bold text-gray-900">4. Revisar e Ativar Automação</h3>
      <p class="text-[11px] text-gray-400">Revise o fluxo de trabalho automatizado e dê um nome descritivo antes de salvar.</p>
    </div>

    <div class="bg-white border border-gray-150 rounded-2xl p-6 shadow-sm space-y-6 text-left">
      
      <!-- Nome da Automação -->
      <div class="space-y-1.5">
        <label class="block text-[11px] font-bold text-gray-700">Nome da Regra de Automação</label>
        <input
          :value="modelValue.name"
          @input="updateName($event.target.value)"
          type="text"
          placeholder="Ex: Enviar WhatsApp de Boas-vindas para Leads Grandes"
          class="block w-full px-3.5 py-2.5 rounded-xl border border-gray-250 bg-white focus:outline-none focus:border-slate-800 text-xs font-bold text-gray-800 transition-all shadow-sm"
          :class="{ 'border-rose-350 focus:border-rose-500': showErrors && !modelValue.name }"
        />
        <p v-if="showErrors && !modelValue.name" class="text-[9px] text-rose-500 font-bold">O nome da automação é obrigatório.</p>
      </div>

      <!-- Fluxo Visual Premium (Vertical Flowchart) -->
      <div class="space-y-2.5 pt-4 border-t border-gray-100">
        <span class="block text-[10px] font-bold text-gray-400 uppercase tracking-wider">Visualização do Fluxo</span>
        
        <div class="relative pl-6 border-l-2 border-slate-100 space-y-6 ml-3 py-1">
          
          <!-- 1. Trigger Node -->
          <div class="relative">
            <span class="absolute -left-[31px] top-1.5 h-4.5 w-4.5 rounded-full bg-emerald-500 text-white flex items-center justify-center text-[10px] font-bold ring-4 ring-white shadow-sm">
              1
            </span>
            <div class="bg-emerald-50/40 border border-emerald-150 rounded-2xl p-4.5">
              <span class="text-[9px] font-bold text-emerald-700 bg-emerald-50 border border-emerald-100 px-1.5 py-0.5 rounded-md uppercase tracking-wider">Gatilho (QUANDO)</span>
              <div class="flex items-center space-x-2 mt-2">
                <span class="text-lg">{{ getTriggerIcon(modelValue.trigger_type) }}</span>
                <span class="text-xs font-bold text-slate-800 leading-snug">{{ getNaturalTriggerText() }}</span>
              </div>
            </div>
          </div>

          <!-- 2. Conditions Node -->
          <div class="relative">
            <span class="absolute -left-[31px] top-1.5 h-4.5 w-4.5 rounded-full bg-blue-500 text-white flex items-center justify-center text-[10px] font-bold ring-4 ring-white shadow-sm">
              2
            </span>
            <div class="bg-blue-50/40 border border-blue-150 rounded-2xl p-4.5">
              <span class="text-[9px] font-bold text-blue-700 bg-blue-50 border border-blue-100 px-1.5 py-0.5 rounded-md uppercase tracking-wider">Critério (E SE)</span>
              <div class="flex items-center space-x-2 mt-2">
                <span class="text-lg">🔍</span>
                <span class="text-xs font-bold text-slate-800 leading-snug">
                  {{ modelValue.conditions && modelValue.conditions.length > 0 ? getNaturalConditionsText() : 'Não houver regras adicionais (rodar para todos os leads).' }}
                </span>
              </div>
            </div>
          </div>

          <!-- 3. Actions Node -->
          <div class="relative">
            <span class="absolute -left-[31px] top-1.5 h-4.5 w-4.5 rounded-full bg-violet-500 text-white flex items-center justify-center text-[10px] font-bold ring-4 ring-white shadow-sm">
              3
            </span>
            <div class="bg-violet-50/40 border border-violet-150 rounded-2xl p-4.5 space-y-3">
              <span class="text-[9px] font-bold text-violet-700 bg-violet-50 border border-violet-100 px-1.5 py-0.5 rounded-md uppercase tracking-wider">Ações (ENTÃO)</span>
              
              <div v-if="modelValue.actions && modelValue.actions.length > 0" class="space-y-2">
                <div 
                  v-for="(act, idx) in modelValue.actions" 
                  :key="idx"
                  class="flex items-start space-x-2.5 p-2 bg-white border border-gray-150 rounded-xl"
                >
                  <span class="text-base leading-none p-1 bg-slate-50 rounded-lg shrink-0">{{ getActionIcon(act.action_type) }}</span>
                  <div class="min-w-0">
                    <span class="text-[11px] font-bold text-slate-800 block leading-tight">{{ getActionTypeLabel(act.action_type) }}</span>
                    <span class="text-[10px] text-gray-450 mt-0.5 block font-medium truncate leading-normal">
                      {{ getNaturalActionText(act) }}
                    </span>
                  </div>
                </div>
              </div>
              <span v-else class="text-xs font-bold text-rose-500 italic block mt-2">Nenhuma ação comercial configurada. O fluxo não fará nada.</span>
            </div>
          </div>

        </div>
      </div>

      <!-- Toggle Ativação Rápido -->
      <div class="flex items-center justify-between p-4 bg-slate-50 border border-gray-150 rounded-2xl mt-4">
        <div>
          <span class="text-xs font-bold text-gray-800 block">Ativar automação comercial?</span>
          <span class="text-[10px] text-gray-400 block font-medium mt-0.5">Se ativada, ela monitorará os leads no pipeline em tempo real a partir de agora.</span>
        </div>
        <button
          @click="toggleActive"
          type="button"
          class="relative inline-flex h-5.5 w-10 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-150 ease-in-out focus:outline-none"
          :class="modelValue.active ? 'bg-slate-950' : 'bg-gray-200'"
        >
          <span
            class="pointer-events-none inline-block h-4.5 w-4.5 transform rounded-full bg-white shadow ring-0 transition duration-150 ease-in-out"
            :class="modelValue.active ? 'translate-x-4.5' : 'translate-x-0'"
          ></span>
        </button>
      </div>

    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { usePipelineStore } from '@/stores/pipeline'
import { useAutomationStore } from '@/stores/automation'

const props = defineProps({
  modelValue: {
    type: Object,
    required: true
  },
  showErrors: {
    type: Boolean,
    default: false
  }
})

const emit = defineEmits(['update:modelValue'])
const pipelineStore = usePipelineStore()
const automationStore = useAutomationStore()

const updateName = (name) => {
  emit('update:modelValue', { ...props.modelValue, name })
}

const toggleActive = () => {
  emit('update:modelValue', { ...props.modelValue, active: !props.modelValue.active })
}

// Mapeamento de Agentes (Round-robin)
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

// Gatilho em Linguagem Natural
const getNaturalTriggerText = () => {
  const type = props.modelValue.trigger_type
  const config = props.modelValue.trigger_config

  switch (type) {
    case 'card_created':
      return 'Um novo negócio for criado no pipeline'
    case 'card_enters_stage': {
      const stageName = getStageName(config?.stage_id)
      return `Um negócio for movido para a etapa: "${stageName}"`
    }
    case 'time_in_stage': {
      const stageName = getStageName(config?.stage_id)
      return `Um negócio ficar parado por mais de ${config?.days || 0} dias na etapa: "${stageName}"`
    }
    case 'card_updated': {
      const fieldLabel = getFieldLabel(config?.field)
      return `O campo "${fieldLabel}" de um negócio for modificado`
    }
    default:
      return 'Nenhum gatilho configurado'
  }
}

// Condições em Linguagem Natural
const getNaturalConditionsText = () => {
  const conditions = props.modelValue.conditions
  if (!conditions || conditions.length === 0) return ''

  const operatorsMap = {
    eq: 'for igual a',
    neq: 'for diferente de',
    gt: 'for maior que',
    gte: 'for maior ou igual a',
    lt: 'for menor que',
    lte: 'for menor ou igual a',
    contains: 'contiver',
    not_contains: 'não contiver',
    starts_with: 'começar com',
    present: 'estiver preenchido',
    blank: 'estiver vazio'
  }

  const parts = conditions.map(cond => {
    if (!cond.field) return '[campo não selecionado]'
    
    const fieldLabel = automationStore.availableFields[cond.field]?.label || cond.field
    const opLabel = operatorsMap[cond.operator] || cond.operator

    if (cond.operator === 'present' || cond.operator === 'blank') {
      return `"${fieldLabel}" ${opLabel}`
    }

    let valDisplay = cond.value
    if (cond.field === 'assigned_agent_id') {
      const agent = mockAgents.find(a => a.id === cond.value)
      valDisplay = agent ? agent.name : `Agente #${cond.value}`
    } else if (cond.field === 'stage_type') {
      const types = { intermediate: 'Fase Intermediária', won: 'Ganho', lost: 'Perdido' }
      valDisplay = types[cond.value] || cond.value
    } else if (cond.field === 'value') {
      valDisplay = new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(cond.value || 0)
    }

    return `"${fieldLabel}" ${opLabel} "${valDisplay || 'vazio'}"`
  })

  return parts.join(' E ')
}

// Ações em Linguagem Natural
const getNaturalActionText = (action) => {
  const type = action.action_type
  const config = action.action_config

  switch (type) {
    case 'send_whatsapp':
      return config.template ? `Enviar WhatsApp: "${config.template}"` : 'Mensagem não configurada'
    case 'move_card': {
      if (!config.stage_id) return 'Mover negócio para etapa não selecionada'
      const stageName = getStageName(config.stage_id)
      return `Mover negócio para a etapa: "${stageName}"`
    }
    case 'assign_agent':
      return config.assignment_type === 'round_robin'
        ? 'Distribuir automaticamente por Round-robin'
        : `Atribuir para: ${getAgentName(config.agent_id) || 'corretor não selecionado'}`
    case 'create_task':
      return config.title ? `Criar tarefa: "${config.title}" (Vence em ${config.due_in_days || 0}d)` : 'Criar tarefa'
    case 'webhook':
      return config.url ? `Disparar Webhook POST para: ${config.url}` : 'URL não preenchida'
    case 'update_field': {
      const fieldName = getFieldLabel(config.field)
      return `Atualizar campo "${fieldName}" para: "${config.value || 'vazio'}"`
    }
    default:
      return 'Configuração da ação'
  }
}

// Helpers Auxiliares
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

const getTriggerIcon = (type) => {
  switch (type) {
    case 'card_created': return '✨'
    case 'card_enters_stage': return '🔀'
    case 'time_in_stage': return '⏳'
    case 'card_updated': return '✏️'
    default: return '⚙'
  }
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
</script>
