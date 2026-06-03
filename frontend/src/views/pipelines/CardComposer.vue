<template>
  <div class="border-t border-gray-200 bg-white p-4 space-y-3">
    <!-- Controles de Modo (WhatsApp / Nota Interna) -->
    <div class="flex items-center space-x-2">
      <!-- Botão Modo WhatsApp -->
      <button
        type="button"
        @click="mode = 'whatsapp'"
        class="flex items-center space-x-1.5 px-3 py-1.5 rounded-xl text-xs font-bold transition-all"
        :class="[
          mode === 'whatsapp'
            ? 'bg-zavy-50 text-zavy-600 ring-1 ring-zavy-500/20'
            : 'text-gray-500 hover:text-gray-700 hover:bg-gray-50'
        ]"
      >
        <component :is="MessageSquare" class="h-3.5 w-3.5" />
        <span>WhatsApp</span>
      </button>

      <!-- Botão Modo Nota Interna -->
      <button
        type="button"
        @click="mode = 'note'"
        class="flex items-center space-x-1.5 px-3 py-1.5 rounded-xl text-xs font-bold transition-all"
        :class="[
          mode === 'note'
            ? 'bg-amber-50 text-amber-700 ring-1 ring-amber-500/20'
            : 'text-gray-500 hover:text-gray-700 hover:bg-gray-50'
        ]"
      >
        <component :is="Lock" class="h-3.5 w-3.5" />
        <span>Nota Interna</span>
      </button>
    </div>

    <!-- Staging Area de Arquivo Anexo -->
    <div v-if="stagedFile" class="animate-scale-up">
      <!-- Se for Imagem -->
      <div v-if="stagedFile.type.startsWith('image/')" class="flex items-center space-x-3 p-2 bg-slate-50 border border-slate-200 rounded-xl relative group">
        <div class="h-12 w-12 rounded-lg overflow-hidden border border-slate-200 bg-white shrink-0">
          <img :src="stagedPreview" class="h-full w-full object-cover" />
        </div>
        <div class="flex-1 min-w-0">
          <p class="text-xs font-bold text-slate-700 truncate">{{ stagedFile.name }}</p>
          <p class="text-[10px] text-slate-400">{{ formatSize(stagedFile.size) }}</p>
        </div>
        <button 
          type="button" 
          @click="removeStagedFile"
          class="p-1.5 hover:bg-slate-200 rounded-lg text-slate-500 hover:text-slate-700 transition-colors"
          title="Remover arquivo"
        >
          <component :is="X" class="h-4 w-4" />
        </button>
      </div>

      <!-- Se for Áudio -->
      <div v-else-if="stagedFile.type.startsWith('audio/')" class="flex items-center space-x-3 p-2.5 bg-slate-50 border border-slate-200 rounded-xl relative group">
        <div class="h-10 w-10 rounded-lg bg-indigo-50 border border-indigo-100 flex items-center justify-center shrink-0">
          <span class="text-lg">🎙</span>
        </div>
        <div class="flex-1 min-w-0 flex flex-col md:flex-row md:items-center md:space-x-3">
          <div class="shrink-0 mb-1 md:mb-0">
            <p class="text-xs font-bold text-slate-700 truncate">{{ stagedFile.name }}</p>
            <p class="text-[10px] text-slate-400 font-medium">{{ formatSize(stagedFile.size) }}</p>
          </div>
          <audio controls class="w-full max-w-[240px] h-8 shrink-0 select-none">
            <source :src="stagedPreview" :type="stagedFile.type" />
          </audio>
        </div>
        <button 
          type="button" 
          @click="removeStagedFile"
          class="p-1.5 hover:bg-slate-200 rounded-lg text-slate-500 hover:text-slate-700 transition-colors"
          title="Remover gravação"
        >
          <component :is="X" class="h-4 w-4" />
        </button>
      </div>

      <!-- Se for outro tipo de arquivo (Documento, etc.) -->
      <div v-else class="flex items-center space-x-3 p-2 bg-slate-50 border border-slate-200 rounded-xl">
        <div class="h-10 w-10 rounded-lg bg-slate-100 border border-slate-150 flex items-center justify-center shrink-0">
          <span class="text-xl">📄</span>
        </div>
        <div class="flex-1 min-w-0">
          <p class="text-xs font-bold text-slate-700 truncate">{{ stagedFile.name }}</p>
          <p class="text-[10px] text-slate-400">{{ formatSize(stagedFile.size) }}</p>
        </div>
        <button 
          type="button" 
          @click="removeStagedFile"
          class="p-1.5 hover:bg-slate-200 rounded-lg text-slate-500 hover:text-slate-700 transition-colors"
          title="Remover arquivo"
        >
          <component :is="X" class="h-4 w-4" />
        </button>
      </div>
    </div>

    <!-- Preview da Mensagem sendo Respondida -->
    <div v-if="replyingTo" class="animate-scale-up bg-slate-50 border border-slate-200 rounded-xl p-2.5 flex items-start space-x-3 relative">
      <div class="flex-1 min-w-0 border-l-2 border-slate-300 pl-2">
        <p class="text-[10px] font-bold text-slate-400 uppercase tracking-wide">Respondendo a {{ replyingTo.sender_name }}</p>
        <p class="text-xs text-slate-650 truncate italic">"{{ replyingTo.content }}"</p>
      </div>
      <button type="button" @click="$emit('cancel-reply')" class="p-1 hover:bg-slate-200 rounded text-slate-500 hover:text-slate-700 transition-colors" title="Cancelar resposta">
        <component :is="X" class="h-3.5 w-3.5" />
      </button>
    </div>

    <!-- Área de Digitação (Composer) -->
    <div class="flex items-end space-x-2">
      <!-- Se estiver gravando áudio -->
      <div v-if="isRecording" class="flex-1 flex items-center justify-between bg-red-50 border border-red-200 rounded-xl px-4 py-2.5 animate-scale-up h-[42px] select-none">
        <div class="flex items-center space-x-2">
          <span class="h-2.5 w-2.5 rounded-full bg-red-550 bg-red-600 animate-pulse"></span>
          <span class="text-xs font-bold text-red-600">Gravando... {{ formatTime(recordingDuration) }}</span>
        </div>
        <div class="flex items-center space-x-2 shrink-0">
          <button 
            type="button" 
            @click="stopRecording" 
            class="flex items-center space-x-1.5 px-3 py-1 bg-red-600 hover:bg-red-700 text-white rounded-lg text-xs font-bold transition-all"
            title="Parar gravação"
          >
            <component :is="Square" class="h-3.5 w-3.5" />
            <span>Parar</span>
          </button>
          <button 
            type="button" 
            @click="discardRecording" 
            class="p-1.5 hover:bg-red-100 rounded-lg text-red-605 text-red-600 hover:text-red-800 transition-colors"
            title="Descartar gravação"
          >
            <component :is="X" class="h-4 w-4" />
          </button>
        </div>
      </div>

      <!-- Modo normal de Digitação -->
      <template v-else>
        <!-- Botão Clip Anexo -->
        <button
          type="button"
          @click="triggerFileSelect"
          class="p-3 text-gray-400 hover:text-gray-650 hover:bg-gray-100 rounded-xl transition-all duration-150 shrink-0"
          title="Anexar arquivo (imagem, documento)"
        >
          <component :is="Paperclip" class="h-4 w-4" />
        </button>

        <!-- Botão Gravar Mensagem de Voz -->
        <button
          type="button"
          @click="startRecording"
          class="p-3 text-gray-400 hover:text-gray-650 hover:bg-gray-100 rounded-xl transition-all duration-150 shrink-0"
          title="Gravar mensagem de voz"
        >
          <component :is="Mic" class="h-4 w-4" />
        </button>

        <!-- File input invisível -->
        <input
          ref="fileInputRef"
          type="file"
          class="hidden"
          @change="handleFileChange"
        />

        <div class="flex-1 relative">
          <textarea
            ref="textareaRef"
            v-model="messageText"
            @input="adjustHeight"
            @keydown="handleKeyDown"
            :placeholder="
              mode === 'whatsapp'
                ? 'Digite uma mensagem (Ctrl+Enter para enviar)...'
                : 'Digite uma nota interna privada (Ctrl+Enter para enviar)...'
            "
            rows="1"
            class="block w-full px-4 py-3 rounded-xl border focus:outline-none focus:ring-1 bg-gray-50/20 text-xs transition-all resize-none max-h-[200px] overflow-y-auto"
            :class="[
              mode === 'whatsapp'
                ? 'border-gray-250 focus:border-zavy-500 focus:ring-zavy-500'
                : 'border-gray-250 focus:border-amber-500 focus:ring-amber-500'
            ]"
          ></textarea>
        </div>

        <!-- Botão Enviar -->
        <button
          type="button"
          @click="send"
          :disabled="sending || (!messageText.trim() && !stagedFile)"
          class="p-3 text-white rounded-xl shadow transition-all duration-150 shrink-0 disabled:bg-gray-300 disabled:text-gray-400 disabled:shadow-none disabled:cursor-not-allowed"
          :class="[
            mode === 'whatsapp' 
              ? 'bg-slate-900 hover:bg-slate-800 shadow-slate-900/10' 
              : 'bg-amber-600 hover:bg-amber-700 shadow-amber-600/10'
          ]"
        >
          <component 
            :is="sending ? Loader2 : Send" 
            class="h-4 w-4"
            :class="{'animate-spin': sending}"
          />
        </button>
      </template>
    </div>

    <!-- Indicador de Status Discreto -->
    <div class="flex items-center justify-between text-[10px] text-gray-400 px-1">
      <div class="flex items-center space-x-1">
        <transition name="fade">
          <span v-if="sending" class="text-zavy-600 font-semibold animate-pulse">Enviando...</span>
          <span v-else-if="statusText" class="text-emerald-600 font-bold flex items-center">
            <component :is="Check" class="h-3 w-3 mr-0.5 text-emerald-500" />
            {{ statusText }}
          </span>
        </transition>
      </div>
      <span class="text-gray-400">Ctrl + Enter para enviar</span>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch, nextTick, onUnmounted } from 'vue'
