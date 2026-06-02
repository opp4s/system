<template>
  <div class="audio-player-container flex flex-col w-full max-w-[320px] select-none">
    <div class="audio-player flex items-center gap-3 px-3 py-2 rounded-full w-full h-12"
         :class="isOutgoing ? 'bg-slate-800 text-white' : 'bg-slate-100 text-slate-800 border border-slate-200/50'">
      
      <!-- Botão Play/Pause -->
      <button @click="togglePlay" class="flex-shrink-0 w-8 h-8 rounded-full flex items-center justify-center transition-all duration-150"
              :class="isOutgoing ? 'bg-slate-700 hover:bg-slate-600 text-white' : 'bg-white hover:bg-slate-50 text-slate-800 shadow-sm border border-slate-200/50'">
        <svg v-if="!isPlaying" class="w-4 h-4 ml-0.5" fill="currentColor" viewBox="0 0 24 24">
          <path d="M8 5v14l11-7z"/>
        </svg>
        <svg v-else class="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
          <path d="M6 19h4V5H6v14zm8-14v14h4V5h-4z"/>
        </svg>
      </button>

      <!-- Barra de progresso (Seek bar) -->
      <div class="flex-1 min-w-0 h-full flex items-center">
        <div class="relative w-full h-1 rounded-full cursor-pointer"
             :class="isOutgoing ? 'bg-slate-600' : 'bg-slate-300'"
             @click="seek($event)">
          <div class="absolute h-full rounded-full"
               :class="isOutgoing ? 'bg-white' : 'bg-slate-800'"
               :style="{ width: progress + '%' }"></div>
          <div class="absolute w-2.5 h-2.5 rounded-full -top-[3px] -ml-[5px]"
               :class="isOutgoing ? 'bg-white' : 'bg-slate-800'"
               :style="{ left: progress + '%' }"></div>
        </div>
      </div>

      <!-- Tempo Formatado (MM:SS) -->
      <span class="flex-shrink-0 text-[10px] font-bold opacity-75 tabular-nums min-w-[32px] text-center">
        {{ formatTime(isPlaying ? currentTime : duration) }}
      </span>

      <!-- Botão Transcrição (T) -->
      <button @click="requestTranscription" 
              class="flex-shrink-0 w-7 h-7 rounded-full flex items-center justify-center text-xs font-black transition-all duration-150"
              :class="[
                hasTranscription && showTranscription
                  ? 'bg-emerald-500 text-white shadow-sm'
                  : hasTranscription
                    ? 'bg-emerald-500/20 text-emerald-500 border border-emerald-500/30'
                    : (isOutgoing ? 'bg-slate-700 hover:bg-slate-600 text-slate-300' : 'bg-slate-200 hover:bg-slate-300 text-slate-600')
              ]"
              :title="hasTranscription ? 'Esconder transcrição' : 'Mostrar transcrição'">
        T
      </button>

      <!-- Elemento audio oculto -->
      <audio ref="audioEl" :src="audioUrl" @loadedmetadata="onLoaded" @timeupdate="onTimeUpdate" @ended="onEnded"></audio>
    </div>

    <!-- Bloco de Transcrição (abaixo do player, dentro do balão de mensagem) -->
    <div v-if="showTranscription && transcriptionText" 
         class="mt-2 text-xs leading-relaxed border-t pt-2 border-dashed select-text"
         :class="isOutgoing ? 'text-slate-300 border-slate-700/60' : 'text-slate-600 border-slate-200'">
      <div class="flex items-start gap-1">
        <span class="text-xs shrink-0 select-none">📝</span>
        <p class="italic">{{ transcriptionText }}</p>
      </div>
    </div>
    
    <!-- Indicador de Transcrevendo (apenas sob demanda) -->
    <div v-if="isTranscribing" 
         class="mt-2 text-[10px] text-slate-400 italic flex items-center gap-1 select-none">
      <span>⏳</span>
      <span>Transcrevendo áudio...</span>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch, onUnmounted } from 'vue'

const props = defineProps({
  audioUrl: {
    type: String,
    required: true
  },
  isOutgoing: {
    type: Boolean,
    default: false
  },
  transcription: {
    type: String,
    default: null
  },
  messageId: {
    type: Number,
    required: true
  }
})

const audioEl = ref(null)
const isPlaying = ref(false)
const currentTime = ref(0)
const duration = ref(0)
const showTranscription = ref(false)
const isTranscribing = ref(false)
let transcribeTimeout = null

const progress = computed(() => {
  if (!duration.value || isNaN(duration.value) || !isFinite(duration.value)) return 0
  return (currentTime.value / duration.value) * 100
})

const hasTranscription = computed(() => !!props.transcription)
const transcriptionText = computed(() => props.transcription)

// Se a transcrição chegar via polling, atualiza e exibe
watch(() => props.transcription, (newVal) => {
  if (newVal) {
    if (transcribeTimeout) {
      clearTimeout(transcribeTimeout)
      transcribeTimeout = null
    }
    isTranscribing.value = false
    showTranscription.value = true
  }
})

onUnmounted(() => {
  if (transcribeTimeout) {
    clearTimeout(transcribeTimeout)
  }
})

function togglePlay() {
  if (!audioEl.value) return
  if (isPlaying.value) {
    audioEl.value.pause()
    isPlaying.value = false
  } else {
    audioEl.value.play().then(() => {
      isPlaying.value = true
    }).catch(err => {
      console.error('Erro ao tocar áudio:', err)
    })
  }
}

function onLoaded() {
  if (audioEl.value) {
    const d = audioEl.value.duration
    if (isFinite(d) && !isNaN(d)) {
      duration.value = d
    }
  }
}

function onTimeUpdate() {
  if (audioEl.value) {
    currentTime.value = audioEl.value.currentTime
    const d = audioEl.value.duration
    if (duration.value !== d && isFinite(d) && !isNaN(d)) {
      duration.value = d
    }
  }
}

function onEnded() {
  isPlaying.value = false
  currentTime.value = 0
}

function seek(e) {
  if (!audioEl.value || !duration.value || isNaN(duration.value) || !isFinite(duration.value)) return
  const rect = e.currentTarget.getBoundingClientRect()
  const pct = (e.clientX - rect.left) / rect.width
  const targetTime = pct * duration.value
  audioEl.value.currentTime = targetTime
  currentTime.value = targetTime
}

function requestTranscription() {
  if (hasTranscription.value) {
    showTranscription.value = !showTranscription.value
  } else {
    isTranscribing.value = true
    showTranscription.value = true
    
    if (transcribeTimeout) clearTimeout(transcribeTimeout)
    
    // Oculta a mensagem de "Transcrevendo..." após no máximo 30 segundos
    transcribeTimeout = setTimeout(() => {
      isTranscribing.value = false
    }, 30000)
  }
}

function formatTime(seconds) {
  if (seconds === undefined || seconds === null || isNaN(seconds) || !isFinite(seconds)) return '00:00'
  const m = Math.floor(seconds / 60)
  const s = Math.floor(seconds % 60)
  return `${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`
}
</script>
