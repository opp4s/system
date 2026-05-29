<template>
  <div class="max-w-4xl mx-auto space-y-6 px-4 sm:px-6 lg:px-8 py-6">
    <!-- Header -->
    <header class="pb-5 border-b border-gray-200">
      <h1 class="text-2xl font-extrabold text-gray-900 tracking-tight flex items-center space-x-2">
        <component :is="MessageSquare" class="h-6 w-6 text-zavy-600" />
        <span>Conexão do WhatsApp</span>
      </h1>
      <p class="text-sm text-gray-500 mt-1">
        Conecte seu WhatsApp instantaneamente via QR Code para enviar mensagens e campanhas em massa.
      </p>
    </header>

    <!-- Conteúdo Principal -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
      
      <!-- Painel Principal de Conexão -->
      <section class="md:col-span-2 space-y-6">
        <div class="bg-white border border-gray-200 rounded-3xl p-6 shadow-sm space-y-6 relative overflow-hidden">
          
          <!-- Badge de Status -->
          <div class="flex items-center justify-between pb-3 border-b border-gray-150">
            <h3 class="text-sm font-bold text-gray-800 uppercase tracking-wider">Status do Dispositivo</h3>
            <span 
              class="text-xs px-2.5 py-0.5 rounded-full font-bold flex items-center space-x-1"
              :class="isConnected ? 'bg-emerald-50 text-emerald-700' : isGenerating || isScanning ? 'bg-amber-50 text-amber-700' : 'bg-gray-100 text-gray-600'"
            >
              <span class="w-1.5 h-1.5 rounded-full" :class="isConnected ? 'bg-emerald-500 animate-ping' : isScanning ? 'bg-amber-500 animate-pulse' : 'bg-gray-400'"></span>
              <span>{{ isConnected ? 'Conectado' : isScanning ? 'Aguardando Leitura' : 'Desconectado' }}</span>
            </span>
          </div>

          <!-- FLUXO 1: Formulário Inicial (Inserção do Número) -->
          <div v-if="currentStep === 'input'" class="space-y-4 py-4">
            <div class="space-y-2">
              <label class="text-xs font-bold text-gray-700 uppercase tracking-wider block">Número do WhatsApp (com DDI e DDD)</label>
              <div class="relative rounded-xl shadow-sm">
                <input
                  type="text"
                  v-model="phoneNumber"
                  @input="formatPhoneNumber"
                  placeholder="+55 (11) 99999-9999"
                  class="block w-full px-4 py-3 rounded-xl border border-gray-250 focus:outline-none focus:border-zavy-500 focus:ring-1 focus:ring-zavy-500 bg-gray-50/20 text-sm text-gray-800 transition-all"
                />
              </div>
              <p class="text-xs text-gray-400">Insira o número do celular associado ao WhatsApp que deseja conectar.</p>
            </div>

            <!-- Método de Pareamento -->
            <div class="space-y-2">
              <label class="text-xs font-bold text-gray-700 uppercase tracking-wider block">Método de Conexão</label>
              <div class="flex space-x-2 bg-gray-100 p-1 rounded-xl w-fit">
                <button
                  type="button"
                  @click="connectionMethod = 'qr'"
                  class="px-4 py-2 text-xs font-bold rounded-lg transition-all"
                  :class="connectionMethod === 'qr' ? 'bg-white text-slate-900 shadow-sm' : 'text-gray-500 hover:text-gray-700'"
                >
                  QR Code
                </button>
                <button
                  type="button"
                  @click="connectionMethod = 'pairing'"
                  class="px-4 py-2 text-xs font-bold rounded-lg transition-all"
                  :class="connectionMethod === 'pairing' ? 'bg-white text-slate-900 shadow-sm' : 'text-gray-500 hover:text-gray-700'"
                >
                  Código de Pareamento
                </button>
              </div>
            </div>

            <div class="pt-4 flex justify-end">
              <button
                @click="generateQRCode"
                :disabled="!isValidPhone || isGenerating"
                class="flex items-center space-x-2 px-6 py-3 bg-slate-900 hover:bg-slate-800 disabled:bg-slate-350 text-white rounded-xl text-sm font-bold shadow-md shadow-slate-900/10 hover:shadow-lg transition-all duration-150"
              >
                <component v-if="isGenerating" :is="Loader2" class="h-4 w-4 animate-spin" />
                <span>{{ isGenerating ? 'Gerando Conexão...' : 'Conectar WhatsApp' }}</span>
              </button>
            </div>
          </div>

          <!-- FLUXO 2: Exibição do QR Code ou Código e Leitura -->
          <div v-if="currentStep === 'scan'" class="flex flex-col items-center justify-center space-y-6 py-6 animate-scale-up">
            <div class="text-center space-y-2">
              <h4 class="text-sm font-bold text-slate-800">
                {{ connectionMethod === 'qr' ? 'Escaneie o QR Code abaixo no seu WhatsApp' : 'Insira o código de pareamento no seu WhatsApp' }}
              </h4>
              <p class="text-xs text-gray-500 max-w-sm mx-auto">
                {{ connectionMethod === 'qr' 
                  ? 'Abra o WhatsApp no seu celular, vá em Dispositivos Conectados > Conectar um dispositivo e aponte a câmera.' 
                  : 'Abra o WhatsApp no seu celular, vá em Dispositivos Conectados > Conectar um dispositivo > Conectar com número de telefone e insira o código.' 
                }}
              </p>
            </div>

            <!-- Área de Conexão (QR Code ou Código de Pareamento) -->
            <div class="relative p-4 bg-white border border-gray-200 rounded-3xl shadow-md flex items-center justify-center w-64 h-64">
              <template v-if="connectionMethod === 'qr'">
                <img 
                  v-if="qrCodeUrl" 
                  :src="qrCodeUrl" 
                  alt="WhatsApp QR Code" 
                  class="w-full h-full rounded-2xl transition-opacity duration-300"
                  :class="isExpired ? 'opacity-20 blur-sm' : 'opacity-100'"
                />
              </template>
              <template v-else>
                <div v-if="pairingCode" class="flex flex-col items-center justify-center space-y-4 px-2 text-center select-all">
                  <span class="text-xs font-bold text-gray-400 uppercase tracking-wider">Código de Conexão</span>
                  <span class="text-3xl font-extrabold tracking-widest text-slate-900 bg-slate-50 border border-slate-200 px-5 py-3.5 rounded-2xl font-mono">
                    {{ pairingCode }}
                  </span>
                  <span class="text-[10px] text-gray-400">Clique para copiar</span>
                </div>
              </template>
              
              <!-- Loader de Polling/Conexão -->
              <div v-if="isExpired" class="absolute inset-0 flex flex-col items-center justify-center p-6 text-center bg-white/80 rounded-3xl">
                <p class="text-xs font-bold text-rose-600 mb-2">Conexão expirada</p>
                <button 
                  @click="generateQRCode" 
                  class="flex items-center space-x-2 px-4 py-2 bg-slate-900 hover:bg-slate-800 text-white text-xs font-bold rounded-xl shadow-md transition-all"
                >
                  <component :is="RefreshCw" class="h-3.5 w-3.5" />
                  <span>Gerar novo código</span>
                </button>
              </div>
            </div>

            <!-- Timer e Status da Leitura -->
            <div class="flex flex-col items-center space-y-2 text-center w-full">
              <div class="flex items-center space-x-2 text-xs font-semibold text-gray-500">
                <component :is="Loader2" class="h-3.5 w-3.5 animate-spin text-zavy-600" />
                <span>Aguardando conexão pelo celular...</span>
              </div>
              <p class="text-xs text-gray-400">
                Expira em: <span class="font-bold text-slate-700">{{ countdown }}s</span>
              </p>
            </div>

            <!-- Botão Voltar -->
            <div class="pt-4 w-full flex justify-between border-t border-gray-100">
              <button 
                @click="cancelScan" 
                class="px-4 py-2 text-xs font-bold text-gray-500 hover:text-gray-700 hover:bg-gray-50 rounded-xl transition-all"
              >
                Voltar
              </button>
            </div>
          </div>

          <!-- FLUXO 3: WhatsApp Conectado com Sucesso -->
          <div v-if="currentStep === 'success'" class="flex flex-col items-center justify-center space-y-6 py-10 text-center animate-scale-up">
            <div class="w-16 h-16 bg-emerald-50 text-emerald-500 rounded-full flex items-center justify-center border border-emerald-100 shadow-sm">
              <component :is="CheckCircle" class="w-8 h-8" />
            </div>
            <div class="space-y-2">
              <h3 class="text-lg font-bold text-slate-850">WhatsApp Conectado com Sucesso!</h3>
              <p class="text-xs text-gray-550 max-w-sm">
                Seu dispositivo com o número <strong class="text-slate-800">{{ phoneNumber }}</strong> foi integrado ao Zavy CRM. Suas mensagens e campanhas estão prontas para disparar.
              </p>
            </div>

            <div class="pt-4 flex space-x-3">
              <button 
                @click="goToDashboard" 
                class="px-6 py-2.5 bg-slate-900 hover:bg-slate-800 text-white rounded-xl text-xs font-bold shadow-md shadow-slate-900/10 hover:shadow-lg transition-all"
              >
                Ir para o Dashboard
              </button>
              <button 
                @click="disconnectDevice" 
                class="px-6 py-2.5 border border-rose-250 hover:bg-rose-50 text-rose-650 rounded-xl text-xs font-bold transition-all"
              >
                Desconectar
              </button>
            </div>
          </div>

        </div>

        <!-- Seção: Distribuição Automática de Leads (Apenas se Conectado) -->
        <div 
          v-if="isConnected" 
          class="bg-white border border-gray-200 rounded-3xl p-6 shadow-sm space-y-5 animate-scale-up"
        >
          <header class="flex items-center space-x-2 pb-3 border-b border-gray-150 text-slate-850">
            <component :is="Zap" class="h-5 w-5 text-zavy-500" />
            <h3 class="text-sm font-bold text-gray-800 uppercase tracking-wider">Distribuição Automática de Leads</h3>
          </header>

          <div class="space-y-4">
            <div class="flex items-center justify-between">
              <div>
                <h4 class="text-xs font-bold text-gray-700">Encaminhar Novas Conversas</h4>
                <p class="text-[10px] text-gray-400 mt-0.5">Criar oportunidades automaticamente para novas conversas do WhatsApp.</p>
              </div>
              <button
                @click="autoLinkSettings.autoLinkEnabled = !autoLinkSettings.autoLinkEnabled"
                class="relative inline-flex h-6 w-11 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none focus:ring-2 focus:ring-slate-900 focus:ring-offset-2"
                :class="autoLinkSettings.autoLinkEnabled ? 'bg-slate-900' : 'bg-gray-200'"
              >
                <span
                  class="pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out"
                  :class="autoLinkSettings.autoLinkEnabled ? 'translate-x-5' : 'translate-x-0'"
                ></span>
              </button>
            </div>

            <transition
              enter-active-class="transition duration-200 ease-out"
              enter-from-class="transform -translate-y-2 opacity-0"
              enter-to-class="transform translate-y-0 opacity-100"
              leave-active-class="transition duration-150 ease-in"
              leave-from-class="transform translate-y-0 opacity-100"
              leave-to-class="transform -translate-y-2 opacity-0"
            >
              <div v-if="autoLinkSettings.autoLinkEnabled" class="grid grid-cols-1 sm:grid-cols-2 gap-4 pt-2">
                <div class="space-y-1.5">
                  <label class="text-[10px] font-bold text-gray-400 uppercase tracking-wider block">Funil (Pipeline) de Destino</label>
                  <select
                    v-model="autoLinkSettings.destinationPipelineId"
                    @change="onPipelineChange"
                    class="block w-full px-3 py-2 rounded-xl border border-gray-250 focus:outline-none focus:border-zavy-500 focus:ring-1 focus:ring-zavy-500 bg-gray-50/30 text-xs text-gray-800 transition-all"
                  >
                    <option :value="null" disabled>Selecione um funil...</option>
                    <option v-for="pipeline in pipelineStore.pipelines" :key="pipeline.id" :value="pipeline.id">
                      {{ pipeline.name }}
                    </option>
                  </select>
                </div>

                <div class="space-y-1.5">
                  <label class="text-[10px] font-bold text-gray-400 uppercase tracking-wider block">Etapa do Funil</label>
                  <select
                    v-model="autoLinkSettings.destinationStageId"
                    :disabled="!autoLinkSettings.destinationPipelineId"
                    class="block w-full px-3 py-2 rounded-xl border border-gray-250 focus:outline-none focus:border-zavy-500 focus:ring-1 focus:ring-zavy-500 bg-gray-50/30 text-xs text-gray-800 transition-all disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    <option :value="null" disabled>Selecione uma etapa...</option>
                    <option v-for="stage in availableStages" :key="stage.id" :value="stage.id">
                      {{ stage.name }}
                    </option>
                  </select>
                </div>
              </div>
            </transition>

            <div class="flex justify-end pt-3 border-t border-gray-100">
              <button
                @click="saveRoutingSettings"
                :disabled="chatwootStore.loading || (autoLinkSettings.autoLinkEnabled && (!autoLinkSettings.destinationPipelineId || !autoLinkSettings.destinationStageId))"
                class="flex items-center space-x-1.5 px-4 py-2 bg-slate-900 hover:bg-slate-800 disabled:bg-slate-350 text-white font-bold rounded-xl text-xs shadow-md shadow-slate-900/10 transition-all"
              >
                <component :is="Check" class="h-3.5 w-3.5" />
                <span>Salvar Configurações</span>
              </button>
            </div>
          </div>
        </div>



      </section>

      <!-- Painel Informativo Lateral -->
      <section class="space-y-6">
        <div class="bg-slate-50 border border-gray-200 rounded-3xl p-5 shadow-sm space-y-4">
          <h4 class="text-xs font-extrabold text-slate-850 uppercase tracking-wider flex items-center space-x-1.5">
            <component :is="Info" class="h-4 w-4 text-zavy-500 shrink-0" />
            <span>Instruções Rápidas</span>
          </h4>
          
          <ul class="text-xs text-gray-650 space-y-3 list-decimal pl-4 leading-relaxed font-medium">
            <li>
              Digite o número do seu WhatsApp corporativo com o código do país (DDI) e o DDD.
            </li>
            <li>
              Clique em <strong>Gerar QR Code</strong> e aguarde o carregamento da imagem.
            </li>
            <li>
              No WhatsApp do seu celular, toque em <strong>Dispositivos conectados</strong> e leia o QR Code.
            </li>
            <li>
              O sistema detectará a conexão e ativará o status automaticamente em segundos.
            </li>
          </ul>
        </div>
      </section>

    </div>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { useChatwootStore } from '@/stores/chatwoot'
