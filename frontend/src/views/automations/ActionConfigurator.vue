<template>
  <div class="space-y-6">
    <div class="flex items-center justify-between pb-3 border-b border-gray-150/60">
      <div class="space-y-1">
        <h3 class="text-xs font-bold text-gray-900">Configuração de Ações Comerciais</h3>
        <p class="text-[11px] text-gray-400">As ações serão executadas de cima para baixo. Arraste-as para reordenar.</p>
      </div>
      <!-- Botão Adicionar Rápido -->
      <div class="relative">
        <button
          @click="showAddMenu = !showAddMenu"
          type="button"
          class="px-3 py-1.5 bg-slate-900 hover:bg-slate-800 text-white rounded-xl text-[10px] font-bold shadow-sm transition-all flex items-center space-x-1"
        >
          <component :is="Plus" class="h-3.5 w-3.5" />
          <span>Adicionar Ação</span>
        </button>

        <!-- Dropdown flutuante de ações -->
        <transition name="pop-over">
          <div 
            v-if="showAddMenu"
            class="absolute right-0 mt-2 w-56 bg-white border border-gray-150 rounded-2xl shadow-xl z-50 p-2 space-y-1 text-left animate-scale-up"
          >
            <div class="px-2.5 py-1.5 text-[9px] font-bold text-gray-400 uppercase tracking-wider">Tipos de Ação</div>
            <button
              v-for="opt in actionTypes"
              :key="opt.type"
              @click="addAction(opt.type)"
              type="button"
              class="w-full px-2.5 py-2 hover:bg-slate-50 rounded-xl text-left transition-colors flex items-center space-x-2.5 group"
            >
              <span class="text-base p-1 bg-gray-50 group-hover:bg-white rounded-lg">{{ opt.icon }}</span>
              <div>
                <span class="text-[11px] font-bold text-gray-800 block leading-tight">{{ opt.label }}</span>
                <span class="text-[9px] text-gray-400 block font-semibold leading-normal mt-0.5">{{ opt.desc }}</span>
              </div>
            </button>
          </div>
        </transition>
      </div>
    </div>

    <!-- Lista de Ações Reordenável com Draggable -->
    <div v-if="localActions.length === 0" class="border border-dashed border-gray-200 rounded-3xl p-10 text-center flex flex-col items-center justify-center space-y-3 bg-white">
      <span class="text-3xl select-none animate-bounce">⚡</span>
      <div class="space-y-1">
        <span class="font-bold text-gray-800 text-xs block">Nenhuma ação cadastrada</span>
        <span class="text-[10px] text-gray-400 block max-w-xs leading-normal">Adicione ações como enviar WhatsApp, criar tarefas ou mover negócios para este fluxo comercial.</span>
      </div>
      <button
        @click="showAddMenu = true"
        type="button"
        class="px-4 py-2 border border-slate-900 hover:bg-slate-50 text-slate-900 rounded-xl text-xs font-bold transition-all"
      >
        Adicionar Primeira Ação
      </button>
    </div>

    <draggable
      v-else
      v-model="localActions"
      item-key="id"
      handle=".drag-handle"
      ghost-class="opacity-40"
      @change="onDragChange"
      class="space-y-3.5"
    >
      <template #item="{ element, index }">
        <div 
          class="bg-white border rounded-2xl shadow-sm transition-all duration-200"
          :class="[
            expandedActionIndex === index 
              ? 'border-slate-300 ring-1 ring-slate-100' 
              : 'border-gray-200 hover:border-gray-300'
          ]"
        >
          <!-- Topo do Card da Ação -->
          <div class="px-4.5 py-3 flex items-center justify-between space-x-3 select-none">
            <div class="flex items-center space-x-3 min-w-0">
              <!-- Ícone Handle Draggable -->
              <div class="drag-handle cursor-grab active:cursor-grabbing p-1 hover:bg-gray-50 rounded-lg text-gray-450 transition-colors shrink-0">
                <component :is="GripVertical" class="h-4 w-4" />
              </div>

              <!-- Ícone/Cor Ação -->
              <span class="text-base p-1.5 rounded-xl shrink-0" :class="getActionBadgeBg(element.action_type)">
                {{ getActionIcon(element.action_type) }}
              </span>

              <!-- Informações Textuais -->
              <div class="min-w-0">
                <div class="flex items-center space-x-2">
                  <span class="text-xs font-bold text-gray-900 leading-tight">
                    {{ getActionTypeLabel(element.action_type) }}
                  </span>
                  <span class="text-[9px] px-1.5 py-0.5 rounded-full font-bold bg-gray-50 text-gray-450 border border-gray-100 uppercase tracking-wider">
                    Ação #{{ index + 1 }}
                  </span>
                </div>
                <!-- Resumo Visual Rápido da Configuração -->
                <span class="text-[10px] text-gray-400 block font-medium truncate max-w-sm sm:max-w-md mt-0.5">
                  {{ getActionSummary(element) }}
                </span>
              </div>
            </div>

            <!-- Botões de Controle do Card -->
            <div class="flex items-center space-x-1 shrink-0">
              <!-- Expandir/Recolher -->
              <button
                @click="toggleExpand(index)"
                type="button"
                class="p-1.5 hover:bg-gray-100 text-gray-450 hover:text-gray-700 rounded-lg transition-colors"
                :title="expandedActionIndex === index ? 'Recolher configurações' : 'Expandir configurações'"
              >
                <component 
                  :is="ChevronDown" 
                  class="h-4 w-4 transform transition-transform duration-200"
                  :class="{ 'rotate-180': expandedActionIndex === index }"
                />
              </button>
              <!-- Remover -->
              <button
                @click="removeAction(index)"
                type="button"
                class="p-1.5 hover:bg-rose-50 text-gray-400 hover:text-rose-600 rounded-lg transition-colors"
                title="Excluir ação"
              >
                <component :is="Trash2" class="h-4 w-4" />
              </button>
            </div>
          </div>

          <!-- Formulário Interno Expansível (Configuração Específica) -->
          <transition name="collapse">
            <div 
              v-show="expandedActionIndex === index"
              class="px-5 pb-5 pt-1.5 border-t border-gray-100 bg-slate-50/20 rounded-b-2xl space-y-4 text-left"
            >
              <!-- 1. Enviar WhatsApp (send_whatsapp) -->
              <div v-if="element.action_type === 'send_whatsapp'" class="space-y-3">
                <div class="flex items-center justify-between">
                  <label class="block text-[11px] font-bold text-gray-700">Modelo de Mensagem (Template)</label>
                  <span class="text-[10px] font-semibold text-gray-400">Insira variáveis dinâmicas com os chips</span>
                </div>

                <!-- Chips Clicáveis de Variáveis -->
                <div class="flex flex-wrap gap-1.5 p-2 bg-white border border-gray-200 rounded-xl">
                  <span class="text-[9px] font-bold text-gray-400 uppercase tracking-wider block w-full mb-1">Inserir no cursor:</span>
                  <button
                    v-for="chip in variableChips"
                    :key="chip.marker"
                    @click="insertChip(index, chip.marker)"
                    type="button"
                    class="px-2 py-1 bg-slate-100 hover:bg-slate-200 active:bg-slate-350 text-slate-800 rounded-lg text-[9px] font-bold transition-all border border-gray-200 shadow-sm"
                  >
                    {{ chip.label }}
                  </button>
                </div>

                <div class="relative">
                  <textarea
                    :id="`wa-template-${index}`"
                    v-model="element.action_config.template"
                    @input="updateActionConfig(index)"
                    rows="4"
                    placeholder="Olá {contact_name}! Recebemos seu interesse em '{title}'. Em breve entraremos em contato."
                    class="block w-full px-3.5 py-2.5 rounded-xl border border-gray-250 bg-white focus:outline-none focus:border-slate-800 text-xs font-medium text-gray-800 transition-all shadow-sm resize-y"
                  ></textarea>
                </div>
                <p class="text-[10px] text-gray-400 font-medium">As chaves entre chaves `{}` serão substituídas automaticamente pelos dados do lead antes do envio.</p>
              </div>

              <!-- 2. Mover Negócio (move_card) -->
              <div v-else-if="element.action_type === 'move_card'" class="space-y-2">
                <label class="block text-[11px] font-bold text-gray-700">Etapa Comercial de Destino</label>
                <select
                  v-model="element.action_config.stage_id"
                  @change="updateActionConfig(index)"
                  class="block w-full px-3 py-2.5 rounded-xl border border-gray-250 bg-white focus:outline-none focus:border-slate-800 text-xs font-bold text-gray-800 transition-all shadow-sm"
                >
                  <option :value="null" disabled>Escolha a etapa de destino...</option>
                  <option 
                    v-for="stage in pipelineStore.stages" 
                    :key="stage.id" 
                    :value="stage.id"
                  >
                    {{ stage.name }} ({{ getStageTypeLabel(stage.stage_type) }})
                  </option>
                </select>
                <p class="text-[10px] text-gray-400 font-medium">O cartão de negócio será movido automaticamente para esta etapa.</p>
              </div>

              <!-- 3. Atribuir Agente (assign_agent) -->
              <div v-else-if="element.action_type === 'assign_agent'" class="space-y-4">
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div class="space-y-1.5">
                    <label class="block text-[11px] font-bold text-gray-700">Regra de Atribuição</label>
                    <select
                      v-model="element.action_config.assignment_type"
                      @change="onAssignmentTypeChange(index)"
                      class="block w-full px-3 py-2.5 rounded-xl border border-gray-250 bg-white focus:outline-none focus:border-slate-800 text-xs font-bold text-gray-800 transition-all shadow-sm"
                    >
                      <option value="specific">Agente Específico</option>
                      <option value="round_robin">Distribuição Automática (Round-robin)</option>
                    </select>
                  </div>

                  <div class="space-y-1.5" v-if="element.action_config.assignment_type === 'specific'">
                    <label class="block text-[11px] font-bold text-gray-700">Selecionar Agente</label>
                    <select
                      v-model="element.action_config.agent_id"
                      @change="updateActionConfig(index)"
                      class="block w-full px-3 py-2.5 rounded-xl border border-gray-250 bg-white focus:outline-none focus:border-slate-800 text-xs font-bold text-gray-800 transition-all shadow-sm"
                    >
                      <option :value="null" disabled>Escolha um agente...</option>
                      <option 
                        v-for="agent in mockAgents" 
                        :key="agent.id" 
                        :value="agent.id"
                      >
                        {{ agent.name }}
                      </option>
                    </select>
                  </div>
                </div>
                <p class="text-[10px] text-gray-400 font-medium">
                  {{ element.action_config.assignment_type === 'round_robin' 
                    ? 'O lead será atribuído em fila circular de forma justa aos corretores ativos.' 
                    : 'O lead será atribuído permanentemente ao corretor/agente selecionado.' }}
                </p>
              </div>

              <!-- 4. Criar Tarefa (create_task) -->
              <div v-else-if="element.action_type === 'create_task'" class="space-y-4">
                <div class="space-y-1.5">
                  <label class="block text-[11px] font-bold text-gray-700">Título / Nome da Tarefa</label>
                  <input
                    v-model="element.action_config.title"
                    @input="updateActionConfig(index)"
                    type="text"
                    placeholder="Ex: Fazer follow-up via ligação"
                    class="block w-full px-3 py-2.5 rounded-xl border border-gray-250 bg-white focus:outline-none focus:border-slate-800 text-xs font-bold text-gray-800 transition-all shadow-sm"
                  />
                </div>

                <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div class="space-y-1.5">
                    <label class="block text-[11px] font-bold text-gray-700">Prazo de Vencimento (Dias úteis)</label>
                    <input
                      v-model.number="element.action_config.due_in_days"
                      @input="updateActionConfig(index)"
                      type="number"
                      min="0"
                      placeholder="Ex: 2"
                      class="block w-full px-3 py-2.5 rounded-xl border border-gray-250 bg-white focus:outline-none focus:border-slate-800 text-xs font-bold text-gray-800 transition-all shadow-sm"
                    />
                  </div>
                </div>
                <p class="text-[10px] text-gray-400 font-medium">Uma tarefa de acompanhamento será gerada e atribuída ao corretor responsável pelo lead.</p>
              </div>

              <!-- 5. Enviar Webhook (webhook) -->
              <div v-else-if="element.action_type === 'webhook'" class="space-y-2">
                <label class="block text-[11px] font-bold text-gray-700">URL do Webhook (HTTP POST)</label>
                <div class="relative rounded-xl shadow-sm">
                  <input
                    v-model="element.action_config.url"
                    @input="updateActionConfig(index)"
                    type="url"
                    placeholder="https://sua-api.com/webhooks/zavy"
                    class="block w-full px-3.5 py-2.5 rounded-xl border border-gray-250 bg-white focus:outline-none focus:border-slate-800 text-xs font-bold text-gray-800 transition-all shadow-sm"
                  />
                </div>
                <p class="text-[10px] text-gray-400 font-medium">Os dados completos do negócio serão enviados em formato JSON para esta URL no instante do disparo.</p>
              </div>

              <!-- 6. Atualizar Campo (update_field) -->
              <div v-else-if="element.action_type === 'update_field'" class="space-y-4">
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div class="space-y-1.5">
                    <label class="block text-[11px] font-bold text-gray-700">Campo para Atualização</label>
                    <select
                      v-model="element.action_config.field"
                      @change="onFieldChange(index)"
                      class="block w-full px-3 py-2.5 rounded-xl border border-gray-250 bg-white focus:outline-none focus:border-slate-800 text-xs font-bold text-gray-800 transition-all shadow-sm"
                    >
                      <option :value="null" disabled>Escolha um campo...</option>
                      <optgroup label="Campos Padrão">
                        <option value="title">Título do Negócio</option>
                        <option value="value">Valor Estimado</option>
                        <option value="contact_email">E-mail</option>
                        <option value="contact_phone">Telefone (WhatsApp)</option>
                      </optgroup>
                      <optgroup label="Campos Personalizados" v-if="hasCustomFields">
                        <option 
                          v-for="cfKey in customFieldKeys" 
                          :key="cfKey" 
                          :value="`custom_fields.${cfKey}`"
                        >
                          {{ cfKey }} (Personalizado)
                        </option>
                      </optgroup>
                    </select>
                  </div>

                  <div class="space-y-1.5">
                    <label class="block text-[11px] font-bold text-gray-700">Novo Valor</label>
                    <input
                      v-model="element.action_config.value"
                      @input="updateActionConfig(index)"
                      :type="element.action_config.field === 'value' ? 'number' : 'text'"
                      placeholder="Insira o novo valor..."
                      class="block w-full px-3 py-2.5 rounded-xl border border-gray-250 bg-white focus:outline-none focus:border-slate-800 text-xs font-bold text-gray-800 transition-all shadow-sm"
                    />
                  </div>
                </div>
                <p class="text-[10px] text-gray-400 font-medium">O valor do campo selecionado será alterado de forma automatizada de acordo com o valor configurado.</p>
              </div>

            </div>
          </transition>
        </div>
      </template>
    </draggable>
  </div>
