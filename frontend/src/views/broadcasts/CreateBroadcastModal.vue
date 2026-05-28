<template>
  <transition name="slide-panel">
    <div class="fixed inset-0 z-45 flex justify-end">
      <!-- Backdrop -->
      <div 
        @click="handleClose"
        class="absolute inset-0 bg-slate-900/40 backdrop-blur-sm transition-opacity duration-300 animate-fade-in"
      ></div>

      <!-- Painel Principal (Slide-in) -->
      <div class="relative w-full max-w-2xl h-full bg-white shadow-2xl flex flex-col z-10 animate-slide-in-right">
        <!-- Header -->
        <header class="h-16 px-6 border-b border-gray-100 flex items-center justify-between shrink-0 bg-white">
          <div class="flex items-center space-x-3">
            <div class="p-2 bg-slate-900 text-white rounded-xl">
              <component :is="Megaphone" class="h-4.5 w-4.5" />
            </div>
            <div>
              <h2 class="text-xs font-bold text-gray-900 leading-none">
                {{ isEdit ? 'Editar Transmissão' : 'Criar Nova Transmissão (Broadcast)' }}
              </h2>
              <p class="text-[10px] text-gray-400 mt-0.5">Dispare mensagens personalizadas em massa para seus contatos.</p>
            </div>
          </div>

          <!-- Passos (Steps Progress) -->
          <nav class="flex items-center space-x-2 text-[10px] font-bold mr-6">
            <div 
              v-for="(step, idx) in steps" 
              :key="step.key"
              class="flex items-center space-x-1"
            >
              <span 
                class="h-5 w-5 rounded-full flex items-center justify-center text-[9px] border transition-all"
                :class="[
                  currentStepIndex === idx
                    ? 'bg-slate-900 border-slate-900 text-white'
                    : currentStepIndex > idx
                      ? 'bg-slate-50 border-slate-900 text-slate-900'
                      : 'bg-white border-gray-200 text-gray-400'
                ]"
              >
                {{ idx + 1 }}
              </span>
              <span 
                class="hidden sm:inline transition-colors"
                :class="currentStepIndex === idx ? 'text-gray-900' : 'text-gray-400'"
              >
                {{ step.label }}
              </span>
              <span v-if="idx < steps.length - 1" class="text-gray-300 mx-0.5 font-normal">→</span>
            </div>
          </nav>

          <button 
            @click="handleClose"
            class="p-2 text-gray-400 hover:text-gray-650 hover:bg-gray-100 rounded-xl transition-all"
          >
            <component :is="X" class="h-4 w-4" />
          </button>
        </header>

        <!-- Corpo Principal (Scroll) -->
        <main class="flex-1 overflow-y-auto p-6 bg-slate-50/30 text-left">
          <div class="max-w-lg mx-auto py-2">
            
            <!-- STEP 1: AUDIÊNCIA -->
            <section v-if="currentStepIndex === 0" class="space-y-5 animate-fade-in-up">
              <div class="space-y-1">
                <h3 class="text-xs font-bold text-gray-900">1. Definir Audiência</h3>
                <p class="text-[11px] text-gray-400">Escolha quais leads receberão esta transmissão filtrando o pipeline.</p>
              </div>

              <!-- Nome da Transmissão -->
              <div class="space-y-1.5">
                <label class="block text-[11px] font-bold text-gray-700">Nome Interno do Broadcast</label>
                <input
                  v-model="form.name"
                  type="text"
                  placeholder="Ex: Follow-up Leads Pós-Demonstração"
                  class="block w-full px-3.5 py-2.5 rounded-xl border border-gray-250 bg-white focus:outline-none focus:border-slate-800 text-xs font-bold text-gray-800 transition-all shadow-sm"
                />
              </div>

              <!-- Filtro de Pipeline -->
              <div class="space-y-1.5">
                <label class="block text-[11px] font-bold text-gray-700">Pipeline de Origem</label>
                <select
                  v-model="form.pipeline_id"
                  @change="onPipelineChange"
                  class="block w-full px-3.5 py-2.5 rounded-xl border border-gray-250 bg-white focus:outline-none focus:border-slate-800 text-xs font-bold text-gray-800 transition-all shadow-sm"
                >
                  <option :value="null">Selecione o pipeline...</option>
                  <option 
                    v-for="pipe in pipelineStore.pipelines" 
                    :key="pipe.id" 
                    :value="pipe.id"
                  >
                    {{ pipe.name }}
                  </option>
                </select>
              </div>

              <!-- Filtro de Etapas (Multi-select simplificado) -->
              <div v-if="form.pipeline_id" class="space-y-2">
                <label class="block text-[11px] font-bold text-gray-700">Etapas do Pipeline</label>
                <div class="bg-white border border-gray-200 rounded-2xl p-4 max-h-40 overflow-y-auto space-y-2">
                  <div 
                    v-for="stage in pipelineStore.stages" 
                    :key="stage.id"
                    class="flex items-center space-x-2.5 text-xs text-gray-800 font-semibold"
                  >
                    <input
                      type="checkbox"
                      :id="'stage-' + stage.id"
                      :value="stage.id"
                      v-model="form.stage_ids"
                      @change="updateAudiencePreview"
                      class="h-4 w-4 rounded border-gray-300 text-slate-900 focus:ring-slate-950 transition-colors"
                    />
                    <label :for="'stage-' + stage.id" class="cursor-pointer flex items-center space-x-1.5">
                      <span class="h-2 w-2 rounded-full" :style="{ backgroundColor: stage.color || '#cbd5e1' }"></span>
                      <span>{{ stage.name }}</span>
                    </label>
                  </div>
                </div>
              </div>

              <!-- Filtro de Tags / Labels (Input texto separado por vírgula) -->
              <div v-if="form.pipeline_id" class="space-y-1.5">
                <label class="block text-[11px] font-bold text-gray-700">Tags de Leads (separadas por vírgula)</label>
                <input
                  v-model="form.labels_text"
                  @input="onLabelsInput"
                  type="text"
                  placeholder="Ex: quente, decisor, urgente"
                  class="block w-full px-3.5 py-2.5 rounded-xl border border-gray-250 bg-white focus:outline-none focus:border-slate-800 text-xs font-bold text-gray-800 transition-all shadow-sm"
                />
              </div>

              <!-- Preview de Audiência -->
              <div class="p-4 rounded-2xl border border-slate-900/10 flex items-center justify-between" :class="previewColorClass">
                <div class="flex items-center space-x-3">
                  <span class="text-2xl select-none">🎯</span>
                  <div>
                    <span class="text-xs font-bold text-slate-800 block">Preview da Audiência</span>
                    <span class="text-[10px] text-gray-400 block font-medium leading-normal">
                      Contatos que atendem aos filtros definidos.
                    </span>
                  </div>
                </div>
                <div class="text-right">
                  <span class="text-xl font-black text-slate-900 block">
                    {{ broadcastStore.loading.preview ? '...' : broadcastStore.previewCount }}
                  </span>
                  <span class="text-[9px] font-bold text-slate-500 uppercase tracking-wider">Contatos</span>
                </div>
              </div>
            </section>

            <!-- STEP 2: COMPOSER DE MENSAGEM & PREVIEW -->
            <section v-else-if="currentStepIndex === 1" class="space-y-5 animate-fade-in-up">
              <div class="space-y-1">
                <h3 class="text-xs font-bold text-gray-900">2. Escrever Mensagem</h3>
                <p class="text-[11px] text-gray-400">Escreva sua mensagem com variáveis personalizáveis e mídias.</p>
              </div>

              <!-- Variáveis Chips -->
              <div class="space-y-1.5">
                <label class="block text-[10px] font-bold text-gray-400 uppercase tracking-wider">Variáveis Dinâmicas</label>
                <div class="flex flex-wrap gap-1.5">
                  <button
                    v-for="v in variables"
                    :key="v.tag"
                    @click="insertVariable(v.tag)"
                    type="button"
                    class="px-2.5 py-1 bg-slate-100 hover:bg-slate-200 text-slate-800 border border-slate-200 rounded-xl text-[10px] font-bold transition-all flex items-center space-x-1"
                  >
                    <span>➕</span>
                    <span>{{ v.label }}</span>
                  </button>
                </div>
              </div>

              <!-- Textarea Mensagem -->
              <div class="space-y-1.5">
                <div class="flex items-center justify-between">
                  <label class="block text-[11px] font-bold text-gray-700">Mensagem do WhatsApp</label>
                  <span class="text-[9px] font-bold text-gray-400">
                    {{ form.message.length }} caracteres
                  </span>
                </div>
                <textarea
                  ref="msgTextarea"
                  v-model="form.message"
                  rows="6"
                  placeholder="Escreva a mensagem aqui..."
                  class="block w-full px-3.5 py-2.5 rounded-2xl border border-gray-250 bg-white focus:outline-none focus:border-slate-800 text-xs font-medium text-gray-800 transition-all shadow-sm leading-relaxed"
                ></textarea>
              </div>

              <!-- Envio de Mídia Opcional -->
              <div class="space-y-1.5">
                <label class="block text-[11px] font-bold text-gray-700">Anexo de Mídia Opcional (Imagem/PDF)</label>
                <div class="border border-dashed border-gray-200 rounded-2xl p-4 bg-white flex flex-col items-center justify-center space-y-2">
                  <component :is="Paperclip" class="h-5 w-5 text-gray-400" />
                  <div class="text-center">
                    <span class="text-[10px] font-bold text-gray-700 block">Arraste um arquivo ou clique para selecionar</span>
                    <span class="text-[9px] text-gray-400 block mt-0.5">Suporta imagens (PNG, JPG) ou documentos (PDF) de até 5MB</span>
                  </div>
                  <input 
                    type="text" 
                    v-model="form.media_url" 
                    placeholder="Cole a URL da imagem/documento (opcional)" 
                    class="block w-full mt-2 px-3 py-1.5 rounded-xl border border-gray-200 text-[10px] text-gray-750 focus:outline-none focus:border-slate-800"
                  />
                  <p class="text-[8px] text-gray-450 italic">// Mídia opcional com suporte a URL de anexo</p>
                </div>
              </div>

              <!-- Preview no Celular (WhatsApp Simulator) -->
              <div class="space-y-1.5">
                <span class="block text-[10px] font-bold text-gray-400 uppercase tracking-wider">Preview Visual no WhatsApp</span>
                <div class="bg-[#efeae2] border border-gray-200 rounded-3xl p-4 max-w-sm mx-auto shadow-inner relative overflow-hidden">
                  <!-- Header Simulator -->
                  <div class="h-10 bg-[#075e54] -mt-4 -mx-4 mb-3 px-4 flex items-center space-x-2 text-white shrink-0">
                    <span class="h-6 w-6 rounded-full bg-slate-350 text-[10px] font-bold text-slate-800 flex items-center justify-center select-none">Z</span>
                    <div>
                      <span class="text-[10px] font-bold block leading-none">Cliente de Exemplo</span>
                      <span class="text-[8px] text-[#128c7e] block leading-none font-bold mt-0.5">Online</span>
                    </div>
                  </div>

                  <!-- Bolha de Chat -->
                  <div class="bg-white rounded-2xl p-3 shadow-sm text-[11px] leading-relaxed text-gray-800 relative max-w-[85%] float-left border border-gray-150">
                    <!-- Preview Imagem se houver -->
                    <div v-if="form.media_url" class="mb-2 rounded-xl overflow-hidden max-h-28 bg-gray-100 flex items-center justify-center">
                      <img :src="form.media_url" class="object-cover w-full h-full" alt="Mídia anexa" @error="handleMediaError" />
                    </div>
                    <p class="whitespace-pre-wrap">{{ formatPreviewMessage() }}</p>
                    <span class="text-[8px] text-gray-400 text-right block mt-1">13:00</span>
                  </div>
                  <div class="clear-both"></div>
                </div>
              </div>
            </section>

            <!-- STEP 3: AGENDAMENTO & RESUMO -->
            <section v-else-if="currentStepIndex === 2" class="space-y-5 animate-fade-in-up">
              <div class="space-y-1">
                <h3 class="text-xs font-bold text-gray-900">3. Configurar Envio</h3>
                <p class="text-[11px] text-gray-400">Decida se deseja disparar imediatamente ou programar uma data.</p>
              </div>

              <!-- Escolha de Método -->
              <div class="grid grid-cols-2 gap-4">
                <button
                  @click="form.send_type = 'now'"
                  type="button"
                  class="p-4 rounded-2xl border text-center transition-all flex flex-col items-center justify-center space-y-2"
                  :class="form.send_type === 'now' ? 'bg-slate-900 border-slate-900 text-white shadow' : 'bg-white border-gray-200 text-gray-700 hover:border-gray-300'"
                >
                  <component :is="Zap" class="h-5 w-5" />
                  <span class="text-[11px] font-bold">Enviar Agora</span>
                </button>

                <button
                  @click="form.send_type = 'scheduled'"
                  type="button"
                  class="p-4 rounded-2xl border text-center transition-all flex flex-col items-center justify-center space-y-2"
                  :class="form.send_type === 'scheduled' ? 'bg-slate-900 border-slate-900 text-white shadow' : 'bg-white border-gray-200 text-gray-700 hover:border-gray-300'"
                >
                  <component :is="Calendar" class="h-5 w-5" />
                  <span class="text-[11px] font-bold">Agendar Envio</span>
                </button>
              </div>

              <!-- Configuração Data/Hora se Agendado -->
              <div v-if="form.send_type === 'scheduled'" class="p-4 bg-white border border-gray-200 rounded-2xl space-y-3">
                <span class="text-[10px] font-bold text-gray-400 uppercase tracking-wider block">Escolha Data e Horário</span>
                <div class="grid grid-cols-2 gap-3">
                  <div>
                    <label class="block text-[9px] font-bold text-gray-500 mb-1">Data</label>
                    <input
                      v-model="form.date"
                      type="date"
                      class="block w-full px-3 py-2 rounded-xl border border-gray-250 text-xs font-bold focus:outline-none"
                    />
                  </div>
                  <div>
                    <label class="block text-[9px] font-bold text-gray-500 mb-1">Horário</label>
                    <input
                      v-model="form.time"
                      type="time"
                      class="block w-full px-3 py-2 rounded-xl border border-gray-250 text-xs font-bold focus:outline-none"
                    />
                  </div>
                </div>
              </div>

              <!-- Resumo do Envio -->
              <div class="p-5 bg-slate-900/5 border border-slate-900/10 rounded-2xl text-slate-800 space-y-2">
                <span class="text-[9px] font-bold text-gray-400 uppercase tracking-wider block">Resumo do Envio</span>
                <p class="text-xs font-bold leading-relaxed">
                  📢 Broadcast: <span class="underline text-slate-950 font-black">{{ form.name || 'Sem nome' }}</span>
                </p>
                <p class="text-xs font-bold leading-relaxed">
                  👥 Alcance: <span class="text-slate-950 font-black">{{ broadcastStore.previewCount }} contatos</span>
                </p>
                <p class="text-xs font-bold leading-relaxed">
                  ⏰ Programação: 
                  <span class="text-slate-950 font-black">
                    {{ form.send_type === 'now' ? 'Disparar IMEDIATAMENTE' : `Agendado para ${formatScheduleDisplay()}` }}
                  </span>
                </p>
              </div>
            </section>

          </div>
        </main>

        <!-- Footer -->
        <footer class="h-16 px-6 border-t border-gray-100 flex items-center justify-between shrink-0 bg-gray-50/50">
          <div>
            <button
              v-if="currentStepIndex > 0"
              @click="prevStep"
              type="button"
              class="px-4 py-2 border border-gray-250 hover:bg-gray-100 text-gray-650 rounded-xl text-xs font-bold transition-all"
            >
              Voltar
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

            <!-- Avançar / Confirmar -->
            <button
              v-if="currentStepIndex < steps.length - 1"
              @click="nextStep"
              type="button"
              class="px-5 py-2 bg-slate-900 hover:bg-slate-800 text-white rounded-xl text-xs font-bold transition-all shadow"
            >
              Avançar
            </button>

            <button
              v-else
              @click="handleSaveAndSend"
              :disabled="broadcastStore.loading.mutation"
              type="button"
              class="px-5 py-2 bg-slate-900 hover:bg-slate-850 text-white disabled:bg-slate-400 rounded-xl text-xs font-bold transition-all shadow flex items-center space-x-1.5"
            >
              <component :is="Loader2" v-if="broadcastStore.loading.mutation" class="h-3.5 w-3.5 animate-spin" />
              <span>{{ form.send_type === 'now' ? 'Confirmar e Enviar' : 'Confirmar Agendamento' }}</span>
            </button>
          </div>
        </footer>
      </div>
    </div>
  </transition>
