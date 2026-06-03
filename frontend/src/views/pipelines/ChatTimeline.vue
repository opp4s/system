<template>
  <section class="flex-1 flex flex-col bg-slate-50/50 overflow-hidden h-full">
    <!-- Filtro de Abas no Topo do Chat (WhatsApp, Nota Interna, Histórico) -->
    <div class="h-11 px-6 border-b border-gray-100 flex items-center space-x-5 bg-white shrink-0">
      <button 
        v-for="tab in ['whatsapp', 'notes', 'history']" 
        :key="tab"
        @click="rightActiveTab = tab"
        class="h-full border-b-2 text-xs font-bold transition-all px-1 focus:outline-none"
        :class="rightActiveTab === tab ? 'border-slate-900 text-slate-900' : 'border-transparent text-gray-400 hover:text-gray-600'"
      >
        {{ tab === 'whatsapp' ? 'WhatsApp' : tab === 'notes' ? 'Nota Interna' : 'Histórico' }}
      </button>
    </div>

    <!-- Area de Mensagens / Chat -->
    <div 
      ref="timelineContainer" 
      class="flex-1 overflow-y-auto p-6 space-y-6 scroll-smooth flex flex-col"
    >
      <!-- Loader da Timeline -->
      <div v-if="pipelineStore.loading.timeline && pipelineStore.cardTimeline.length === 0" class="space-y-4">
        <div v-for="i in 3" :key="i" class="h-20 bg-white border border-gray-150 rounded-2xl animate-pulse"></div>
      </div>

      <!-- Se a timeline filtrada estiver vazia -->
      <div v-else-if="filteredTimelineEvents.length === 0" class="h-full flex flex-col items-center justify-center text-center text-sm text-gray-455 py-12 flex-1">
        <component :is="MessageSquare" class="h-10 w-10 text-gray-300 mb-2" />
        <template v-if="rightActiveTab === 'whatsapp'">
          <span class="font-bold text-gray-700 block mb-1">Nenhuma mensagem ainda</span>
          <span class="text-xs text-gray-400">As mensagens aparecerão aqui quando o contato enviar via WhatsApp</span>
        </template>
        <template v-else-if="rightActiveTab === 'notes'">
          <span class="font-bold text-gray-700 block mb-1">Nenhuma nota interna registrada</span>
          <span class="text-xs text-gray-400">Escreva uma nota interna no compositor abaixo para guardar lembretes</span>
        </template>
        <template v-else>
          <span class="font-bold text-gray-700 block mb-1">Nenhum evento registrado</span>
          <span class="text-xs text-gray-400">O histórico de auditoria de etapas e criação aparecerá aqui</span>
        </template>
      </div>

      <!-- Lista Agrupada por Data -->
      <div v-else class="space-y-6">
        <div 
          v-for="group in groupedTimeline" 
          :key="group.date"
          class="space-y-4"
        >
          <!-- Separador de data do chat -->
          <div class="flex justify-center my-4">
            <span class="px-3 py-1 bg-gray-200/80 text-gray-600 rounded-full text-[10px] font-bold tracking-wide shadow-sm">
              {{ group.date }}
            </span>
          </div>

          <!-- Feed do Chat/Eventos -->
          <div class="space-y-3">
            <template v-for="event in group.events" :key="event.id">
              <!-- 1. Renderização de Mensagens (Tipo = message) -->
              <div 
                v-if="event.event_type === 'message'"
                class="flex w-full animate-fade-in"
                :class="[
                  event.message_type === 'outgoing' 
                    ? 'justify-end' 
                    : (event.message_type === 'private' ? 'justify-center' : 'justify-start')
                ]"
              >
                <!-- Bolha de Mensagem Outgoing (Enviada pelo Agente Zavy) -->
                <div 
                  v-if="event.message_type === 'outgoing'"
                  class="max-w-[70%] flex flex-col items-end space-y-1 relative group"
                >
                  <!-- Botão Responder para Outgoing -->
                  <button 
                    @click="triggerReply(event)"
                    class="opacity-0 group-hover:opacity-100 absolute left-[-32px] top-1/2 -translate-y-1/2 p-1.5 hover:bg-slate-200 rounded-lg text-slate-400 hover:text-slate-600 transition-all select-none"
                    title="Responder"
                  >
                    <component :is="CornerUpLeft" class="h-3.5 w-3.5" />
                  </button>

                  <div class="flex items-center space-x-1.5 text-[9px] font-bold text-slate-400 pr-1 select-none">
                    <span>{{ getSenderDisplayName(event) }}</span>
                    <span>{{ formatTimeOnly(event.created_at) }}</span>
                    <span class="text-emerald-500 font-bold">✓✓</span>
                  </div>
                  <div class="bg-slate-900 text-white rounded-2xl rounded-tr-none px-4 py-2.5 shadow-sm text-left w-full">
                    <!-- Quote/Reply Reference -->
                    <div v-if="event.in_reply_to" class="mb-2">
                      <div class="text-[10px] bg-slate-800 border-l-2 border-slate-500 px-2 py-1 rounded text-slate-350">
                        <span class="font-bold text-slate-400">Respondendo a:</span>
                        <span class="italic block truncate">"{{ getQuotePreview(event.in_reply_to) }}"</span>
                      </div>
                    </div>

                    <!-- Exibição de Anexos -->
                    <div v-if="event.attachments && event.attachments.length > 0" class="mb-2 space-y-2">
                      <div v-for="(att, attIdx) in event.attachments" :key="event.id + '-att-' + attIdx">
                        <!-- Imagem: preview inline -->
                        <div v-if="isImage(att)" class="my-1 cursor-pointer" @click="openLightbox(att.url)">
                          <img :src="att.url" 
                               :alt="att.filename"
                               class="max-w-[200px] max-h-[200px] rounded-lg object-cover hover:opacity-90 transition-opacity"
                               @error="handleImageError($event)" />
                        </div>

                        <!-- Vídeo: player inline -->
                        <div v-else-if="isVideo(att)" class="my-1">
                          <video controls class="max-w-[240px] max-h-[240px] rounded-lg">
                            <source :src="att.url" :type="att.content_type || 'video/mp4'" />
                          </video>
                        </div>

                        <!-- Áudio: player inline customizado -->
                        <div v-else-if="isAudio(att)" class="my-1.5 w-full">
                          <AudioPlayer 
                            :audio-url="att.url"
                            :is-outgoing="true"
                            :transcription="getTranscription(event)"
                            :message-id="event.id"
                          />
                        </div>

                        <!-- Documento: link para download -->
                        <a v-else :href="att.url" target="_blank"
                           class="flex items-center justify-between gap-3 p-3 bg-slate-800 border border-slate-700/60 rounded-xl hover:bg-slate-750 transition-colors w-full max-w-[280px]">
                          <div class="flex items-center gap-2 min-w-0">
                            <span class="text-lg shrink-0">📄</span>
                            <div class="min-w-0">
                              <p class="text-xs text-white font-bold truncate">{{ att.filename || 'Arquivo' }}</p>
                              <p class="text-[9px] text-slate-300 font-bold">{{ formatSize(att.size) }}</p>
                            </div>
                          </div>
                          <span class="text-[10px] font-black text-white bg-slate-700 border border-slate-600 px-2 py-1 rounded-lg uppercase tracking-wider hover:bg-slate-650 shrink-0">
                            Abrir
                          </span>
                        </a>
                      </div>
                    </div>
                    <p v-if="shouldShowContent(event)" class="text-xs leading-relaxed whitespace-pre-wrap">{{ event.content }}</p>
                  </div>
                </div>

                <!-- Bolha de Mensagem Incoming (Recebida do Cliente) -->
                <div 
                  v-else-if="event.message_type === 'incoming'"
                  class="max-w-[70%] flex flex-col items-start space-y-1 relative group"
                >
                  <!-- Botão Responder para Incoming -->
                  <button 
                    @click="triggerReply(event)"
                    class="opacity-0 group-hover:opacity-100 absolute right-[-32px] top-1/2 -translate-y-1/2 p-1.5 hover:bg-slate-200 rounded-lg text-slate-400 hover:text-slate-600 transition-all select-none"
                    title="Responder"
                  >
                    <component :is="CornerUpLeft" class="h-3.5 w-3.5" />
                  </button>

                  <div class="flex items-center space-x-1.5 text-[9px] font-bold text-zavy-600 pl-1 select-none">
                    <span>{{ event.sender_name || card?.contact_name || 'Cliente' }}</span>
                    <span class="text-slate-450">{{ formatTimeOnly(event.created_at) }}</span>
                  </div>
                  <div class="bg-white border border-slate-200 text-slate-800 rounded-2xl rounded-tl-none px-4 py-2.5 shadow-sm text-left w-full">
                    <!-- Quote/Reply Reference -->
                    <div v-if="event.in_reply_to" class="mb-2">
                      <div class="text-[10px] bg-slate-100 border-l-2 border-slate-300 px-2 py-1 rounded text-slate-600">
                        <span class="font-bold text-slate-400">Respondendo a:</span>
                        <span class="italic block truncate">"{{ getQuotePreview(event.in_reply_to) }}"</span>
                      </div>
                    </div>

                    <!-- Exibição de Anexos -->
                    <div v-if="event.attachments && event.attachments.length > 0" class="mb-2 space-y-2">
                      <div v-for="(att, attIdx) in event.attachments" :key="event.id + '-att-' + attIdx">
                        <!-- Imagem: preview inline -->
                        <div v-if="isImage(att)" class="my-1 cursor-pointer" @click="openLightbox(att.url)">
                          <img :src="att.url" 
                               :alt="att.filename"
                               class="max-w-[200px] max-h-[200px] rounded-lg object-cover hover:opacity-90 transition-opacity"
                               @error="handleImageError($event)" />
                        </div>

                        <!-- Vídeo: player inline -->
                        <div v-else-if="isVideo(att)" class="my-1">
                          <video controls class="max-w-[240px] max-h-[240px] rounded-lg">
                            <source :src="att.url" :type="att.content_type || 'video/mp4'" />
                          </video>
                        </div>

                        <!-- Áudio: player inline customizado -->
                        <div v-else-if="isAudio(att)" class="my-1.5 w-full">
                          <AudioPlayer 
                            :audio-url="att.url"
                            :is-outgoing="false"
                            :transcription="getTranscription(event)"
                            :message-id="event.id"
                          />
                        </div>

                        <!-- Documento: link para download -->
                        <a v-else :href="att.url" target="_blank"
                           class="flex items-center justify-between gap-3 p-3 bg-slate-50 border border-slate-200/60 rounded-xl hover:bg-slate-100 transition-colors w-full max-w-[280px]">
                          <div class="flex items-center gap-2 min-w-0">
                            <span class="text-lg shrink-0">📄</span>
                            <div class="min-w-0">
                              <p class="text-xs text-slate-850 font-bold truncate">{{ att.filename || 'Arquivo' }}</p>
                              <p class="text-[9px] text-slate-400 font-bold">{{ formatSize(att.size) }}</p>
                            </div>
                          </div>
                          <span class="text-[10px] font-black text-zavy-600 bg-zavy-50 border border-zavy-200 px-2 py-1 rounded-lg uppercase tracking-wider hover:bg-zavy-150 shrink-0">
                            Abrir
                          </span>
                        </a>
                      </div>
                    </div>
                    <p v-if="shouldShowContent(event)" class="text-xs leading-relaxed whitespace-pre-wrap">{{ event.content }}</p>
                  </div>
                </div>

                <!-- Bolha de Nota Interna (Privada) -->
                <div 
                  v-else-if="event.message_type === 'private'"
                  class="max-w-[85%] bg-amber-50 border border-amber-200 text-amber-900 rounded-2xl px-4 py-3 shadow-inner space-y-1.5 text-left w-full mx-6"
                >
                  <div class="flex items-center justify-between">
                    <span class="text-[9px] font-bold uppercase tracking-wider text-amber-700 flex items-center space-x-1">
                      <span class="w-1.5 h-1.5 rounded-full bg-amber-500"></span>
                      <span>Nota Interna</span>
                    </span>
                    <span class="text-[9px] text-amber-600 font-medium">{{ formatTimeOnly(event.created_at) }}</span>
                  </div>
                  <p class="text-xs leading-relaxed whitespace-pre-wrap">{{ event.content }}</p>
                  <div class="text-[9px] text-amber-600 font-semibold flex items-center space-x-1">
                    <span>Por: {{ event.user?.name || 'Agente' }}</span>
                  </div>
                </div>
              </div>

              <!-- 2. Renderização de Eventos de Sistema (Criado, Movido, Atualizado) -->
              <div v-else class="flex justify-center my-2.5">
                <span class="px-3.5 py-1 bg-gray-200/50 text-gray-500 rounded-full text-[10px] font-semibold flex items-center space-x-1.5 border border-gray-150/40">
                  <component :is="getEventIcon(event.event_type)" class="h-3 w-3 shrink-0 text-gray-400" />
                  <span>{{ event.description }}</span>
                  <span v-if="event.user" class="text-gray-400 font-medium">• por {{ event.user.name }}</span>
                  <span class="text-gray-400 font-medium">• {{ formatTimeOnly(event.created_at) }}</span>
                </span>
              </div>
            </template>
          </div>
        </div>
      </div>
    </div>

    <!-- Banner de erro do WhatsApp -->
    <div 
      v-if="isWhatsappUnavailableError" 
      class="mx-4 mt-2 p-3 bg-rose-50 border border-rose-200 rounded-xl flex items-start justify-between shadow-sm animate-scale-up shrink-0"
    >
      <div class="flex items-start space-x-2">
        <span class="text-rose-500 shrink-0 text-sm mt-0.5">⚠️</span>
        <div class="text-xs text-rose-800 font-semibold leading-normal">
          {{ lastErrorMessage || 'WhatsApp desconectado. Reconecte para enviar.' }}
        </div>
      </div>
      <router-link 
        to="/settings/whatsapp" 
        class="shrink-0 text-xs font-black text-rose-600 hover:text-rose-800 hover:underline flex items-center space-x-1 pl-3 whitespace-nowrap"
      >
        <span>Ir para conexões</span>
        <span>→</span>
      </router-link>
    </div>

    <!-- Compositor de Mensagens / Notas -->
    <CardComposer 
      v-if="card"
      :card="card" 
      :replying-to="replyingTo"
      @message-sent="onMessageSent" 
      @cancel-reply="cancelReply"
      @whatsapp-error="handleWhatsappError"
    />

    <!-- Modal de preview (quando clica na imagem) -->
    <div v-if="lightboxUrl" class="fixed inset-0 z-[100] bg-black/80 flex items-center justify-center cursor-pointer" @click="lightboxUrl = null">
      <img :src="lightboxUrl" class="max-w-[90vw] max-h-[90vh] rounded-lg shadow-2xl" />
      <button class="absolute top-4 right-4 text-white text-3xl font-bold select-none hover:text-gray-300" @click="lightboxUrl = null">✕</button>
    </div>
  </section>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted, watch, nextTick } from 'vue'
