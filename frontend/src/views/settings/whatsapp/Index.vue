<script setup>
import { ref, onMounted } from 'vue'
import { MessageSquare, Plus, Loader2 } from 'lucide-vue-next'
import { useChatwootStore } from '@/stores/chatwoot'
import api from '@/plugins/axios'
import ConnectionList from './ConnectionList.vue'
import WizardModal from './WizardModal.vue'
import { useToast } from '@/composables/useToast'

const chatwootStore = useChatwootStore()
const toast = useToast()

const instances = ref([])
const showWizard = ref(false)
const loading = ref(false)
const wizardReconnect = ref(null)
const ready = ref(false)

async function fetchInstances() {
  loading.value = true
  try {
    const res = await api.get('/api/v1/whatsapp/status')
    const data = res.data?.data
    if (data && data.instance_id) {
      instances.value = [{
        instance_id: data.instance_id,
        phone_number: data.phone,
        status: data.connected ? 'connected' : 'user_disconnected'
      }]
      chatwootStore.configured = data.connected
    } else {
      instances.value = []
      chatwootStore.configured = false
    }
  } catch (e) {
    console.error('fetchInstances error', e)
    instances.value = []
    chatwootStore.configured = false
  } finally {
    loading.value = false
    ready.value = true
  }
}

async function disconnect(inst) {
  const ok = confirm(
    `Desconectar "${inst.phone_number || 'Dispositivo'}"?\n\n` +
    `A sincronização de mensagens será interrompida e a instância desligada.`
  )
  if (!ok) return
  
  loading.value = true
  try {
    await api.post('/api/v1/whatsapp/disconnect')
    chatwootStore.configured = false
    chatwootStore.disconnectChatwoot() // limpa o store local
    toast.success('WhatsApp desconectado com sucesso.')
    await fetchInstances()
  } catch (e) {
    console.error('disconnect error', e)
    toast.error('Erro ao desconectar. Verifique a conexão com a Evolution API.')
  } finally {
    loading.value = false
  }
}

function reconnect(inst) {
  wizardReconnect.value = inst
  showWizard.value = true
}

function onWizardClose() {
  showWizard.value = false
  wizardReconnect.value = null
}

function onConnected() {
  showWizard.value = false
  wizardReconnect.value = null
  fetchInstances()
}

onMounted(fetchInstances)
</script>

<template>
  <div class="max-w-4xl mx-auto space-y-6 px-4 sm:px-6 lg:px-8 py-6">
    <!-- Header -->
    <header class="pb-5 border-b border-gray-200">
      <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 class="text-2xl font-extrabold text-gray-900 tracking-tight flex items-center space-x-2">
            <MessageSquare class="h-6 w-6 text-zavy-600" />
            <span>Conexão do WhatsApp</span>
          </h1>
          <p class="text-sm text-gray-500 mt-1">
            Integre e gerencie números de WhatsApp no seu workspace via Evolution API.
          </p>
        </div>
        <div class="flex items-center gap-2">
          <button
            v-if="ready && !instances.some(i => i.status === 'connected')"
            class="flex items-center gap-2 px-5 py-2.5 bg-slate-900 text-white rounded-xl text-xs font-bold hover:bg-slate-800 shadow-md shadow-slate-900/10 hover:shadow-lg transition-all"
            @click="showWizard = true"
          >
            <Plus class="h-4 w-4" />
            <span>Conectar WhatsApp</span>
          </button>
        </div>
      </div>
    </header>

    <!-- Main Content -->
    <div class="py-2">
      <!-- Loading state -->
      <div v-if="!ready" class="flex flex-col items-center justify-center py-20 text-gray-500">
        <Loader2 class="animate-spin h-8 w-8 text-zavy-600 mb-3" />
        <span class="text-xs font-bold uppercase tracking-wider">Buscando configurações...</span>
      </div>

      <!-- Loaded content -->
      <template v-else>
        <ConnectionList
          :instances="instances"
          :loading="loading"
          @on-disconnect="disconnect"
          @on-reconnect="reconnect"
        />
      </template>
    </div>

    <!-- Wizard Modal overlay -->
    <WizardModal
      v-if="showWizard"
      :reconnect-instance="wizardReconnect"
      @close="onWizardClose"
      @connected="onConnected"
    />
  </div>
</template>