import { usePipelineStore } from '@/stores/pipeline'
import { useToast } from '@/composables/useToast'
import api from '@/plugins/axios'
import { 
  MessageSquare, 
  Loader2, 
  CheckCircle,
  Zap,
  Info,
  Check,
  RefreshCw
} from 'lucide-vue-next'

const chatwootStore = useChatwootStore()
const pipelineStore = usePipelineStore()
const toast = useToast()
const router = useRouter()

// Estados de controle do fluxo
const currentStep = ref('input') // input, scan, success
const phoneNumber = ref('')
const isGenerating = ref(false)
const qrCodeUrl = ref('')
const pairingCode = ref('')
const connectionMethod = ref('qr') // qr, pairing
const countdown = ref(45)
const isExpired = ref(false)
const isScanning = ref(false)

let countdownTimer = null
let pollingTimer = null

// Configurações de Roteamento Automático
const autoLinkSettings = reactive({
  autoLinkEnabled: chatwootStore.autoLinkEnabled,
  destinationPipelineId: chatwootStore.destinationPipelineId,
  destinationStageId: chatwootStore.destinationStageId
})

const availableStages = ref([])

const isConnected = computed(() => {
  return chatwootStore.configured
})

const isValidPhone = computed(() => {
  const clean = phoneNumber.value.replace(/\D/g, '')
  return clean.length >= 10
})