import { usePipelineStore } from '@/stores/pipeline'
import { useAuthStore } from '@/stores/auth'
import { usePipelineSocket } from '@/composables/usePipelineSocket'
import CardComposer from './CardComposer.vue'
import AudioPlayer from './AudioPlayer.vue'
import { X, CornerUpLeft, MessageSquare, Plus, MoveRight, HelpCircle, FileText } from 'lucide-vue-next'
import api from '@/plugins/axios'

const props = defineProps({
  cardId: {
    type: Number,
    required: true
  },
  pipelineId: {
    type: Number,
    required: true
  }
})

const pipelineStore = usePipelineStore()
const authStore = useAuthStore()
const socket = usePipelineSocket()

const rightActiveTab = ref('whatsapp') // 'whatsapp', 'notes', 'history'
const replyingTo = ref(null)
const isWhatsappUnavailableError = ref(false)
const lastErrorMessage = ref('')
const lightboxUrl = ref(null)
const timelineContainer = ref(null)

const card = computed(() => {
  return pipelineStore.cards.find(c => c.id === props.cardId)
})

const triggerReply = (msg) => {
  replyingTo.value = {
    id: msg.payload?.chatwoot_msg_id || msg.payload?.message_id || msg.chatwoot_message_id || msg.id,
    content: msg.content?.substring(0, 100),
    sender_name: msg.sender_name || msg.payload?.sender_name || (msg.message_type === 'outgoing' ? 'Você' : 'Cliente')
  }
}

