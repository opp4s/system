<script setup>
import { ref, onMounted } from 'vue'
import { Plus, Loader2 } from 'lucide-vue-next'
import { useChatwootStore } from '@/stores/chatwoot'
import api from '@/plugins/axios'
import ConnectionList from './ConnectionList.vue'
import WizardModal from './WizardModal.vue'
import { useToast } from '@/composables/useToast'

const chatwootStore = useChatwootStore()
const toast = useToast()

const instances = ref([])
const pipelines = ref([])
const showWizard = ref(false)
const loading = ref(false)
const wizardReconnect = ref(null)

const ready = ref(null) // null = loading
const isPrimary = ref(true) // Zavy CRM is always primary
const configured = ref(true) // always configured on Zavy env vars

async function checkSettings() {
  try {
    ready.value = true
    await Promise.all([fetchInstances(), fetchPipelines()])
  } catch (e) {
    console.error('settings check failed', e)
    ready.value = true
  }
}

async function fetchInstances() {
  loading.value = true
  try {
    const res = await api.get('/api/v1/whatsapp/status')
    const list = res.data?.data?.instances || []
    instances.value = list.map(wi => ({
      instance_id: wi.instance_id,
      phone_number: wi.phone,
      status: wi.status,
      name: wi.name,
      pipeline_id: wi.pipeline_id
    }))
    chatwootStore.configured = instances.value.some(i => i.status === 'connected')
  } catch {
    instances.value = []
    chatwootStore.configured = false
  } finally {
    loading.value = false
  }
}

async function fetchPipelines() {
  try {
    const res = await api.get('/api/v1/pipelines')
    pipelines.value = res.data?.data || res.data || []
  } catch (e) {
    console.error('[WhatsApp] Erro ao buscar pipelines:', e)
  }
}

async function handleDisconnect(inst) {
  const ok = confirm(
    `Desconectar "${inst.phone_number || inst.instance_id}"?\n\n` +
    `A caixa de entrada e o histórico serão preservados. ` +
    `Você poderá reconectar quando quiser.`
  )
  if (!ok) return
  
  loading.value = true
  try {
    await api.post('/api/v1/whatsapp/disconnect', { instance_id: inst.instance_id })
    toast.success('WhatsApp desconectado com sucesso.')
    await fetchInstances()
  } catch (e) {
    console.error('disconnect error', e)
    toast.error('Erro ao desconectar. Verifique a conexão.')
  } finally {
    loading.value = false
  }
}

async function handleDelete(instance) {
  const confirmed = confirm(`Tem certeza que deseja EXCLUIR a instância ${instance.instance_id}?\n\nEsta ação é irreversível e desconectará o WhatsApp permanentemente.`)
  if (!confirmed) return

  loading.value = true
  try {
    await api.delete('/api/v1/whatsapp/destroy', {
      data: { instance_id: instance.instance_id }
    })
    instances.value = instances.value.filter(i => i.instance_id !== instance.instance_id)
    toast.success('Instância excluída com sucesso')
  } catch (error) {
    toast.error('Erro ao excluir instância')
    console.error(error)
  } finally {
    loading.value = false
  }
}

function handleReconnect(inst) {
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

onMounted(checkSettings)
</script>

<template>
  <div class="max-w-4xl mx-auto space-y-6 px-4 sm:px-6 lg:px-8 py-6">
    <!-- Loading -->
    <div v-if="ready === null" class="flex flex-col items-center justify-center py-20 text-gray-500">
      <Loader2 class="animate-spin h-8 w-8 text-zavy-600 mb-3" />
      <span>Carregando...</span>
    </div>

    <!-- Normal operation (configured) -->
    <div v-else class="flex flex-col h-full bg-white border border-gray-200 rounded-3xl shadow-sm overflow-hidden">
      
      <!-- Header -->
      <div class="flex items-center justify-between px-6 py-5 border-b border-gray-100 bg-gray-50/50">
        <div class="flex items-center gap-3">
          <div class="h-10 w-10 rounded-xl bg-emerald-50 border border-emerald-100 flex items-center justify-center flex-shrink-0">
            <svg viewBox="0 0 24 24" class="w-6 h-6 fill-emerald-500">
              <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347z"/>
              <path d="M12 0C5.373 0 0 5.373 0 12c0 2.124.554 4.118 1.524 5.845L.057 23.07a.75.75 0 00.932.932l5.226-1.467A11.944 11.944 0 0012 24c6.627 0 12-5.373 12-12S18.627 0 12 0zm0 22c-1.89 0-3.663-.497-5.193-1.367l-.372-.214-3.852 1.081 1.081-3.852-.214-.372A9.944 9.944 0 012 12C2 6.477 6.477 2 12 2s10 4.477 10 10-4.477 10-10 10z"/>
            </svg>
          </div>
          <div>
            <h2 class="text-base font-extrabold text-gray-900">WhatsApp Lite</h2>
            <p class="text-xs text-gray-500 mt-0.5">
              Gerencie conexões WhatsApp
            </p>
            <p class="text-xs text-slate-400 mt-1 leading-normal font-medium max-w-sm">
              Se nenhum funil for selecionado, os leads serão direcionados automaticamente para o primeiro funil da conta.
            </p>
          </div>
        </div>
        <div class="flex items-center gap-2">
          <button
            class="flex items-center gap-2 px-5 py-2.5 bg-slate-900 text-white rounded-xl text-xs font-bold hover:bg-slate-800 shadow-md shadow-slate-900/10 hover:shadow-lg transition-all"
            @click="showWizard = true"
          >
            <Plus class="h-4 w-4" />
            <span>Conectar WhatsApp</span>
          </button>
        </div>
      </div>

      <!-- Connection list area -->
      <div class="flex-1 overflow-auto px-6 py-6 bg-white">
        <ConnectionList
          :instances="instances"
          :pipelines="pipelines"
          :loading="loading"
          @disconnect="handleDisconnect"
          @reconnect="handleReconnect"
          @delete="handleDelete"
        />
      </div>

      <!-- Wizard Modal overlay -->
      <WizardModal
        v-if="showWizard"
        :reconnect-instance="wizardReconnect"
        @close="onWizardClose"
        @connected="onConnected"
      />
    </div>
  </div>
</template>
