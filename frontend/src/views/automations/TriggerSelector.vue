<template>
  <div class="space-y-6">
    <div class="space-y-1.5">
      <h3 class="text-xs font-bold text-gray-900">1. Quando este fluxo deve começar?</h3>
      <p class="text-[11px] text-gray-400">Escolha o evento (gatilho) que acionará as ações automáticas deste pipeline.</p>
    </div>

    <!-- Cards de Gatilhos -->
    <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
      <div
        v-for="trigger in triggerOptions"
        :key="trigger.type"
        @click="selectTrigger(trigger.type)"
        class="border border-gray-150 rounded-2xl p-4 cursor-pointer transition-all duration-250 flex flex-col text-left relative overflow-hidden group select-none"
        :class="[
          modelValue.trigger_type === trigger.type
            ? 'border-slate-900 bg-slate-50/50 shadow-sm ring-1 ring-slate-900'
            : 'bg-white hover:border-gray-300 hover:shadow-sm'
        ]"
      >
        <!-- Badge Ativo -->
        <div 
          v-if="modelValue.trigger_type === trigger.type"
          class="absolute top-3.5 right-3.5 h-4.5 w-4.5 rounded-full bg-slate-950 text-white flex items-center justify-center text-[10px] font-bold"
        >
          ✓
        </div>

        <div class="flex items-center space-x-3 mb-2">
          <div 
            class="p-2 rounded-xl text-base transition-colors"
            :class="[
              modelValue.trigger_type === trigger.type
                ? 'bg-slate-950 text-white'
                : 'bg-slate-50 text-slate-650 group-hover:bg-slate-100'
            ]"
          >
            <component :is="trigger.icon" class="h-4 w-4" />
          </div>
          <span class="text-xs font-bold text-gray-900 leading-snug">{{ trigger.title }}</span>
        </div>

        <p class="text-[11px] leading-normal text-gray-450 font-medium">
          {{ trigger.description }}
        </p>
      </div>
    </div>

    <!-- Painel de Configurações Específicas do Gatilho -->
    <transition name="fade-slide">
      <div 
        v-if="modelValue.trigger_type"
        class="bg-slate-50 border border-gray-150 rounded-2xl p-5 space-y-4"
      >
        <div class="flex items-center space-x-2 pb-3 border-b border-gray-150/60">
          <span class="text-[10px] font-bold text-slate-800 uppercase tracking-wider">Parâmetros do Gatilho</span>
          <span class="text-gray-300">•</span>
          <span class="text-[11px] text-gray-450 font-semibold">{{ getActiveTriggerTitle() }}</span>
        </div>

        <!-- 1. Card Criado (Sem configurações extras) -->
        <div v-if="modelValue.trigger_type === 'card_created'" class="text-[11px] text-gray-400 py-2 flex items-center space-x-2">
          <component :is="Info" class="h-4 w-4 text-gray-300 shrink-0" />
          <span>Este gatilho não requer configurações extras. Ele é ativado assim que um novo negócio é inserido neste funil.</span>
        </div>

        <!-- 2. Card Entrou na Etapa -->
        <div v-else-if="modelValue.trigger_type === 'card_enters_stage'" class="space-y-2">
          <label class="block text-[11px] font-bold text-gray-700">Selecione a Etapa Comercial</label>
          <div class="relative">
            <select
              v-model="localConfig.stage_id"
              @change="updateConfig"
              class="block w-full px-3 py-2.5 rounded-xl border border-gray-250 bg-white focus:outline-none focus:border-slate-800 text-xs font-bold text-gray-800 transition-all shadow-sm"
            >
              <option :value="null" disabled>Escolha uma etapa...</option>
              <option 
                v-for="stage in pipelineStore.stages" 
                :key="stage.id" 
                :value="stage.id"
              >
                {{ stage.name }} ({{ getStageTypeLabel(stage.stage_type) }})
              </option>
            </select>
          </div>
          <p class="text-[10px] text-gray-400 font-medium">As ações serão acionadas imediatamente quando o lead for arrastado ou movido para a etapa selecionada.</p>
        </div>

        <!-- 3. Tempo na Etapa (Estagnação) -->
        <div v-else-if="modelValue.trigger_type === 'time_in_stage'" class="space-y-4">
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div class="space-y-1.5">
              <label class="block text-[11px] font-bold text-gray-700">Etapa sob Monitoramento</label>
              <select
                v-model="localConfig.stage_id"
                @change="updateConfig"
                class="block w-full px-3 py-2.5 rounded-xl border border-gray-250 bg-white focus:outline-none focus:border-slate-800 text-xs font-bold text-gray-800 transition-all shadow-sm"
              >
                <option :value="null" disabled>Escolha uma etapa...</option>
                <option 
                  v-for="stage in pipelineStore.stages" 
                  :key="stage.id" 
                  :value="stage.id"
                >
                  {{ stage.name }}
                </option>
              </select>
            </div>

            <div class="space-y-1.5">
              <label class="block text-[11px] font-bold text-gray-700">Tempo de Estagnação (dias)</label>
              <div class="relative rounded-xl shadow-sm">
                <input
                  v-model.number="localConfig.days"
                  @input="updateConfig"
                  type="number"
                  min="1"
                  placeholder="Ex: 3"
                  class="block w-full px-3 py-2.5 rounded-xl border border-gray-250 bg-white focus:outline-none focus:border-slate-800 text-xs font-bold text-gray-800 transition-all shadow-sm"
                />
              </div>
            </div>
          </div>
          <p class="text-[10px] text-gray-400 font-medium">As ações serão disparadas se o lead permanecer nesta etapa sem modificações por mais tempo do que o limite definido.</p>
        </div>

        <!-- 4. Campo Alterado -->
        <div v-else-if="modelValue.trigger_type === 'card_updated'" class="space-y-3">
          <label class="block text-[11px] font-bold text-gray-700">Selecione o Campo para Monitoramento</label>
          <select
            v-model="localConfig.field"
            @change="updateConfig"
            class="block w-full px-3 py-2.5 rounded-xl border border-gray-250 bg-white focus:outline-none focus:border-slate-800 text-xs font-bold text-gray-800 transition-all shadow-sm"
          >
            <option :value="null" disabled>Escolha um campo...</option>
            <optgroup label="Campos Padrão">
              <option value="title">Título do Negócio</option>
              <option value="value">Valor Estimado</option>
              <option value="contact_name">Nome do Contato</option>
              <option value="contact_email">E-mail</option>
              <option value="contact_phone">Telefone (WhatsApp)</option>
              <option value="user_id">Responsável (Agente)</option>
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
          <p class="text-[10px] text-gray-400 font-medium">O fluxo será iniciado reativamente no instante em que o valor do campo selecionado for alterado.</p>
        </div>
      </div>
    </transition>
  </div>