const cancelReply = () => {
  replyingTo.value = null
}

const handleWhatsappError = (err) => {
  isWhatsappUnavailableError.value = true
  lastErrorMessage.value = err.message
}

const onMessageSent = () => {
  replyingTo.value = null
  isWhatsappUnavailableError.value = false
  lastErrorMessage.value = ''
  scrollToBottom()
}

const getSenderDisplayName = (event) => {
  const name = event.user?.name || event.sender_name
  if (!name) return 'Você'
  if (authStore.user?.name && name.toLowerCase() === authStore.user.name.toLowerCase()) {
    return 'Você'
  }
  return name
}

const getEventIcon = (type) => {
  switch (type) {
    case 'card_created': return Plus
    case 'card_moved': return MoveRight
    case 'card_updated': return FileText
    default: return HelpCircle
  }
}

const loadTimeline = async () => {
  if (props.pipelineId && props.cardId) {
    await pipelineStore.fetchCardTimeline(props.pipelineId, props.cardId)
    scrollToBottom()
  }
}

const onNewMessageReceived = () => {
  scrollToBottom()
}

let pollInterval = null

onMounted(() => {
  loadTimeline()
  
  if (props.pipelineId && props.cardId) {
    pipelineStore.fetchCardDetail(props.pipelineId, props.cardId)
    socket.connect(props.pipelineId, props.cardId)
  }

  window.addEventListener('zavy-new-message', onNewMessageReceived)

  pollInterval = setInterval(async () => {
    if (props.pipelineId && props.cardId) {
      try {
        const response = await api.get(`/api/v1/pipelines/${props.pipelineId}/cards/${props.cardId}/timeline`)
        const newItems = response.data.data || response.data
        
        const isChanged = newItems.length !== pipelineStore.cardTimeline.length ||
                          newItems.some((item, idx) => {
                            const oldItem = pipelineStore.cardTimeline[idx]
                            return !oldItem || 
                                   oldItem.id !== item.id || 
                                   oldItem.created_at !== item.created_at ||
                                   oldItem.event_type !== item.event_type ||
                                   JSON.stringify(oldItem.payload) !== JSON.stringify(item.payload)
                          })
        
        if (isChanged) {
          pipelineStore.cardTimeline = newItems
        }
      } catch (e) {
        console.error("Erro no polling de timeline:", e)
      }
    }
  }, 5000)
})