onMounted(async () => {
  await chatwootStore.fetchSettings()
  await pipelineStore.fetchPipelines()
  
  autoLinkSettings.autoLinkEnabled = chatwootStore.autoLinkEnabled
  autoLinkSettings.destinationPipelineId = chatwootStore.destinationPipelineId
  autoLinkSettings.destinationStageId = chatwootStore.destinationStageId
  
  try {
    const response = await api.get('/api/v1/whatsapp/status')
    const data = response.data?.data
    if (data && data.connected) {
      chatwootStore.configured = true
      currentStep.value = 'success'
      if (data.phone) {
        phoneNumber.value = data.phone
        formatPhoneNumber()
      }
      if (autoLinkSettings.destinationPipelineId) {
        await loadStagesForPipeline(autoLinkSettings.destinationPipelineId)
      }
    } else {
      chatwootStore.configured = false
      currentStep.value = 'input'
    }
  } catch (error) {
    console.error('Erro ao verificar status do WhatsApp:', error)
    currentStep.value = 'input'
  }
})

onUnmounted(() => {
  clearTimers()
})

const clearTimers = () => {
  if (countdownTimer) clearInterval(countdownTimer)
  if (pollingTimer) clearInterval(pollingTimer)
}

// Formatar entrada de telefone
const formatPhoneNumber = () => {
  let clean = phoneNumber.value.replace(/\D/g, '')
  if (!clean) {
    phoneNumber.value = ''
    return
  }
  // Garante DDI 55 se começar sem +
  if (!phoneNumber.value.startsWith('+') && clean.substring(0, 2) !== '55') {
    clean = '55' + clean
  }
  
  // Aplica máscara simples
  if (clean.length <= 2) {
    phoneNumber.value = '+' + clean
  } else if (clean.length <= 4) {
    phoneNumber.value = `+${clean.substring(0, 2)} (${clean.substring(2)}`
  } else if (clean.length <= 8) {
    phoneNumber.value = `+${clean.substring(0, 2)} (${clean.substring(2, 4)}) ${clean.substring(4)}`
  } else if (clean.length <= 12) {
    phoneNumber.value = `+${clean.substring(0, 2)} (${clean.substring(2, 4)}) ${clean.substring(4, 8)}-${clean.substring(8)}`
  } else {
    phoneNumber.value = `+${clean.substring(0, 2)} (${clean.substring(2, 4)}) ${clean.substring(4, 9)}-${clean.substring(9, 13)}`
  }
}

