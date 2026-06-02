<template>
  <div class="audio-player-container flex flex-col w-full max-w-[300px]">
    <div class="audio-player flex items-center gap-3 p-3 rounded-2xl"
         :class="isOutgoing ? 'bg-slate-800 text-white' : 'bg-slate-100 text-slate-800 border border-slate-200/50'">
      
      <!-- Botão Play/Pause -->
      <button @click="togglePlay" class="flex-shrink-0 w-9 h-9 rounded-full flex items-center justify-center transition-all duration-150"
              :class="isOutgoing ? 'bg-slate-700 hover:bg-slate-650 text-white' : 'bg-white hover:bg-slate-50 text-slate-800 shadow-sm border border-slate-200/50'">
        <svg v-if="!isPlaying" class="w-4.5 h-4.5 ml-0.5" fill="currentColor" viewBox="0 0 24 24">
          <path d="M8 5v14l11-7z"/>
        </svg>
        <svg v-else class="w-4.5 h-4.5" fill="currentColor" viewBox="0 0 24 24">
          <path d="M6 19h4V5H6v14zm8-14v14h4V5h-4z"/>
        </svg>
      </button>

      <!-- Barra de progresso + tempos -->
      <div class="flex-1 min-w-0">
        <div class="relative h-1 rounded-full cursor-pointer bg-slate-350"
             :class="isOutgoing ? 'bg-slate-600' : 'bg-slate-300'"
             @click="seek($event)">
          <div class="absolute h-full rounded-full"
               :class="isOutgoing ? 'bg-white' : 'bg-slate-850'"
               :style="{ width: progress + '%' }"></div>
          <div class="absolute w-2.5 h-2.5 rounded-full -top-[3px] -ml-[5px]"
               :class="isOutgoing ? 'bg-white' : 'bg-slate-850'"
               :style="{ left: progress + '%' }"></div>
        </div>
        <div class="flex justify-between mt-1.5 select-none">
          <span class="text-[9px] font-bold opacity-60 tabular-nums">{{ formatTime(currentTime) }}</span>
          <span class="text-[9px] font-bold opacity-60 tabular-nums">{{ formatTime(duration) }}</span>
        </div>
      </div>

      <!-- Botão Transcrição (T) -->
      <button @click="requestTranscription" 
              class="flex-shrink-0 w-8 h-8 rounded-full flex items-center justify-center text-xs font-black transition-all duration-150"
              :class="[
                hasTranscription 
                  ? 'bg-emerald-500 hover:bg-emerald-600 text-white shadow-sm' 
                  : (isOutgoing ? 'bg-slate-700 hover:bg-slate-650 text-slate-300' : 'bg-slate-200 hover:bg-slate-300 text-slate-600')
              ]"
              :title="hasTranscription ? 'Ver transcrição (T)' : 'Transcrever áudio (T)'">
        T
      </button>

      <!-- Elemento audio hidden -->
      <audio ref="audioEl" :src="audioUrl" @loadedmetadata="onLoaded" @timeupdate="onTimeUpdate" @ended="onEnded"></audio>
    </div>

    <!-- Transcrição (abaixo do player, dentro da bolha) -->
    <div v-if="showTranscription && transcriptionText" 
         class="mt-2 text-xs leading-relaxed border-t pt-2 border-dashed select-text"
         :class="isOutgoing ? 'text-slate-300 border-slate-700/60' : 'text-slate-600 border-slate-200'">
      <div class="flex items-start gap-1">
        <span class="text-xs">📝</span>
        <p class="italic">{{ transcriptionText }}</p>
      </div>
    </div>
    
    <!-- Loading transcrição -->
    <div v-if="isTranscribing" 
         class="mt-2 text-[10px] text-slate-400 italic flex items-center gap-1 select-none">
      <span>⏳</span>
      <span>Transcrevendo áudio...</span>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch } from 'vue'

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

const progress = computed(() => {
  if (!duration.value || isNaN(duration.value) || !isFinite(duration.value)) return 0
  return (currentTime.value / duration.value) * 100
})

const hasTranscription = computed(() => !!props.transcription)
const transcriptionText = computed(() => props.transcription)

// Monitora se a transcrição chegou pelo polling
watch(() => props.transcription, (newVal) => {
  if (newVal) {
    isTranscribing.value = false
    showTranscription.value = true
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

function onTimeUpdateFallback() {
  if (audioEl.value) {
    currentTime.value = audioEl.value.currentTime
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
  }
}

function formatTime(seconds) {
  if (seconds === undefined || seconds === null || isNaN(seconds) || !isFinite(seconds)) return '00:00'
  const m = Math.floor(seconds / 60)
  const s = Math.floor(seconds % 60)
  return `${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`
}
</script>
