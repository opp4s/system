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

            <!-- STEP 2: CONDIÇÕES (CONDITIONS) - Placeholder Estruturado para o Dia 17 -->
            <section v-else-if="currentStepIndex === 1" class="animate-fade-in-up space-y-6">
              <div class="space-y-1.5">
                <h3 class="text-xs font-bold text-gray-900">2. Definir regras adicionais (Condições)</h3>
                <p class="text-[11px] text-gray-400">Opcional. Defina regras para filtrar quais leads devem rodar esta automação (ex: "apenas se o valor for maior que R$ 5.000").</p>
              </div>

              <!-- Construtor Visual de Condições (Placeholder Premium) -->
              <div class="bg-white border border-gray-150 rounded-2xl p-5 shadow-sm space-y-4">
                <div class="flex items-center justify-between text-xs pb-3 border-b border-gray-100">
                  <span class="font-bold text-gray-800">Condições de Filtragem</span>
                  <span class="px-2 py-0.5 rounded bg-amber-50 text-amber-700 text-[9px] font-bold uppercase tracking-wider">Breve (Dia 19)</span>
                </div>

                <div class="space-y-3">
                  <div class="p-4 bg-slate-50 border border-gray-150 rounded-xl flex items-center justify-between text-xs text-gray-500 font-semibold italic">
                    Nenhuma regra adicional configurada. O fluxo rodará para todos os leads que dispararem o gatilho.
                  </div>

                  <!-- Botão de simulação -->
                  <button
                    type="button"
                    class="px-4 py-2 border border-dashed border-gray-300 hover:border-slate-800 hover:bg-slate-50/50 text-gray-500 hover:text-slate-900 rounded-xl text-[11px] font-bold transition-all w-full flex items-center justify-center space-x-1.5"
                  >
                    <component :is="Plus" class="h-3.5 w-3.5" />
                    <span>Adicionar Condição</span>
                  </button>
                </div>
              </div>
            </section>

            <!-- STEP 3: AÇÕES (ACTIONS) - Placeholder Estruturado para o Dia 17 -->
            <section v-else-if="currentStepIndex === 2" class="animate-fade-in-up space-y-6">
              <div class="space-y-1.5">
                <h3 class="text-xs font-bold text-gray-900">3. O que esta automação deve fazer? (Ações)</h3>
                <p class="text-[11px] text-gray-400">Escolha uma ou mais ações que serão executadas sequencialmente quando o gatilho for disparado.</p>
              </div>

              <!-- Configurador de Ações (Placeholder Premium) -->
              <div class="bg-white border border-gray-150 rounded-2xl p-5 shadow-sm space-y-4">
                <div class="flex items-center justify-between text-xs pb-3 border-b border-gray-100">
                  <span class="font-bold text-gray-800">Ações Configuradas</span>
                  <span class="px-2 py-0.5 rounded bg-amber-50 text-amber-700 text-[9px] font-bold uppercase tracking-wider">Breve (Dia 18)</span>
                </div>

                <!-- Listagem de Ações Atuais se existirem na edição -->
                <div v-if="localAutomation.actions && localAutomation.actions.length > 0" class="space-y-2.5">
                  <div 
                    v-for="(action, idx) in localAutomation.actions" 
                    :key="action.id || idx"
                    class="p-4 bg-slate-50 border border-gray-150 rounded-xl flex items-center justify-between shadow-sm"
                  >
                    <div class="flex items-center space-x-3 text-xs">
                      <span class="text-base">{{ getActionIcon(action.action_type) }}</span>
                      <div>
                        <span class="font-bold text-gray-900 block leading-tight">{{ getActionTypeLabel(action.action_type) }}</span>
                        <span class="text-[10px] text-gray-400 mt-0.5 block font-medium max-w-md truncate">
                          {{ action.action_config?.template || 'Ação configurada automaticamente' }}
                        </span>
                      </div>
                    </div>
                    <span class="text-[9px] font-bold text-gray-400 uppercase tracking-wider">Ação #{{ idx + 1 }}</span>
                  </div>
                </div>

                <div v-else class="p-4 bg-slate-50 border border-gray-150 rounded-xl flex items-center justify-between text-xs text-gray-500 font-semibold italic">
                  Adicione sua primeira ação (ex: enviar WhatsApp) para que o fluxo tenha efeito.
                </div>

                <!-- Grid de Ações para Adicionar (Botões Simulação) -->
                <div class="grid grid-cols-2 gap-3.5 pt-2">
                  <button
                    v-for="opt in actionOptions"
                    :key="opt.type"
                    type="button"
                    class="p-3 border border-gray-200 hover:border-slate-800 hover:bg-slate-50 text-left rounded-xl transition-all flex items-center space-x-2.5"
                  >
                    <span class="text-base p-1.5 bg-gray-50 rounded-lg group-hover:bg-white">{{ opt.icon }}</span>
                    <div>
                      <span class="text-[11px] font-bold text-gray-800 block">{{ opt.label }}</span>
                      <span class="text-[9px] text-gray-400 block font-medium truncate max-w-[120px]">{{ opt.desc }}</span>
                    </div>
                  </button>
                </div>
              </div>
            </section>

            <!-- STEP 4: REVISÃO & SALVAMENTO (REVIEW) -->
            <section v-else-if="currentStepIndex === 3" class="animate-fade-in-up space-y-6">
              <div class="space-y-1.5">
                <h3 class="text-xs font-bold text-gray-900">4. Revisar e Ativar Automação</h3>
                <p class="text-[11px] text-gray-400">Dê um nome amigável e revise o resumo em linguagem natural do fluxo antes de finalizar.</p>
              </div>

              <div class="bg-white border border-gray-150 rounded-2xl p-6 shadow-sm space-y-5">
                <!-- Nome da Automação -->
                <div class="space-y-1.5">
                  <label class="block text-[11px] font-bold text-gray-700">Nome da Regra de Automação</label>
                  <input
                    v-model="localAutomation.name"
                    type="text"
                    placeholder="Ex: Mensagem de Boas-vindas no WhatsApp"
                    class="block w-full px-4 py-2.5 rounded-xl border border-gray-250 bg-white focus:outline-none focus:border-slate-800 text-xs font-bold text-gray-800 transition-all shadow-sm"
                    :class="{ 'border-rose-350 focus:border-rose-500': showValidationErrors && !localAutomation.name }"
                  />
                  <p v-if="showValidationErrors && !localAutomation.name" class="text-[9px] text-rose-500 font-bold">O nome da automação é obrigatório.</p>
                </div>

                <!-- Resumo Linguagem Natural -->
                <div class="space-y-2 pt-2 border-t border-gray-100">
                  <span class="block text-[10px] font-bold text-gray-400 uppercase tracking-wider">Resumo do Fluxo</span>
                  <div class="bg-slate-50 border border-gray-150 rounded-2xl p-4.5 space-y-3 text-xs leading-relaxed text-slate-700">
                    <!-- Resumo Gatilho -->
                    <div class="flex items-start space-x-2.5">
                      <span class="text-emerald-550 shrink-0 font-bold">QUANDO</span>
                      <span class="font-semibold text-slate-800">{{ getNaturalTriggerText() }}</span>
                    </div>

                    <!-- Resumo Condição -->
                    <div class="flex items-start space-x-2.5 pt-2 border-t border-dashed border-gray-200">
                      <span class="text-blue-550 shrink-0 font-bold">E SE</span>
                      <span class="font-semibold text-slate-800">
                        {{ localAutomation.conditions && localAutomation.conditions.length > 0 ? 'Múltiplas regras adicionais coincidirem.' : 'Não houver regras adicionais (rodar sempre).' }}
                      </span>
                    </div>

                    <!-- Resumo Ações -->
                    <div class="flex items-start space-x-2.5 pt-2 border-t border-dashed border-gray-200">
                      <span class="text-violet-550 shrink-0 font-bold">ENTÃO</span>
                      <div class="min-w-0">
                        <span v-if="localAutomation.actions && localAutomation.actions.length > 0" class="font-semibold text-slate-800">
                          Executar sequencialmente {{ localAutomation.actions.length }} ação(ões):
                          <ul class="list-disc list-inside mt-1 space-y-0.5 text-[11px] text-gray-500">
                            <li v-for="(act, idx) in localAutomation.actions" :key="idx">
                              <strong>{{ getActionTypeLabel(act.action_type) }}</strong>: {{ act.action_config?.template || 'Execução automatizada' }}
                            </li>
                          </ul>
                        </span>
                        <span v-else class="font-semibold text-rose-500 italic block">Nenhuma ação configurada no Passo 3.</span>
                      </div>
                    </div>
                  </div>
                </div>

                <!-- Status de Ativação Toggle -->
                <div class="flex items-center justify-between p-4 bg-slate-50 border border-gray-150 rounded-xl pt-2">
                  <div>
                    <span class="text-xs font-bold text-gray-800 block">Ativar automação imediatamente?</span>
                    <span class="text-[10px] text-gray-400 block font-medium mt-0.5">Se ativa, ela monitorará os eventos a partir de agora.</span>
                  </div>
                  <button
                    @click="localAutomation.active = !localAutomation.active"
                    type="button"
                    class="relative inline-flex h-5.5 w-10 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-150 ease-in-out focus:outline-none"
                    :class="localAutomation.active ? 'bg-slate-950' : 'bg-gray-200'"
                  >
                    <span
                      class="pointer-events-none inline-block h-4.5 w-4.5 transform rounded-full bg-white shadow ring-0 transition duration-150 ease-in-out"
                      :class="localAutomation.active ? 'translate-x-4.5' : 'translate-x-0'"
                    ></span>
                  </button>
                </div>
              </div>
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
import { 
  Zap, 
  X, 
  Loader2, 
  Plus 
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

// Navegação de passos
const nextStep = () => {
  if (currentStepIndex.value === 0) {
    // Validação Passo 1: Deve selecionar um gatilho e configurá-lo
    if (!localAutomation.value.trigger_type) {
      toast.error('Escolha um gatilho para avançar.')
      return
    }
    
    // Validações adicionais específicas
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

// Salva a automação na store
const handleSave = async () => {
  showValidationErrors.value = true
  if (!localAutomation.value.name) {
    toast.error('Nomeie sua automação para salvá-la.')
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

// Helpers para placeholders de ações
const actionOptions = [
  { type: 'send_whatsapp', label: 'Enviar WhatsApp', desc: 'Dispare mensagens', icon: '💬' },
  { type: 'create_task', label: 'Criar Tarefa', desc: 'Agende follow-ups', icon: '📋' },
  { type: 'move_card', label: 'Mover Negócio', desc: 'Mude a etapa do lead', icon: '🔀' },
  { type: 'assign_agent', label: 'Atribuir Agente', desc: 'Troque o responsável', icon: '👤' }
]

const getActionIcon = (type) => {
  switch (type) {
    case 'send_whatsapp': return '💬'
    case 'create_task': return '📋'
    case 'move_card': return '🔀'
    case 'assign_agent': return '👤'
    default: return '⚙️'
  }
}

const getActionTypeLabel = (type) => {
  switch (type) {
    case 'send_whatsapp': return 'Enviar WhatsApp'
    case 'create_task': return 'Criar Tarefa'
    case 'move_card': return 'Mover Negócio'
    case 'assign_agent': return 'Atribuir Agente'
    default: return 'Ação'
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