onUnmounted(() => {
  window.removeEventListener('zavy-new-message', onNewMessageReceived)
  socket.disconnect()
  if (pollInterval) {
    clearInterval(pollInterval)
  }
})

watch(() => props.cardId, (newCardId) => {
  if (newCardId) {
    isWhatsappUnavailableError.value = false
    lastErrorMessage.value = ''
    
    socket.disconnect()
    if (props.pipelineId) {
      socket.connect(props.pipelineId, newCardId)
    }
    
    loadTimeline()
    if (props.pipelineId) {
      pipelineStore.fetchCardDetail(props.pipelineId, newCardId)
    }
  }
})

const formatTimeOnly = (isoString) => {
  if (!isoString) return ''
  const date = new Date(isoString)
  const hours = date.getHours().toString().padStart(2, '0')
  const minutes = date.getMinutes().toString().padStart(2, '0')
  const seconds = date.getSeconds().toString().padStart(2, '0')
  return `${hours}:${minutes}:${seconds}`
}

const openLightbox = (url) => {
  lightboxUrl.value = url
}

const handleImageError = (e) => {
  console.error('Erro ao carregar imagem:', e.target.src)
}

const isVideo = (att) => {
  if (!att) return false
  const type = att.content_type || att.type || ''
  const filename = att.filename || ''
  return type.toLowerCase().startsWith('video') || 
         filename.toLowerCase().endsWith('.mp4') || 
         filename.toLowerCase().endsWith('.3gp') || 
         filename.toLowerCase().endsWith('.mov')
}