</template>

<script setup>
import { ref, watch, computed } from 'vue'
import draggable from 'vuedraggable'
import { usePipelineStore } from '@/stores/pipeline'
import { 
  Plus, 
  Trash2, 
  ChevronDown, 
  GripVertical 
} from 'lucide-vue-next'

const props = defineProps({
  modelValue: {
    type: Array,
    required: true,
    default: () => []
  }
})

const emit = defineEmits(['update:modelValue'])
const pipelineStore = usePipelineStore()

const showAddMenu = ref(false)
const expandedActionIndex = ref(null)

// Lista Localizada de Ações Reordenável
const localActions = ref([])

watch(
  () => props.modelValue,
  (newVal) => {
    if (newVal) {
      localActions.value = JSON.parse(JSON.stringify(newVal))
    }
  },
  { immediate: true, deep: true }
)

// Tipos de Ações Disponíveis
const actionTypes = [
  { type: 'send_whatsapp', label: 'Enviar WhatsApp', desc: 'Mensagem automatizada', icon: '💬' },
  { type: 'move_card', label: 'Mover Negócio', desc: 'Mudar etapa do lead', icon: '🔀' },
  { type: 'assign_agent', label: 'Atribuir Agente', desc: 'Alterar o corretor', icon: '👤' },
  { type: 'create_task', label: 'Criar Tarefa', desc: 'Acompanhar com prazos', icon: '📋' },
  { type: 'webhook', label: 'Enviar Webhook', desc: 'Disparar payload API', icon: '🔗' },
  { type: 'update_field', label: 'Atualizar Campo', desc: 'Modificar dados do lead', icon: '✏️' }
]