import { usePipelineStore } from '@/stores/pipeline'
import { useToast } from '@/composables/useToast'
import api from '@/plugins/axios'
import { 
  Send, 
  MessageSquare, 
  Lock, 
  Check, 
  Loader2,
  Paperclip,
  X,
  Mic,
  Square
} from 'lucide-vue-next'

const props = defineProps({
  card: {
    type: Object,
    required: true
  },
  replyingTo: {
    type: Object,
    default: null
  }
})

const emits = defineEmits(['message-sent', 'cancel-reply', 'whatsapp-error'])

const pipelineStore = usePipelineStore()
const toast = useToast()

const mode = ref('whatsapp')
const messageText = ref('')
const sending = ref(false)
const statusText = ref('')
const textareaRef = ref(null)
const showToken = ref(false)

const fileInputRef = ref(null)

// Staging Area State
const stagedFile = ref(null)
const stagedPreview = ref(null)

// Audio Recording State
const isRecording = ref(false)
const mediaRecorder = ref(null)
const audioChunks = ref([])
const recordingDuration = ref(0)
const recordingInterval = ref(null)

// Iniciar gravação
const startRecording = async () => {
  try {
    const stream = await navigator.mediaDevices.getUserMedia({ audio: true })
    audioChunks.value = []

    let options = { mimeType: 'audio/webm;codecs=opus' }
    try {
      mediaRecorder.value = new MediaRecorder(stream, options)
    } catch (e) {
      // Fallback para Safari e outros navegadores sem suporte webm opus
      mediaRecorder.value = new MediaRecorder(stream)
    }

    mediaRecorder.value.ondataavailable = (e) => {
      if (e.data && e.data.size > 0) {
        audioChunks.value.push(e.data)
      }
    }
    
    mediaRecorder.value.onstop = () => {
      const blob = new Blob(audioChunks.value, { type: 'audio/ogg' })
      const file = new File([blob], `audio-${Date.now()}.ogg`, { type: 'audio/ogg' })
      
      removeStagedFile()
      
      stagedFile.value = file
      stagedPreview.value = URL.createObjectURL(blob)
      stream.getTracks().forEach(t => t.stop())
    }

    mediaRecorder.value.start()
    isRecording.value = true
    recordingDuration.value = 0
    recordingInterval.value = setInterval(() => {
      recordingDuration.value++
    }, 1000)
  } catch (err) {
    console.error('Erro ao acessar microfone:', err)
    toast.error('Erro ao acessar microfone. Verifique as permissões.')
  }
}