const shouldShowContent = (event) => {
  if (!event.content) return false
  if (event.attachments && event.attachments.length > 0) {
    return !event.attachments.some(att => att.filename === event.content)
  }
  return true
}

const isAudio = (att) => {
  if (!att) return false
  const type = att.content_type || att.type || ''
  const filename = att.filename || ''
  return type.toLowerCase().startsWith('audio') || 
         filename.toLowerCase().endsWith('.ogg') || 
         filename.toLowerCase().endsWith('.oga') || 
         filename.toLowerCase().endsWith('.mp3') || 
         filename.toLowerCase().endsWith('.webm') ||
         filename.toLowerCase().endsWith('.m4a') ||
         filename.toLowerCase().endsWith('.wav')
}

const isImage = (att) => {
  if (!att) return false
  const type = att.content_type || att.type || ''
  const filename = att.filename || ''
  return type.toLowerCase().startsWith('image') || 
         filename.toLowerCase().endsWith('.jpg') || 
         filename.toLowerCase().endsWith('.jpeg') || 
         filename.toLowerCase().endsWith('.png') || 
         filename.toLowerCase().endsWith('.webp') ||
         filename.toLowerCase().endsWith('.gif')
}

const getTranscription = (event) => {
  return event.transcription ||
         event.metadata?.transcription || 
         event.payload?.metadata?.transcription || 
         event.payload?.transcription || 
         null
}