// Lista de Chips de Variáveis Úteis do WhatsApp
const variableChips = [
  { label: 'Nome do Lead', marker: '{contact_name}' },
  { label: 'Título do Negócio', marker: '{title}' },
  { label: 'Valor Estimado', marker: '{value}' },
  { label: 'Telefone (WhatsApp)', marker: '{contact_phone}' }
]

// Lista Mockada de Agentes do Workspace para Seleção
const mockAgents = [
  { id: 10001, name: 'João Agente' },
  { id: 10002, name: 'Ana Souza' },
  { id: 10003, name: 'Carlos Consultor' },
  { id: 10004, name: 'Mariana Gerente' }
]

// Adiciona Ação Comercial
const addAction = (type) => {
  const newAction = {
    id: `act_${Date.now()}`,
    action_type: type,
    action_config: {}
  }

  // Configurações Padrão Iniciais por Tipo
  if (type === 'send_whatsapp') {
    newAction.action_config = { template: '' }
  } else if (type === 'move_card') {
    newAction.action_config = { stage_id: null }
  } else if (type === 'assign_agent') {
    newAction.action_config = { assignment_type: 'specific', agent_id: null }
  } else if (type === 'create_task') {
    newAction.action_config = { title: '', due_in_days: 1 }
  } else if (type === 'webhook') {
    newAction.action_config = { url: '' }
  } else if (type === 'update_field') {
    newAction.action_config = { field: null, value: '' }
  }

  localActions.value.push(newAction)
  expandedActionIndex.value = localActions.value.length - 1
  showAddMenu.value = false
  emitActions()
}