</template>

<script setup>
import { ref, watch, computed } from 'vue'
import { usePipelineStore } from '@/stores/pipeline'
import { 
  PlusCircle, 
  Target, 
  Clock, 
  Edit3, 
  Info 
} from 'lucide-vue-next'

const props = defineProps({
  modelValue: {
    type: Object,
    required: true,
    default: () => ({
      trigger_type: '',
      trigger_config: {}
    })
  }
})

const emit = defineEmits(['update:modelValue'])
const pipelineStore = usePipelineStore()

// Opções de Gatilhos Comerciais
const triggerOptions = [
  {
    type: 'card_created',
    title: 'Lead Criado',
    description: 'Executa o fluxo quando um novo negócio é inserido no funil.',
    icon: PlusCircle
  },
  {
    type: 'card_enters_stage',
    title: 'Entrou na Etapa',
    description: 'Inicia o fluxo assim que o lead é movido para uma etapa específica.',
    icon: Target
  },
  {
    type: 'time_in_stage',
    title: 'Parado na Etapa',
    description: 'Dispara quando o lead fica estagnado por X dias em uma etapa.',
    icon: Clock
  },
  {
    type: 'card_updated',
    title: 'Campo Alterado',
    description: 'Ativa o fluxo quando dados específicos do lead são modificados.',
    icon: Edit3
  }
]

// Estado de Configurações Localizado
const localConfig = ref({
  stage_id: null,
  days: 1,
  field: null
})

// Sincroniza estado inicial a partir do modelValue
watch(
  () => props.modelValue,
  (newVal) => {
    if (newVal.trigger_config) {
      localConfig.value = {
        stage_id: newVal.trigger_config.stage_id || null,
        days: newVal.trigger_config.days || 1,
        field: newVal.trigger_config.field || null
      }
    }
  },
  { immediate: true, deep: true }
)

// Seleção de gatilho
const selectTrigger = (type) => {
  // Limpa configurações locais de acordo com o tipo
  localConfig.value = {
    stage_id: null,
    days: type === 'time_in_stage' ? 3 : 1,
    field: null
  }
  
  emit('update:modelValue', {
    trigger_type: type,
    trigger_config: getSanitizedConfig(type)
  })
}

// Atualização de Configuração Local
const updateConfig = () => {
  emit('update:modelValue', {
    ...props.modelValue,
    trigger_config: getSanitizedConfig(props.modelValue.trigger_type)
  })
}

// Sanitização de Configurações por tipo
const getSanitizedConfig = (type) => {
  const config = {}
  if (type === 'card_enters_stage') {
    config.stage_id = localConfig.value.stage_id ? Number(localConfig.value.stage_id) : null
  } else if (type === 'time_in_stage') {
    config.stage_id = localConfig.value.stage_id ? Number(localConfig.value.stage_id) : null
    config.days = localConfig.value.days ? Number(localConfig.value.days) : 1
  } else if (type === 'card_updated') {
    config.field = localConfig.value.field || null
  }
  return config
}

// Helpers textuais e dados
const getActiveTriggerTitle = () => {
  const opt = triggerOptions.find(t => t.type === props.modelValue.trigger_type)
  return opt ? opt.title : ''
}

const getStageTypeLabel = (type) => {
  switch (type) {
    case 'win': return 'Ganho'
    case 'lose': return 'Perdido'
    default: return 'Fase Intermediária'
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
.fade-slide-enter-active,
.fade-slide-leave-active {
  transition: all 0.25s cubic-bezier(0.16, 1, 0.3, 1);
}
.fade-slide-enter-from {
  opacity: 0;
  transform: translateY(8px);
}
.fade-slide-leave-to {
  opacity: 0;
  transform: translateY(-8px);
}
</style>