</template>

<script setup>
import { ref, watch, onMounted, computed } from 'vue'
import { useBroadcastStore } from '@/stores/broadcast'
import { usePipelineStore } from '@/stores/pipeline'
import { useToast } from '@/composables/useToast'
import { 
  Megaphone, 
  X, 
  Paperclip, 
  Zap, 
  Calendar, 
  Loader2 
} from 'lucide-vue-next'

const props = defineProps({
  broadcast: {
    type: Object,
    default: null
  }
})

const emit = defineEmits(['close', 'saved'])

const broadcastStore = useBroadcastStore()
const pipelineStore = usePipelineStore()
const toast = useToast()

const isEdit = ref(false)
const currentStepIndex = ref(0)
const msgTextarea = ref(null)

const steps = [
  { key: 'audience', label: 'Audiência' },
  { key: 'message', label: 'Mensagem' },
  { key: 'schedule', label: 'Agendamento' }
]

// Lista de variáveis disponíveis
const variables = [
  { tag: '{nome}', label: 'Nome do Contato' },
  { tag: '{telefone}', label: 'Telefone' },
  { tag: '{email}', label: 'Email' }
]

// Form data inicial
const form = ref({
  name: '',
  pipeline_id: null,
  stage_ids: [],
  labels_text: '',
  labels: [],
  message: '',
  media_url: '',
  send_type: 'now',
  date: '',
  time: ''
})