// Remove Ação
const removeAction = (index) => {
  localActions.value.splice(index, 1)
  if (expandedActionIndex.value === index) {
    expandedActionIndex.value = null
  } else if (expandedActionIndex.value > index) {
    expandedActionIndex.value--
  }
  emitActions()
}

// Inserir chip de variável na posição do cursor da Textarea (Melhoria premium)
const insertChip = (index, marker) => {
  const textarea = document.getElementById(`wa-template-${index}`)
  if (!textarea) return

  const start = textarea.selectionStart
  const end = textarea.selectionEnd
  const text = localActions.value[index].action_config.template || ''
  
  // Insere a variável e foca de volta na textarea
  localActions.value[index].action_config.template = text.substring(0, start) + marker + text.substring(end)
  emitActions()

  // Seta posição do cursor após a inserção
  setTimeout(() => {
    textarea.focus()
    textarea.selectionStart = textarea.selectionEnd = start + marker.length
  }, 50)
}

const toggleExpand = (index) => {
  expandedActionIndex.value = expandedActionIndex.value === index ? null : index
}

const updateActionConfig = (index) => {
  emitActions()
}

const onAssignmentTypeChange = (index) => {
  const action = localActions.value[index]
  if (action.action_config.assignment_type === 'round_robin') {
    action.action_config.agent_id = null
  }
  emitActions()
}

