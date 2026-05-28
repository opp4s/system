<template>
  <div class="space-y-6">
    <div class="flex items-center justify-between pb-3 border-b border-gray-150/60">
      <div class="space-y-1">
        <h3 class="text-xs font-bold text-gray-900">Regras de Filtragem (Condições)</h3>
        <p class="text-[11px] text-gray-400">Opcional. Defina regras adicionais para que esta automação só execute se o lead atender a todos os critérios.</p>
      </div>
      <button
        @click="addCondition"
        type="button"
        class="px-3 py-1.5 bg-slate-900 hover:bg-slate-800 text-white rounded-xl text-[10px] font-bold shadow-sm transition-all flex items-center space-x-1"
      >
        <component :is="Plus" class="h-3.5 w-3.5" />
        <span>Adicionar Condição</span>
      </button>
    </div>

    <!-- Lista de Condições -->
    <div v-if="localConditions.length === 0" class="border border-dashed border-gray-200 rounded-3xl p-10 text-center flex flex-col items-center justify-center space-y-3 bg-white">
      <span class="text-3xl select-none animate-bounce">🔍</span>
      <div class="space-y-1">
        <span class="font-bold text-gray-800 text-xs block">Sem condições restritivas</span>
        <span class="text-[10px] text-gray-400 block max-w-xs leading-normal">Esta automação será executada para todos os leads que dispararem o gatilho.</span>
      </div>
      <button
        @click="addCondition"
        type="button"
        class="px-4 py-2 border border-slate-900 hover:bg-slate-50 text-slate-900 rounded-xl text-xs font-bold transition-all"
      >
        Adicionar Primeira Regra
      </button>
    </div>

    <div v-else class="space-y-3">
      <!-- Cards de Condições -->
      <div 
        v-for="(cond, index) in localConditions" 
        :key="index"
        class="p-4 bg-white border border-gray-150 hover:border-gray-250 rounded-2xl shadow-sm transition-all flex flex-col sm:flex-row items-start sm:items-center space-y-3 sm:space-y-0 sm:space-x-3.5"
      >
        <!-- Contador / Pills "E" -->
        <span class="px-2 py-1 rounded-lg text-[9px] font-bold tracking-wider uppercase bg-slate-150 text-slate-650 shrink-0">
          {{ index === 0 ? 'SE' : 'E' }}
        </span>

        <!-- Seletor de Campo -->
        <div class="flex-1 w-full">
          <select
            v-model="cond.field"
            @change="onFieldChange(index)"
            class="block w-full px-3 py-2 rounded-xl border border-gray-250 bg-white focus:outline-none focus:border-slate-800 text-xs font-bold text-gray-800 transition-all"
          >
            <option :value="null" disabled>Escolha um campo...</option>
            <option 
              v-for="(fieldCfg, fieldKey) in availableFields" 
              :key="fieldKey" 
              :value="fieldKey"
            >
              {{ fieldCfg.label }}
            </option>
          </select>
        </div>

        <!-- Seletor de Operador -->
        <div class="flex-1 w-full" v-if="cond.field">
          <select
            v-model="cond.operator"
            @change="onOperatorChange(index)"
            class="block w-full px-3 py-2 rounded-xl border border-gray-250 bg-white focus:outline-none focus:border-slate-800 text-xs font-bold text-gray-800 transition-all"
          >
            <option 
              v-for="op in getOperatorsForField(cond.field)" 
              :key="op.value" 
              :value="op.value"
            >
              {{ op.label }}
            </option>
          </select>
        </div>

        <!-- Input de Valor (Condicional ao Operador) -->
        <div class="flex-1 w-full" v-if="cond.field && showValueInput(cond.operator)">
          <!-- Caso 1: Dropdown de Agentes se for o campo de atribuição -->
          <select
            v-if="cond.field === 'assigned_agent_id'"
            v-model="cond.value"
            @change="emitConditions"
            class="block w-full px-3 py-2 rounded-xl border border-gray-250 bg-white focus:outline-none focus:border-slate-800 text-xs font-bold text-gray-800 transition-all"
          >
            <option :value="null" disabled>Selecione o agente...</option>
            <option 
              v-for="agent in mockAgents" 
              :key="agent.id" 
              :value="agent.id"
            >
              {{ agent.name }}
            </option>
          </select>

          <!-- Caso 2: Dropdown de Tipo de Etapa se for o campo correspondente -->
          <select
            v-else-if="cond.field === 'stage_type'"
            v-model="cond.value"
            @change="emitConditions"
            class="block w-full px-3 py-2 rounded-xl border border-gray-250 bg-white focus:outline-none focus:border-slate-800 text-xs font-bold text-gray-800 transition-all"
          >
            <option :value="null" disabled>Selecione o tipo...</option>
            <option value="intermediate">Fase Intermediária</option>
            <option value="won">Ganho (Won)</option>
            <option value="lost">Perdido (Lost)</option>
          </select>

          <!-- Caso 3: Input de Número para Campos Numéricos -->
          <input
            v-else-if="getFieldType(cond.field) === 'number'"
            v-model.number="cond.value"
            @input="emitConditions"
            type="number"
            placeholder="Ex: 5000"
            class="block w-full px-3 py-2 rounded-xl border border-gray-250 bg-white focus:outline-none focus:border-slate-800 text-xs font-bold text-gray-800 transition-all"
          />

          <!-- Caso 4: Input de Texto comum -->
          <input
            v-else
            v-model="cond.value"
            @input="emitConditions"
            type="text"
            placeholder="Valor de comparação..."
            class="block w-full px-3 py-2 rounded-xl border border-gray-250 bg-white focus:outline-none focus:border-slate-800 text-xs font-bold text-gray-800 transition-all"
          />
        </div>

        <!-- Botão Remover Pill -->
        <button
          @click="removeCondition(index)"
          type="button"
          class="p-2 hover:bg-rose-50 text-gray-450 hover:text-rose-600 rounded-xl transition-colors shrink-0"
          title="Remover critério"
        >
          <component :is="Trash2" class="h-4 w-4" />
        </button>
      </div>

      <!-- Resumo Linguagem Natural Live -->
      <div class="p-4 bg-slate-900/5 border border-slate-900/10 rounded-2xl space-y-2 mt-4 text-left">
        <span class="text-[9px] font-bold text-gray-400 uppercase tracking-wider block">Tradução em Linguagem Natural</span>
        <p class="text-xs font-semibold text-slate-800 leading-relaxed">
          ⚡ O fluxo rodará se: <span class="text-slate-900 font-bold underline">{{ getNaturalLanguageSummary() }}</span>
        </p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, watch, onMounted, computed } from 'vue'
