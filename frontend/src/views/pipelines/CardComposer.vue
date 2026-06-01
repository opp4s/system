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

    <!-- Área de Digitação (Composer) -->
    <div class="flex items-end space-x-2">
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
        :disabled="sending || !messageText.trim()"
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
import { ref, computed, watch, nextTick } from 'vue'
import { usePipelineStore } from '@/stores/pipeline'
import { useToast } from '@/composables/useToast'
import { 
  Send, 
  MessageSquare, 
  Lock, 
  Check, 
  Loader2 
} from 'lucide-vue-next'

const props = defineProps({
  card: {
    type: Object,
    required: true
  }
})

const emits = defineEmits(['message-sent'])

const pipelineStore = usePipelineStore()
const toast = useToast()

const mode = ref('whatsapp')
const messageText = ref('')
const sending = ref(false)
const statusText = ref('')
const textareaRef = ref(null)
const showToken = ref(false)

// Observa mudança de card para resetar composer e estado local de simulação
watch(() => props.card?.id, () => {
  messageText.value = ''
  statusText.value = ''
  nextTick(() => adjustHeight())
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
  if (!content) return

  sending.value = true
  statusText.value = 'Enviando...'

  try {
    const isPrivate = mode.value === 'note'
    
    // Dispara a action na store
    await pipelineStore.sendMessage(props.card.id, content, isPrivate)
    
    // Limpa o textarea e redefine altura
    messageText.value = ''
    nextTick(() => adjustHeight())

    // Feedback de Sucesso
    statusText.value = isPrivate ? 'Nota salva ✓' : 'Mensagem enviada ✓'
    setTimeout(() => {
      statusText.value = ''
    }, 2000)

    emits('message-sent')
  } catch (error) {
    statusText.value = ''
    toast.error('Erro ao enviar mensagem. Tente novamente.')
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