const onFieldChange = (index) => {
  localActions.value[index].action_config.value = ''
  emitActions()
}

const onDragChange = () => {
  emitActions()
}

const emitActions = () => {
  emit('update:modelValue', localActions.value)
}

// Resumos rápidos para cada ação
const getActionSummary = (action) => {
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
      return `Mover para: "${stage ? stage.name : `Etapa #${config.stage_id}`}"`
    }
    case 'assign_agent':
      return config.assignment_type === 'round_robin'
        ? 'Distribuir automaticamente por Round-robin'
        : `Atribuir para: ${getAgentName(config.agent_id) || 'Selecionar corretor'}`
    case 'create_task':
      return config.title 
        ? `Tarefa: "${config.title}" (Vence em ${config.due_in_days || 0}d)` 
        : 'Criar tarefa em aberto'
    case 'webhook':
      return config.url 
        ? `Enviar HTTP POST para: ${config.url}` 
        : 'URL do Webhook não preenchida'
    case 'update_field': {
      if (!config.field) return 'Nenhum campo selecionado'
      const fieldName = getFieldLabel(config.field)
      return `Definir "${fieldName}" como: "${config.value || 'vazio'}"`
    }
    default:
      return 'Configuração da ação'
  }
}

const getAgentName = (id) => {
  const agent = mockAgents.find(a => a.id === id)
  return agent ? agent.name : ''
}