onMounted(async () => {
  if (pipelineStore.pipelines.length === 0) {
    await pipelineStore.fetchPipelines()
  }
  
  if (props.broadcast) {
    isEdit.value = true
    const b = props.broadcast
    form.value = {
      id: b.id,
      name: b.name,
      pipeline_id: b.pipeline_id || null,
      stage_ids: b.stage_ids || [],
      labels_text: b.labels ? b.labels.join(', ') : '',
      labels: b.labels || [],
      message: b.message || '',
      media_url: b.media_url || '',
      send_type: b.scheduled_at ? 'scheduled' : 'now',
      date: b.scheduled_at ? b.scheduled_at.split('T')[0] : '',
      time: b.scheduled_at ? b.scheduled_at.split('T')[1].substring(0, 5) : ''
    }
    
    if (form.value.pipeline_id) {
      await pipelineStore.fetchStages(form.value.pipeline_id)
      await updateAudiencePreview()
    }
  } else {
    isEdit.value = false
    // Define o pipeline atual da store de pipelines se houver
    form.value.pipeline_id = pipelineStore.currentPipelineId || (pipelineStore.pipelines[0]?.id || null)
    if (form.value.pipeline_id) {
      await pipelineStore.fetchStages(form.value.pipeline_id)
      await updateAudiencePreview()
    }
  }
  
  window.addEventListener('keydown', handleKeyDown)
})