const generateQRCode = async () => {
  if (!isValidPhone.value) return
  
  isGenerating.value = true
  isExpired.value = false
  clearTimers()
  pairingCode.value = ''
  qrCodeUrl.value = ''
  
  const cleanPhone = phoneNumber.value.replace(/\D/g, '')
  
  try {
    // Chamada real ao backend para conectar
    const response = await api.post('/api/v1/whatsapp/connect', { 
      phone_number: '+' + cleanPhone,
      method: connectionMethod.value
    })
    
    const data = response.data?.data
    if (!data) {
      throw new Error('Resposta inválida do servidor')
    }

    if (connectionMethod.value === 'qr') {
      let qr = data.qr_code_base64
      if (qr) {
        if (!qr.startsWith('data:')) {
          qr = `data:image/png;base64,${qr}`
        }
        qrCodeUrl.value = qr
      } else {
        throw new Error('Nenhum QR Code retornado pela API.')
      }
    } else {
      if (data.pairing_code) {
        pairingCode.value = data.pairing_code
      } else {
        throw new Error('Nenhum código de pareamento retornado pela API.')
      }
    }

    isGenerating.value = false
    currentStep.value = 'scan'
    isScanning.value = true
    
    // Iniciar temporizador
    countdown.value = 45
    countdownTimer = setInterval(() => {
      if (countdown.value > 0) {
        countdown.value--
      } else {
        isExpired.value = true
        isScanning.value = false
        clearTimers()
      }
    }, 1000)

    // Iniciar polling
    startStatusPolling(cleanPhone)
  } catch (error) {
    console.error('Erro ao conectar WhatsApp:', error)
    const errorMsg = error.response?.data?.error || error.message || 'Erro de conexão'
    toast.error(`Falha ao conectar: ${errorMsg}`)
    isGenerating.value = false
    currentStep.value = 'input'
    isScanning.value = false
    clearTimers()
  }
}

