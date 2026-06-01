import { ref, onUnmounted } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { usePipelineStore } from '@/stores/pipeline'

export function usePipelineSocket() {
  const socket = ref(null)
  const isConnected = ref(false)
  const reconnectTimeout = ref(null)
  let activePipelineId = null
  let activeCardId = null

  const authStore = useAuthStore()
  const pipelineStore = usePipelineStore()

  // Conecta ao ActionCable via WebSocket nativo
  const connect = (pipelineId, cardId = null) => {
    activePipelineId = pipelineId
    activeCardId = cardId

    const token = authStore.user?.pubsub_token
    if (!token) {
      console.warn('pubsub_token não disponível. Conexão em tempo real ActionCable abortada.')
      return
    }

    // Fecha conexão existente
    disconnect()

    // TODO: replace host or protocol for production/development environment if needed
    const wsUrl = `wss://api.zavycrm.com/cable?token=${token}`
    
    try {
      socket.value = new WebSocket(wsUrl)

      socket.value.onopen = () => {
        isConnected.value = true
        console.log('ActionCable WebSocket conectado com sucesso!')
        
        // Se inscreve no PipelineChannel
        subscribe(pipelineId)
      };

      socket.value.onmessage = (event) => {
        const data = JSON.parse(event.data)
        
        // Ignora pings periódicos do ActionCable
        if (data.type === 'ping') return

        // Verifica se a mensagem veio do canal correto
        if (data.message && data.identifier) {
          const identifier = JSON.parse(data.identifier)
          
          if (identifier.channel === 'PipelineChannel') {
            handleChannelMessage(data.message)
          }
        }
      };

      socket.value.onclose = (event) => {
        isConnected.value = false
        console.log('ActionCable WebSocket desconectado. Código:', event.code)
        
        // Tenta reconectar se a conexão não foi fechada de forma intencional
        if (event.code !== 1000) {
          attemptReconnect(pipelineId, cardId)
        }
      };

      socket.value.onerror = (error) => {
        console.error('Erro na conexão ActionCable WebSocket:', error)
      };

    } catch (e) {
      console.error('Falha ao instanciar ActionCable WebSocket:', e)
    }
  }

  const disconnect = () => {
    if (reconnectTimeout.value) {
      clearTimeout(reconnectTimeout.value)
      reconnectTimeout.value = null
    }

    if (socket.value) {
      // Código 1000 indica encerramento intencional e limpo
      socket.value.close(1000)
      socket.value = null
    }
    isConnected.value = false
  }

  const subscribe = (pipelineId) => {
    if (!socket.value || socket.value.readyState !== WebSocket.OPEN) return

    const subscribeMsg = {
      command: 'subscribe',
      identifier: JSON.stringify({
        channel: 'PipelineChannel',
        pipeline_id: pipelineId
      })
    }

    socket.value.send(JSON.stringify(subscribeMsg))
    console.log(`Subscrição enviada para o PipelineChannel (pipeline_id: ${pipelineId})`)
  }

  // Tenta reconectar a cada 5 segundos em caso de queda de rede
  const attemptReconnect = (pipelineId, cardId) => {
    if (reconnectTimeout.value) return
    
    console.log('Tentando reconectar ActionCable em 5 segundos...')
    reconnectTimeout.value = setTimeout(() => {
      reconnectTimeout.value = null
      connect(pipelineId, cardId)
    }, 5000)
  }

  // Processa as mensagens recebidas do ActionCable
  const handleChannelMessage = (message) => {
    console.log('Mensagem ActionCable recebida:', message)

    const cardIdFromMessage = message.card_id
    if (activeCardId && cardIdFromMessage === Number(activeCardId)) {
      const eventData = message.event_data || message.data || message
      
      const timelineEvents = [
        'message_sent',
        'chatwoot_message_received',
        'chatwoot_status_changed',
        'conversation_linked',
        'conversation_unlinked',
        'timeline_update'
      ]
      
      if (timelineEvents.includes(message.event) || (eventData.event_type && eventData.id)) {
        const exists = pipelineStore.cardTimeline.some(item => item.id === eventData.id)
        if (!exists) {
          // Normaliza tipo de mensagem se necessário
          if (eventData.event_type === 'message' && eventData.message_type) {
            eventData.message_type = eventData.message_type === 'lost' ? 'lose' : (eventData.message_type === 'won' ? 'win' : eventData.message_type)
          }
          pipelineStore.cardTimeline.push(eventData)
          
          // Emite um evento customizado no DOM para que o CardDetail role para baixo
          const customEvent = new CustomEvent('zavy-new-message', { detail: eventData })
          window.dispatchEvent(customEvent)
        }
      }
    }   // Se o evento indicar que um card mudou de etapa, podemos atualizar os cards do board em tempo real
    if (message.event === 'card_moved') {
      const eventData = message.event_data || message.data || message
      const card = eventData
      const index = pipelineStore.cards.findIndex(c => c.id === card.id)
      if (index !== -1) {
        pipelineStore.cards[index] = { ...pipelineStore.cards[index], ...card }
      } else {
        pipelineStore.cards.push(card)
      }
    }
  }

  onUnmounted(() => {
    disconnect()
  })

  return {
    connect,
    disconnect,
    isConnected
  }
}
