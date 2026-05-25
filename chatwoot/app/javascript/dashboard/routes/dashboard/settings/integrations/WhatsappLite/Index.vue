<script setup>
import { ref, onMounted } from 'vue';
import { useRoute } from 'vue-router';
import ConnectionList from './ConnectionList.vue';
import SettingsForm from './SettingsForm.vue';
import WizardModal from './WizardModal.vue';

/* global axios */

const route = useRoute();
const instances = ref([]);
const showWizard = ref(false);
const loading = ref(false);
const wizardReconnect = ref(null);

// null = loading, true = configured, false = needs setup
const settingsConfigured = ref(null);
const settingsUrl = ref('');

function accountId() {
  return route.params.accountId;
}

async function checkSettings() {
  try {
    const res = await axios.get(
      `/api/v1/accounts/${accountId()}/whatsapp_lite/settings`
    );
    settingsConfigured.value = res.data.configured;
    settingsUrl.value = res.data.evolution_api_url || '';
  } catch {
    settingsConfigured.value = false;
  }
}

async function fetchInstances() {
  loading.value = true;
  try {
    const res = await axios.get(
      `/api/v1/accounts/${accountId()}/whatsapp_lite/instances`
    );
    instances.value = res.data;
  } catch {
    instances.value = [];
  } finally {
    loading.value = false;
  }
}

function onSettingsSaved() {
  settingsConfigured.value = true;
  fetchInstances();
}

async function disconnect(inst) {
  const ok = confirm(
    `Desconectar "${inst.phone_number}"?\n\n` +
    `A caixa de entrada e o histórico serão preservados. ` +
    `Você poderá reconectar quando quiser.`
  );
  if (!ok) return;

  try {
    await axios.post(
      `/api/v1/accounts/${accountId()}/whatsapp_lite/disconnect`,
      { instance_id: inst.instance_id }
    );
  } catch (e) {
    console.error('disconnect error', e);
    alert('Erro ao desconectar. Verifique a conexão.');
  }
  await fetchInstances();
}

async function deleteInstance(inst) {
  const ok = confirm(
    `Excluir definitivamente "${inst.phone_number}"?\n\n` +
    `ATENÇÃO: a caixa de entrada e TODAS as conversas serão removidas.\n` +
    `Esta ação não pode ser desfeita.`
  );
  if (!ok) return;

  try {
    await axios.delete(
      `/api/v1/accounts/${accountId()}/whatsapp_lite/instances` +
      `?instance_id=${encodeURIComponent(inst.instance_id)}`
    );
  } catch (e) {
    console.error('delete error', e);
    alert('Erro ao excluir. Verifique a conexão.');
  }
  await fetchInstances();
}

function reconnect(inst) {
  wizardReconnect.value = inst;
  showWizard.value = true;
}

function onWizardClose() {
  showWizard.value = false;
  wizardReconnect.value = null;
}

function onConnected() {
  showWizard.value = false;
  wizardReconnect.value = null;
  fetchInstances();
}

onMounted(async () => {
  await checkSettings();
  if (settingsConfigured.value) {
    await fetchInstances();
  }
});
</script>

<template>
  <!-- Loading -->
  <div v-if="settingsConfigured === null" class="flex items-center justify-center py-20 text-n-slate-9">
    <span class="i-woot-spinner animate-spin text-2xl mr-2" />
    Carregando...
  </div>

  <!-- Settings form (first-time setup) -->
  <SettingsForm
    v-else-if="!settingsConfigured"
    :account-id="accountId()"
    :current-url="settingsUrl"
    @saved="onSettingsSaved"
  />

  <!-- Main UI -->
  <div v-else class="flex flex-col h-full">
    <div class="flex items-center justify-between px-6 py-4 border-b border-n-weak">
      <div class="flex items-center gap-3">
        <div class="h-10 w-10 rounded-lg bg-[#25D366]/10 flex items-center justify-center flex-shrink-0">
          <svg viewBox="0 0 24 24" class="w-6 h-6 fill-[#25D366]">
            <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347z"/>
            <path d="M12 0C5.373 0 0 5.373 0 12c0 2.124.554 4.118 1.524 5.845L.057 23.07a.75.75 0 00.932.932l5.226-1.467A11.944 11.944 0 0012 24c6.627 0 12-5.373 12-12S18.627 0 12 0zm0 22c-1.89 0-3.663-.497-5.193-1.367l-.372-.214-3.852 1.081 1.081-3.852-.214-.372A9.944 9.944 0 012 12C2 6.477 6.477 2 12 2s10 4.477 10 10-4.477 10-10 10z"/>
          </svg>
        </div>
        <div>
          <h2 class="text-heading-2 text-n-slate-12">WhatsApp Lite</h2>
          <p class="text-body-sm text-n-slate-11">
            Gerencie conexões WhatsApp via Evolution API
          </p>
        </div>
      </div>
      <div class="flex items-center gap-2">
        <button
          class="px-3 py-2 text-xs text-n-slate-9 hover:text-n-slate-12 border border-n-weak rounded-lg transition-colors"
          :title="settingsUrl || 'Configurações'"
          @click="settingsConfigured = false"
        >
          Configurações
        </button>
        <button
          class="flex items-center gap-2 px-4 py-2 bg-woot-500 text-white rounded-lg text-sm font-medium hover:bg-woot-600 transition-colors"
          @click="showWizard = true"
        >
          <span class="i-woot-plus text-base" />
          Conectar WhatsApp
        </button>
      </div>
    </div>

    <div class="flex-1 overflow-auto px-6 py-4">
      <ConnectionList
        :instances="instances"
        :loading="loading"
        @on-disconnect="disconnect"
        @on-reconnect="reconnect"
        @on-delete="deleteInstance"
      />
    </div>

    <WizardModal
      v-if="showWizard"
      :account-id="accountId()"
      :reconnect-instance="wizardReconnect"
      @close="onWizardClose"
      @connected="onConnected"
    />
  </div>
</template>