const handleKeyDown = (e) => {
  if (e.key === 'Escape') {
    handleClose()
  }
}

const handleClose = () => {
  window.removeEventListener('keydown', handleKeyDown)
  emit('close')
}

const onPipelineChange = async () => {
  form.value.stage_ids = []
  if (form.value.pipeline_id) {
    await pipelineStore.fetchStages(form.value.pipeline_id)
  }
  await updateAudiencePreview()
}

const onLabelsInput = () => {
  form.value.labels = form.value.labels_text
    .split(',')
    .map(t => t.trim())
    .filter(t => t !== '')
  updateAudiencePreview()
}

const updateAudiencePreview = async () => {
  if (!form.value.pipeline_id) {
    broadcastStore.previewCount = 0
    return
  }
  
  const params = {
    pipeline_id: form.value.pipeline_id,
    stage_ids: form.value.stage_ids,
    labels: form.value.labels
  }
  await broadcastStore.fetchPreview(params)
}

const previewColorClass = computed(() => {
  if (broadcastStore.previewCount === 0) return 'bg-rose-50/50 border-rose-100'
  return 'bg-emerald-50/50 border-emerald-100'
})

// Navegação entre steps com validações
const nextStep = () => {
  if (currentStepIndex.value === 0) {
    if (!form.value.name) {
      toast.error('Dê um nome interno para este broadcast.')
      return
    }
    if (!form.value.pipeline_id) {
      toast.error('Selecione o pipeline de origem.')
      return
    }
    if (broadcastStore.previewCount === 0) {
      toast.warning('A audiência estimada é de 0 contatos. Verifique seus filtros.')
    }
  } else if (currentStepIndex.value === 1) {
    if (!form.value.message) {
      toast.error('Escreva a mensagem a ser transmitida.')
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

// Inserir variáveis no cursor do textarea
const insertVariable = (tag) => {
  const textarea = msgTextarea.value
  if (!textarea) return

  const start = textarea.selectionStart
  const end = textarea.selectionEnd
  const text = form.value.message

  form.value.message = text.substring(0, start) + tag + text.substring(end)
  
  // Reposiciona o cursor após inserir o chip
  setTimeout(() => {
    textarea.focus()
    const newPos = start + tag.length
    textarea.setSelectionRange(newPos, newPos)
  }, 10)
}

// Formatador da bolha de chat
const formatPreviewMessage = () => {
  let msg = form.value.message || 'Digite sua mensagem para pré-visualizar...'
  msg = msg.replace(/{nome}/g, 'João Silva')
  msg = msg.replace(/{telefone}/g, '+55 11 99999-9999')
  msg = msg.replace(/{email}/g, 'joao.silva@email.com')
  msg = msg.replace(/{value}/g, 'R$ 10.000,00')
  return msg
}

// Helper para display do horário agendado
const formatScheduleDisplay = () => {
  if (!form.value.date || !form.value.time) return '[Data e Horário não configurados]'
  const dateParts = form.value.date.split('-')
  return `${dateParts[2]}/${dateParts[1]}/${dateParts[0]} às ${form.value.time}`
}

const handleMediaError = (e) => {
  // Placeholder ou remover visualmente
  console.warn('Falha ao carregar imagem de anexo')
}

// Salva e agenda ou envia agora
const handleSaveAndSend = async () => {
  if (form.value.send_type === 'scheduled' && (!form.value.date || !form.value.time)) {
    toast.error('Selecione a data e hora do agendamento.')
    return
  }

  try {
    let saved
    const payload = {
      name: form.value.name,
      pipeline_id: form.value.pipeline_id,
      stage_ids: form.value.stage_ids,
      labels: form.value.labels,
      message: form.value.message,
      media_url: form.value.media_url || null
    }

    if (isEdit.value) {
      saved = await broadcastStore.updateBroadcast(form.value.id, payload)
    } else {
      saved = await broadcastStore.createBroadcast(payload)
    }

    if (saved) {
      if (form.value.send_type === 'now') {
        await broadcastStore.sendNow(saved.id)
        toast.success('Transmissão enviada com sucesso!')
      } else {
        const scheduledDateTime = `${form.value.date}T${form.value.time}:00Z`
        await broadcastStore.scheduleBroadcast(saved.id, scheduledDateTime)
        toast.success(`Transmissão agendada com sucesso para ${formatScheduleDisplay()}!`)
      }
      
      window.removeEventListener('keydown', handleKeyDown)
      emit('saved')
    }
  } catch (error) {
    toast.error('Erro ao salvar ou disparar transmissão.')
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
</style>