// Parar gravação
const stopRecording = () => {
  if (mediaRecorder.value && mediaRecorder.value.state !== 'inactive') {
    mediaRecorder.value.stop()
  }
  isRecording.value = false
  if (recordingInterval.value) {
    clearInterval(recordingInterval.value)
    recordingInterval.value = null
  }
}

// Descartar gravação
const discardRecording = () => {
  stopRecording()
  removeStagedFile()
}

// Formatar tempo (segundos em MM:SS)
const formatTime = (seconds) => {
  const m = Math.floor(seconds / 60).toString().padStart(2, '0')
  const s = (seconds % 60).toString().padStart(2, '0')
  return `${m}:${s}`
}

const triggerFileSelect = () => {
  if (fileInputRef.value) {
    fileInputRef.value.click()
  }
}

const handleFileChange = (e) => {
  const file = e.target.files[0]
  if (!file) return

  const maxSize = 16 * 1024 * 1024 // 16MB
  const allowedTypes = [
    'image/png', 'image/jpeg', 'image/jpg', 'image/webp', 'image/gif',
    'application/pdf',
    'audio/ogg', 'audio/mpeg', 'audio/mp4', 'audio/aac',
    'video/mp4', 'video/quicktime',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
  ]

  if (file.size > maxSize) {
    toast.error('Arquivo muito grande (máximo 16MB)')
    return
  }
  if (!allowedTypes.includes(file.type)) {
    toast.error('Tipo de arquivo não permitido')
    return
  }

  // Remove staged file anterior
  removeStagedFile()

  // Coloca o arquivo em staging
  stagedFile.value = file
  if (file.type.startsWith('image/') || file.type.startsWith('audio/')) {
    stagedPreview.value = URL.createObjectURL(file)
  }

  // Reseta o input para permitir selecionar o mesmo arquivo novamente
  if (fileInputRef.value) {
    fileInputRef.value.value = ''
  }
}