const startStatusPolling = (phone) => {
  pollingTimer = setInterval(async () => {
    try {
      const response = await api.get('/api/v1/whatsapp/status')
      const connected = response.data?.data?.connected
      if (connected) {
        onConnectionSuccess()
      }
    } catch (error) {
      console.warn('Erro ao checar status do WhatsApp:', error)
    }
  }, 3000)
}

const onConnectionSuccess = async () => {
  clearTimers()
  isScanning.value = false
  currentStep.value = 'success'
  
  // Atualiza as configurações no store buscando do backend
  await chatwootStore.fetchSettings()
  chatwootStore.configured = true

  toast.success('WhatsApp conectado com sucesso!')
}

const cancelScan = () => {
  clearTimers()
  isScanning.value = false
  currentStep.value = 'input'
}

const disconnectDevice = async () => {
  if (!confirm('Deseja realmente desconectar este dispositivo do WhatsApp?')) return
  
  clearTimers()
  try {
    await api.post('/api/v1/whatsapp/disconnect')
  } catch (error) {
    console.error('Erro ao desconectar WhatsApp no backend:', error)
  }

  chatwootStore.configured = false
  chatwootStore.disconnectChatwoot()
  
  currentStep.value = 'input'
  phoneNumber.value = ''
  toast.warning('WhatsApp desconectado do workspace.')
}

const goToDashboard = () => {
  router.push('/dashboard')
}

// Lógica de distribuição
const onPipelineChange = async () => {
  autoLinkSettings.destinationStageId = null
  if (autoLinkSettings.destinationPipelineId) {
    await loadStagesForPipeline(autoLinkSettings.destinationPipelineId)
  } else {
    availableStages.value = []
  }
}

const loadStagesForPipeline = async (pipelineId) => {
  await pipelineStore.fetchStages(pipelineId)
  availableStages.value = pipelineStore.stages
}

const saveRoutingSettings = async () => {
  try {
    await chatwootStore.updateSettings({
      autoLinkEnabled: autoLinkSettings.autoLinkEnabled,
      destinationPipelineId: autoLinkSettings.destinationPipelineId,
      destinationStageId: autoLinkSettings.destinationStageId
    })
    toast.success('Configurações de roteamento salvas com sucesso!')
  } catch (e) {
    toast.error('Erro ao salvar as configurações de roteamento.')
  }
}
</script>

<style scoped>
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
  animation: scaleUp 0.2s cubic-bezier(0.16, 1, 0.3, 1) forwards;
}
</style>