const getQuotePreview = (inReplyToId) => {
  if (!inReplyToId) return '...'
  const original = pipelineStore.cardTimeline.find(item => {
    const itemId = item.id?.toString()
    const itemCwId = (item.payload?.chatwoot_msg_id || item.payload?.message_id || item.chatwoot_message_id || item.payload?.in_reply_to || item.in_reply_to)?.toString()
    return itemId === inReplyToId.toString() || itemCwId === inReplyToId.toString()
  })
  
  if (!original) return '...'
  
  const attachments = original.payload?.attachments || original.attachments || []
  if (attachments.some(isAudio)) return '🎙 Áudio'
  if (attachments.some(a => a.content_type?.startsWith('image/') || a.type?.startsWith('image'))) return '🖼️ Imagem'
  if (attachments.length > 0) {
    const att = attachments[0]
    return '📄 ' + (att.filename || 'Arquivo')
  }
  
  return original.payload?.content || original.content || '...'
}

const formatSize = (bytes) => {
  if (bytes === undefined || bytes === null || isNaN(bytes)) return '0 B'
  const k = 1024
  const sizes = ['B', 'KB', 'MB', 'GB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i]
}

const getFriendlyDateKey = (dateStr) => {
  const date = new Date(dateStr)
  const today = new Date()
  const yesterday = new Date()
  yesterday.setDate(today.getDate() - 1)
  
  if (date.toDateString() === today.toDateString()) {
    return 'Hoje'
  } else if (date.toDateString() === yesterday.toDateString()) {
    return 'Ontem'
  } else {
    return date.toLocaleDateString('pt-BR', { day: 'numeric', month: 'long' })
  }
}

const normalizedTimeline = computed(() => {
  const list = pipelineStore.cardTimeline.map(event => {
    const mergedMetadata = {
      ...(event.metadata || {}),
      ...(event.payload?.metadata || {})
    }

    if (event.event_type === 'chatwoot_message') {
      return {
        ...event,
        event_type: 'message',
        content: event.payload?.content || '',
        message_type: event.payload?.message_type || 'incoming',
        sender_name: event.payload?.sender_name || '',
        attachments: event.payload?.attachments || event.attachments || [],
        in_reply_to: event.payload?.in_reply_to || event.in_reply_to || null,
        metadata: Object.keys(mergedMetadata).length > 0 ? mergedMetadata : null
      }
    }
    if (event.event_type === 'message_sent') {
      return {
        ...event,
        event_type: 'message',
        content: event.payload?.content || '',
        message_type: event.payload?.private_note ? 'private' : 'outgoing',
        sender_name: 'Você',
        attachments: event.payload?.attachments || event.attachments || [],
        in_reply_to: event.payload?.in_reply_to || event.in_reply_to || null,
        metadata: Object.keys(mergedMetadata).length > 0 ? mergedMetadata : null
      }
    }
    if (event.event_type === 'message') {
      return {
        ...event,
        attachments: event.payload?.attachments || event.attachments || [],
        in_reply_to: event.payload?.in_reply_to || event.in_reply_to || null,
        metadata: Object.keys(mergedMetadata).length > 0 ? mergedMetadata : null
      }
    }
    return event
  })
  
  list.sort((a, b) => new Date(a.created_at) - new Date(b.created_at))
  
  const uniqList = []
  list.forEach(item => {
    const isDuplicate = uniqList.some(existing => {
      if (existing.id && item.id && existing.id === item.id) return true
      
      const isMsg1 = existing.event_type === 'message'
      const isMsg2 = item.event_type === 'message'
      
      if (isMsg1 && isMsg2) {
        const cwId1 = existing.payload?.chatwoot_msg_id || existing.payload?.message_id || existing.chatwoot_message_id
        const cwId2 = item.payload?.chatwoot_msg_id || item.payload?.message_id || item.chatwoot_message_id
        
        if (cwId1 && cwId2 && cwId1.toString() === cwId2.toString()) return true
        
        if (existing.content && existing.content.trim() !== '' &&
            existing.content.trim() === item.content.trim() &&
            existing.message_type === item.message_type) {
          const diff = Math.abs(new Date(existing.created_at) - new Date(item.created_at))
          if (diff < 60000) return true
        }
      }
      return false
    })
    
    if (!isDuplicate) {
      uniqList.push(item)
    } else {
      const idx = uniqList.findIndex(existing => {
        const cwId1 = existing.payload?.chatwoot_msg_id || existing.payload?.message_id || existing.chatwoot_message_id
        const cwId2 = item.payload?.chatwoot_msg_id || item.payload?.message_id || item.chatwoot_message_id
        return cwId1 && cwId2 && cwId1.toString() === cwId2.toString()
      })
      if (idx !== -1) {
        uniqList[idx] = { ...uniqList[idx], ...item }
      }
    }
  })
  
  return uniqList
})

const filteredTimelineEvents = computed(() => {
  if (rightActiveTab.value === 'whatsapp') {
    return normalizedTimeline.value.filter(e => e.event_type === 'message' && e.message_type !== 'private')
  } else if (rightActiveTab.value === 'notes') {
    return normalizedTimeline.value.filter(e => e.event_type === 'message' && e.message_type === 'private')
  } else {
    return normalizedTimeline.value.filter(e => e.event_type !== 'message')
  }
})

const groupedTimeline = computed(() => {
  const groupsMap = {}
  filteredTimelineEvents.value.forEach(event => {
    const dateKey = getFriendlyDateKey(event.created_at)
    if (!groupsMap[dateKey]) {
      groupsMap[dateKey] = []
    }
    groupsMap[dateKey].push(event)
  })
  
  return Object.keys(groupsMap).map(date => ({
    date,
    events: groupsMap[date]
  }))
})

const scrollToBottom = () => {
  nextTick(() => {
    if (timelineContainer.value) {
      timelineContainer.value.scrollTop = timelineContainer.value.scrollHeight
    }
  })
}

watch(() => pipelineStore.cardTimeline.length, (newVal, oldVal) => {
  if (newVal > oldVal) {
    scrollToBottom()
  }
})
</script>