import { useAutomationStore } from '@/stores/automation'
import { Plus, Trash2 } from 'lucide-vue-next'

const props = defineProps({
  modelValue: {
    type: Array,
    required: true,
    default: () => []
  },
  pipelineId: {
    type: [Number, String],
    required: true
  }
})

const emit = defineEmits(['update:modelValue'])
const automationStore = useAutomationStore()

const localConditions = ref([])

watch(
  () => props.modelValue,
  (newVal) => {
    if (newVal) {
      localConditions.value = JSON.parse(JSON.stringify(newVal))
    }
  },
  { immediate: true, deep: true }
)

onMounted(() => {
  // Carrega campos do endpoint ou fallback mock
  automationStore.fetchAvailableFields(props.pipelineId)
})

const availableFields = computed(() => automationStore.availableFields || {})

// Lista Mockada de Agentes (Sincronizado com ActionConfigurator)
const mockAgents = [
  { id: 10001, name: 'João Agente' },
  { id: 10002, name: 'Ana Souza' },
  { id: 10003, name: 'Carlos Consultor' },
  { id: 10004, name: 'Mariana Gerente' }
]

// Lista Completa de Operadores com Traduções
const operatorsMap = {
  eq: 'igual a',
  neq: 'diferente de',
  gt: 'maior que',
  gte: 'maior ou igual a',
  lt: 'menor que',
  lte: 'menor ou igual a',
  contains: 'contém',
  not_contains: 'não contém',
  starts_with: 'começa com',
  present: 'está preenchido',
  blank: 'está vazio',
  in: 'está na lista',
  not_in: 'não está na lista'
}

