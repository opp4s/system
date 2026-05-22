<script setup>
import { ref, onMounted } from 'vue';
import ConnectionList from './ConnectionList.vue';
import WizardModal from './WizardModal.vue';

const instances = ref([]);
const showWizard = ref(false);
const loading = ref(false);

const API_BASE = window.whatsappLiteConfig?.apiBase || '';

async function fetchInstances() {
  loading.value = true;
  try {
    const res = await fetch(`${API_BASE}/wa/instances`);
    instances.value = await res.json();
  } catch {
    instances.value = [];
  } finally {
    loading.value = false;
  }
}

async function disconnect(instanceId) {
  await fetch(`${API_BASE}/wa/instances/${instanceId}`, { method: 'DELETE' });
  await fetchInstances();
}

function onConnected() {
  showWizard.value = false;
  fetchInstances();
}

onMounted(fetchInstances);
</script>

<template>
  <div class="flex flex-col h-full">
    <div class="flex items-center justify-between px-6 py-4 border-b border-n-weak">
      <div class="flex items-center gap-3">
        <img
          src="/dashboard/images/integrations/whatsapp_lite.png"
          class="h-10 w-10 rounded-lg"
          alt="WhatsApp Lite"
        />
        <div>
          <h2 class="text-heading-2 text-n-slate-12">WhatsApp Lite</h2>
          <p class="text-body-sm text-n-slate-11">
            Gerencie conexões WhatsApp via Evolution API
          </p>
        </div>
      </div>
      <button
        class="flex items-center gap-2 px-4 py-2 bg-woot-500 text-white rounded-lg text-sm font-medium hover:bg-woot-600 transition-colors"
        @click="showWizard = true"
      >
        <span class="i-woot-plus text-base" />
        Conectar WhatsApp
      </button>
    </div>

    <div class="flex-1 overflow-auto px-6 py-4">
      <ConnectionList
        :instances="instances"
        :loading="loading"
        @disconnect="disconnect"
      />
    </div>

    <WizardModal
      v-if="showWizard"
      :api-base="API_BASE"
      @close="showWizard = false"
      @connected="onConnected"
    />
  </div>
</template>