const getStageTypeLabel = (type) => {
  switch (type) {
    case 'win': return 'Ganho'
    case 'lose': return 'Perdido'
    default: return 'Fase Intermediária'
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

const getActionBadgeBg = (type) => {
  switch (type) {
    case 'send_whatsapp': return 'bg-emerald-50 text-emerald-700'
    case 'move_card': return 'bg-amber-50 text-amber-700'
    case 'assign_agent': return 'bg-purple-50 text-purple-700'
    case 'create_task': return 'bg-blue-50 text-blue-700'
    case 'webhook': return 'bg-slate-50 text-slate-700'
    case 'update_field': return 'bg-pink-50 text-pink-700'
    default: return 'bg-gray-50 text-gray-700'
  }
}

const getFieldLabel = (field) => {
  if (!field) return ''
  if (field.startsWith('custom_fields.')) {
    return field.replace('custom_fields.', '')
  }
  switch (field) {
    case 'title': return 'Título do Negócio'
    case 'value': return 'Valor Estimado'
    case 'contact_email': return 'E-mail'
    case 'contact_phone': return 'Telefone (WhatsApp)'
    default: return field
  }
}

// Busca as chaves de campos personalizados mapeadas nos leads ativos para oferecer no select
const customFieldKeys = computed(() => {
  const keys = new Set()
  pipelineStore.cards.forEach(card => {
    if (card.custom_fields) {
      Object.keys(card.custom_fields).forEach(k => keys.add(k))
    }
  })
  return Array.from(keys)
})

const hasCustomFields = computed(() => customFieldKeys.value.length > 0)
</script>

<style scoped>
.pop-over-enter-active,
.pop-over-leave-active {
  transition: all 0.2s cubic-bezier(0.16, 1, 0.3, 1);
}
.pop-over-enter-from {
  opacity: 0;
  transform: scale(0.95) translateY(-4px);
}
.pop-over-leave-to {
  opacity: 0;
  transform: scale(0.95) translateY(-4px);
}

.collapse-enter-active,
.collapse-leave-active {
  transition: max-height 0.25s cubic-bezier(0.16, 1, 0.3, 1), opacity 0.2s linear;
  max-height: 500px;
  overflow: hidden;
}
.collapse-enter-from,
.collapse-leave-to {
  max-height: 0;
  opacity: 0;
  padding-bottom: 0;
}
</style>