// Filtra operadores correspondentes ao tipo de campo
const getOperatorsForField = (fieldKey) => {
  const field = availableFields.value[fieldKey]
  if (!field) return []

  const type = field.type
  if (type === 'number') {
    return [
      { value: 'eq', label: 'Igual a (=)' },
      { value: 'neq', label: 'Diferente de (!=)' },
      { value: 'gt', label: 'Maior que (>)' },
      { value: 'gte', label: 'Maior ou igual (>=)' },
      { value: 'lt', label: 'Menor que (<)' },
      { value: 'lte', label: 'Menor ou igual (<=)' },
      { value: 'present', label: 'Está preenchido' },
      { value: 'blank', label: 'Está vazio' }
    ]
  } else if (type === 'select') {
    return [
      { value: 'eq', label: 'Igual a' },
      { value: 'neq', label: 'Diferente de' },
      { value: 'present', label: 'Está preenchido' },
      { value: 'blank', label: 'Está vazio' }
    ]
  } else {
    // string / text
    return [
      { value: 'eq', label: 'Igual a' },
      { value: 'neq', label: 'Diferente de' },
      { value: 'contains', label: 'Contém' },
      { value: 'not_contains', label: 'Não contém' },
      { value: 'starts_with', label: 'Começa com' },
      { value: 'present', label: 'Está preenchido' },
      { value: 'blank', label: 'Está vazio' }
    ]
  }
}

// Retorna tipo do campo selecionado
const getFieldType = (fieldKey) => {
  return availableFields.value[fieldKey]?.type || 'text'
}

// Mostra ou esconde o input de valor com base no operador
const showValueInput = (operator) => {
  return operator !== 'present' && operator !== 'blank'
}

// Adiciona uma nova condição na lista local
const addCondition = () => {
  const newCond = {
    field: null,
    operator: 'eq',
    value: ''
  }
  localConditions.value.push(newCond)
  emitConditions()
}

// Remove uma condição da lista
const removeCondition = (index) => {
  localConditions.value.splice(index, 1)
  emitConditions()
}

// Atualiza o operador quando altera o campo de pesquisa
const onFieldChange = (index) => {
  const cond = localConditions.value[index]
  const operators = getOperatorsForField(cond.field)
  cond.operator = operators[0]?.value || 'eq'
  cond.value = ''
  emitConditions()
}

const onOperatorChange = (index) => {
  const cond = localConditions.value[index]
  if (!showValueInput(cond.operator)) {
    cond.value = null
  } else {
    cond.value = ''
  }
  emitConditions()
}

const emitConditions = () => {
  emit('update:modelValue', localConditions.value)
}

// Tradutor dinâmico de filtros compostos em Português Fluido
const getNaturalLanguageSummary = () => {
  if (localConditions.value.length === 0) {
    return 'Não houver regras adicionais (rodar sempre).'
  }

  const parts = localConditions.value.map(cond => {
    if (!cond.field) return '[Campo não selecionado]'
    
    const fieldLabel = availableFields.value[cond.field]?.label || cond.field
    const opLabel = operatorsMap[cond.operator] || cond.operator

    if (!showValueInput(cond.operator)) {
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

    return `"${fieldLabel}" for ${opLabel} "${valDisplay || 'vazio'}"`
  })

  return parts.join(' E ')
}
</script>