const removeStagedFile = () => {
  if (stagedPreview.value) {
    URL.revokeObjectURL(stagedPreview.value)
    stagedPreview.value = null
  }
  stagedFile.value = null
  if (fileInputRef.value) {
    fileInputRef.value.value = ''
  }
}

const formatSize = (bytes) => {
  if (bytes === undefined || bytes === null || isNaN(bytes)) return '0 B'
  const k = 1024
  const sizes = ['B', 'KB', 'MB', 'GB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i]
}

// Observa mudança de card para resetar composer e staging
watch(() => props.card?.id, () => {
  messageText.value = ''
  statusText.value = ''
  discardRecording()
  nextTick(() => adjustHeight())
})

onUnmounted(() => {
  if (recordingInterval.value) {
    clearInterval(recordingInterval.value)
  }
  removeStagedFile()
})

// Auto-resize do textarea
const adjustHeight = () => {
  if (textareaRef.value) {
    textareaRef.value.style.height = 'auto'
    textareaRef.value.style.height = Math.min(textareaRef.value.scrollHeight, 200) + 'px'
  }
}

// Escuta Ctrl+Enter e Cmd+Enter para enviar
const handleKeyDown = (e) => {
  if ((e.ctrlKey || e.metaKey) && e.key === 'Enter') {
    e.preventDefault()
    send()
  }
}

// Ação de envio de mensagem
const send = async () => {
  const content = messageText.value.trim()
  const file = stagedFile.value

  if (!content && !file) return

  sending.value = true
  statusText.value = 'Enviando...'

  try {
    const isPrivate = mode.value === 'note'
    let newMessage

    if (file) {
      const formData = new FormData()
      formData.append('message[content]', content)
      formData.append('message[attachment]', file)
      formData.append('message[private_note]', isPrivate.toString())
      if (props.replyingTo) {
        formData.append('message[in_reply_to]', props.replyingTo.id)
      }

      const response = await api.post(`/api/v1/cards/${props.card.id}/messages`, formData, {
        headers: { 'Content-Type': 'multipart/form-data' }
      })
      newMessage = response.data.data || response.data
    } else {
      const payload = {
        message: {
          content: content,
          private_note: isPrivate
        }
      }
      if (props.replyingTo) {
        payload.message.in_reply_to = props.replyingTo.id
      }
      const response = await api.post(`/api/v1/cards/${props.card.id}/messages`, payload)
      newMessage = response.data.data || response.data
    }

    const exists = pipelineStore.cardTimeline.some(item => item.id === newMessage.id)
    if (!exists) {
      pipelineStore.cardTimeline.push(newMessage)
    }

    // Limpa o textarea e staging
    messageText.value = ''
    removeStagedFile()
    nextTick(() => adjustHeight())

    // Feedback de Sucesso
    statusText.value = isPrivate ? 'Nota salva ✓' : 'Mensagem enviada ✓'
    setTimeout(() => {
      statusText.value = ''
    }, 2000)

    emits('message-sent')
  } catch (error) {
    statusText.value = ''
    const errMsg = error.response?.data?.error || 'Erro ao enviar mensagem. Tente novamente.'
    const errCode = error.response?.data?.code
    toast.error(errMsg)
    console.error(error)
    
    if (errCode === 'whatsapp_unavailable' || error.response?.status === 422) {
      emits('whatsapp-error', { message: errMsg, code: errCode })
    }
  } finally {
    sending.value = false
  }
}
</script>

<style scoped>
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.2s ease;
}
.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

@keyframes scaleUp {
  from {
    opacity: 0;
    transform: scale(0.97);
  }
  to {
    opacity: 1;
    transform: scale(1);
  }
}
.animate-scale-up {
  animation: scaleUp 0.15s cubic-bezier(0.16, 1, 0.3, 1) forwards;
}
</style>
