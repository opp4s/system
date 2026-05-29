<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import api from '@/plugins/axios'
import { Loader2, X, Check, RefreshCw } from 'lucide-vue-next'
import { useToast } from '@/composables/useToast'

const props = defineProps({
  reconnectInstance: { type: Object, default: null },
})

const emit = defineEmits(['close', 'connected'])
const toast = useToast()

const step = ref('platform') // platform, qr, success
const platform = ref(null)
const instanceId = ref(null)
const qrCode = ref(null)
const expiresAt = ref(null)
const loadingQr = ref(false)
const apiError = ref('')

let pollTimer = null
let refreshTimer = null
let abortController = null

const stepIndex = computed(() => {
  const map = { platform: 0, qr: 1, success: 2 }
  return map[step.value] ?? 0
})

function selectPlatform(p) {
  platform.value = p
  requestConnection()
}

function scheduleQrRefresh(expiresAtIso) {
  clearTimeout(refreshTimer)
  const expiryDate = expiresAtIso ? new Date(expiresAtIso) : new Date(Date.now() + 45000)
  const msUntilExpiry = expiryDate.getTime() - Date.now() - 5000
  if (msUntilExpiry > 0) {
    refreshTimer = setTimeout(async () => {
      await refreshQr()
    }, msUntilExpiry)
  }
}

function startPolling() {
  clearInterval(pollTimer)
  pollTimer = setInterval(async () => {
    try {
      const res = await api.get('/api/v1/whatsapp/status')
      const list = res.data?.data?.instances || []
      const currentInst = list.find(i => i.instance_id === instanceId.value)
      if (currentInst && currentInst.status === 'connected') {
        clearInterval(pollTimer)
        clearTimeout(refreshTimer)
        step.value = 'success'
        setTimeout(() => emit('connected', { instanceId: instanceId.value }), 1500)
      }
    } catch {
      // silently retry
    }
  }, 3000)
}

async function requestConnection() {
  abortController = new AbortController()
  loadingQr.value = true
  apiError.value = ''
  qrCode.value = null

  try {
    const res = await api.post(
      '/api/v1/whatsapp/connect',
      {
        method: 'qr',
      },
      { signal: abortController.signal }
    )

    const data = res.data?.data
    if (!data) {
      throw new Error('Resposta inválida do servidor')
    }

    instanceId.value = data.instance_id
    let qr = data.qr_code_base64
    if (qr && !qr.startsWith('data:')) {
      qr = `data:image/png;base64,${qr}`
    }
    qrCode.value = qr
    expiresAt.value = data.expires_at

    step.value = 'qr'
    scheduleQrRefresh(expiresAt.value)
    startPolling()
  } catch (e) {
    if (e.name === 'CanceledError' || e.name === 'AbortError') return
    const msg = e.response?.data?.error || e.message
    apiError.value = msg || 'Erro ao criar conexão. Tente novamente.'
    toast.error(apiError.value)
  } finally {
    loadingQr.value = false
  }
}

async function refreshQr() {
  loadingQr.value = true
  apiError.value = ''
  try {
    const res = await api.post('/api/v1/whatsapp/connect', {
      method: 'qr',
    })
    const data = res.data?.data
    if (data) {
      let qr = data.qr_code_base64
      if (qr && !qr.startsWith('data:')) {
        qr = `data:image/png;base64,${qr}`
      }
      qrCode.value = qr
      expiresAt.value = data.expires_at
      scheduleQrRefresh(expiresAt.value)
    }
  } catch {
    apiError.value = 'Não foi possível atualizar o QR Code.'
  } finally {
    loadingQr.value = false
  }
}

function close() {
  abortController?.abort()
  clearInterval(pollTimer)
  clearTimeout(refreshTimer)
  emit('close')
}

onMounted(() => {
  if (props.reconnectInstance) {
    instanceId.value = props.reconnectInstance.instance_id
    platform.value = 'android'
    step.value = 'qr'
    requestConnection()
  }
})

onUnmounted(() => {
  clearInterval(pollTimer)
  clearTimeout(refreshTimer)
})
</script>

<template>
  <div class="fixed inset-0 z-50 flex items-center justify-center p-4">
    <!-- Backdrop -->
    <div class="absolute inset-0 bg-slate-900/60 backdrop-blur-sm" @click="close" />

    <!-- Modal -->
    <div class="relative bg-white border border-gray-150 rounded-3xl shadow-2xl w-full max-w-xl overflow-hidden animate-scale-up">

      <!-- Header -->
      <div class="flex items-center justify-between px-6 py-4 border-b border-gray-100 bg-gray-50/50">
        <div class="flex items-center gap-3">
          <div class="w-8 h-8 rounded-xl bg-emerald-50 border border-emerald-100 flex items-center justify-center">
            <svg viewBox="0 0 24 24" class="w-5 h-5 fill-emerald-500">
              <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347z"/>
              <path d="M12 0C5.373 0 0 5.373 0 12c0 2.124.554 4.118 1.524 5.845L.057 23.07a.75.75 0 00.932.932l5.226-1.467A11.944 11.944 0 0012 24c6.627 0 12-5.373 12-12S18.627 0 12 0zm0 22c-1.89 0-3.663-.497-5.193-1.367l-.372-.214-3.852 1.081 1.081-3.852-.214-.372A9.944 9.944 0 012 12C2 6.477 6.477 2 12 2s10 4.477 10 10-4.477 10-10 10z"/>
            </svg>
          </div>
          <span class="text-sm font-bold text-gray-800">{{ reconnectInstance ? 'Reconectar WhatsApp' : 'Conectar WhatsApp' }}</span>
        </div>
        <button class="text-gray-400 hover:text-gray-600 hover:bg-gray-100 p-1.5 rounded-xl transition-all duration-150" @click="close">
          <X class="h-5 w-5" />
        </button>
      </div>

      <!-- Step indicator -->
      <div class="flex items-center justify-between px-6 pt-4 pb-2 border-b border-gray-50 bg-gray-50/20">
        <template v-for="(label, i) in ['Plataforma', 'Conectar', 'Pronto']" :key="i">
          <div class="flex items-center gap-1.5">
            <div
              class="w-6 h-6 rounded-full flex items-center justify-center text-xs font-bold transition-all duration-150"
              :class="i <= stepIndex ? 'bg-slate-900 text-white' : 'bg-gray-100 text-gray-400'"
            >
              <Check v-if="i < stepIndex" class="h-3 w-3" />
              <span v-else>{{ i + 1 }}</span>
            </div>
            <span
              class="text-xs hidden sm:block"
              :class="i <= stepIndex ? 'text-gray-800 font-bold' : 'text-gray-400 font-medium'"
            >{{ label }}</span>
          </div>
          <div v-if="i < 2" class="flex-1 h-px mx-3 bg-gray-100 min-w-4" />
        </template>
      </div>

      <!-- Body -->
      <div class="px-6 py-6 min-h-[300px] flex flex-col justify-center">

        <!-- STEP: Platform selection -->
        <div v-if="step === 'platform'" class="flex flex-col items-center text-center space-y-4">
          <div class="w-14 h-14 rounded-2xl bg-emerald-50 flex items-center justify-center">
            <svg viewBox="0 0 24 24" class="w-7 h-7 fill-emerald-500">
              <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347z"/>
            </svg>
          </div>
          <div>
            <h3 class="text-base font-extrabold text-gray-900">Todas as conversas. Um único painel.</h3>
            <p class="text-xs text-gray-500 max-w-sm mx-auto mt-1">
              Habilite a centralização do WhatsApp no Zavy CRM. Vamos começar selecionando a plataforma do seu celular.
            </p>
          </div>
          <div class="flex gap-4 w-full max-w-xs pt-4">
            <button
              class="flex-1 flex flex-col items-center gap-2.5 p-4 rounded-2xl border-2 border-gray-150 hover:border-slate-800 hover:bg-slate-50 transition-all group"
              @click="selectPlatform('android')"
            >
              <span class="text-3xl">🤖</span>
              <span class="text-xs font-bold text-gray-800">Android</span>
            </button>
            <button
              class="flex-1 flex flex-col items-center gap-2.5 p-4 rounded-2xl border-2 border-gray-150 hover:border-slate-800 hover:bg-slate-50 transition-all group"
              @click="selectPlatform('iphone')"
            >
              <span class="text-3xl">🍎</span>
              <span class="text-xs font-bold text-gray-800">iPhone</span>
            </button>
          </div>
        </div>

        <!-- STEP: QR Code -->
        <div v-else-if="step === 'qr'" class="flex flex-col md:flex-row gap-6 w-full animate-scale-up">
          <!-- Left: Instructions -->
          <div class="flex-1 flex flex-col justify-between space-y-4">
            <div>
              <h3 class="text-base font-extrabold text-gray-900">
                Abra o seu WhatsApp no celular
              </h3>

              <ol class="space-y-2.5 text-xs text-gray-650 font-medium pl-4 list-decimal leading-relaxed pt-3">
                <li>Abra o WhatsApp no seu celular</li>
                <li>
                  <template v-if="platform === 'iphone'">
                    Vá em <strong>Configurações</strong> → <strong>Dispositivos conectados</strong>
                  </template>
                  <template v-else>
                    Vá no <strong>Menu (3 pontos)</strong> → <strong>Dispositivos conectados</strong>
                  </template>
                </li>
                <li>Toque em <strong>Conectar um dispositivo</strong></li>
                <li>Aponte a câmera para o QR Code ao lado</li>
              </ol>
            </div>

            <div class="pt-3">
              <p v-if="apiError" class="text-xs text-rose-600 font-semibold mb-2">{{ apiError }}</p>
              <p v-else class="text-xs text-gray-400 flex items-center gap-1.5 font-semibold">
                <Loader2 class="animate-spin h-3.5 w-3.5 text-zavy-600" />
                Aguardando leitura pelo celular...
              </p>
            </div>
          </div>

          <!-- Right: QR Code -->
          <div class="flex flex-col items-center justify-center flex-shrink-0 bg-gray-50 border border-gray-150 rounded-3xl p-4 w-full md:w-52 h-52 relative">
            <div class="relative w-full h-full flex items-center justify-center">
              <div v-if="loadingQr || !qrCode" class="w-full h-full flex items-center justify-center">
                <Loader2 class="animate-spin h-8 w-8 text-gray-400" />
              </div>
              <img
                v-else
                :src="qrCode"
                alt="Evolution QR Code"
                class="w-full h-full object-contain rounded-xl"
              />
            </div>
            <button
              class="absolute bottom-2 text-[10px] text-zavy-600 hover:text-zavy-700 flex items-center gap-1 font-bold bg-white/95 border border-gray-150 rounded-full px-2.5 py-1 shadow-sm transition-all"
              @click="refreshQr"
              :disabled="loadingQr"
            >
              <RefreshCw class="h-3 w-3" :class="{'animate-spin': loadingQr}" />
              <span>Atualizar QR</span>
            </button>
          </div>
        </div>

        <!-- STEP: Success -->
        <div v-else-if="step === 'success'" class="flex flex-col items-center justify-center text-center py-6 space-y-4 animate-scale-up">
          <div class="w-14 h-14 rounded-full bg-emerald-50 border border-emerald-100 flex items-center justify-center text-emerald-500">
            <Check class="h-7 w-7" />
          </div>
          <div>
            <h3 class="text-base font-extrabold text-gray-900">WhatsApp conectado!</h3>
            <p class="text-xs text-gray-500 max-w-xs mx-auto mt-1">
              O número do celular foi associado com sucesso e está pronto para uso no Zavy CRM.
            </p>
          </div>
        </div>

      </div>
    </div>
  </div>
</template>
