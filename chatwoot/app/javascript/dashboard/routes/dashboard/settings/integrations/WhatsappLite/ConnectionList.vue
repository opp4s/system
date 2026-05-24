<script setup>
import { ref } from 'vue';

defineProps({
  instances: { type: Array, default: () => [] },
  loading: { type: Boolean, default: false },
});

const emit = defineEmits(['disconnect', 'reconnect', 'delete']);

const confirmingDelete = ref(null);
const actionLoading = ref(null);

function statusColor(status) {
  return status === 'connected' ? 'text-green-500' : 'text-n-slate-9';
}

function statusLabel(status) {
  const map = {
    connected:    'Conectado',
    disconnected: 'Desconectado',
    qr_pending:   'Aguardando QR',
    qr_expired:   'QR Expirado',
  };
  return map[status] || status;
}

async function handleDisconnect(instanceId) {
  actionLoading.value = `disconnect-${instanceId}`;
  try {
    await new Promise(resolve => setTimeout(resolve, 0));
    emit('disconnect', instanceId);
  } finally {
    actionLoading.value = null;
  }
}

async function handleReconnect(inst) {
  actionLoading.value = `reconnect-${inst.instance_id}`;
  try {
    await new Promise(resolve => setTimeout(resolve, 0));
    emit('reconnect', inst);
  } finally {
    actionLoading.value = null;
  }
}

function confirmDelete(instanceId) {
  confirmingDelete.value = instanceId;
}

function cancelDelete() {
  confirmingDelete.value = null;
}

async function handleDelete(instanceId) {
  actionLoading.value = `delete-${instanceId}`;
  confirmingDelete.value = null;
  try {
    emit('delete', instanceId);
  } finally {
    actionLoading.value = null;
  }
}
</script>

<template>
  <div v-if="loading" class="flex items-center justify-center py-16 text-n-slate-9">
    <span class="i-woot-spinner animate-spin text-2xl mr-2" />
    Carregando instâncias...
  </div>

  <div v-else-if="!instances.length" class="flex flex-col items-center justify-center py-16 text-center">
    <div class="w-16 h-16 rounded-full bg-n-alpha-2 flex items-center justify-center mb-4">
      <span class="i-woot-whatsapp text-3xl text-n-slate-9" />
    </div>
    <h3 class="text-heading-3 text-n-slate-12 mb-1">Nenhum número conectado</h3>
    <p class="text-body-sm text-n-slate-10">
      Clique em "Conectar WhatsApp" para adicionar um número.
    </p>
  </div>

  <div v-else class="overflow-x-auto">
    <table class="w-full text-sm">
      <thead>
        <tr class="border-b border-n-weak text-n-slate-10 text-left">
          <th class="pb-3 pr-4 font-medium">Instância</th>
          <th class="pb-3 pr-4 font-medium">Número</th>
          <th class="pb-3 pr-4 font-medium">Estado</th>
          <th class="pb-3 font-medium text-right">Ações</th>
        </tr>
      </thead>
      <tbody>
        <tr
          v-for="inst in instances"
          :key="inst.instance_id"
          class="border-b border-n-weak last:border-0"
        >
          <td class="py-3 pr-4 font-medium text-n-slate-12 font-mono text-xs">{{ inst.instance_id }}</td>
          <td class="py-3 pr-4 text-n-slate-11">{{ inst.phone_number || '—' }}</td>
          <td class="py-3 pr-4">
            <span class="flex items-center gap-1.5" :class="statusColor(inst.status)">
              <span class="w-2 h-2 rounded-full bg-current" />
              {{ statusLabel(inst.status) }}
            </span>
          </td>
          <td class="py-3 text-right">
            <template v-if="confirmingDelete === inst.instance_id">
              <span class="text-xs text-n-slate-11 mr-2">Excluir inbox e conversas?</span>
              <button
                class="text-ruby-500 hover:text-ruby-600 text-xs font-medium mr-3"
                @click="handleDelete(inst.instance_id)"
              >
                Confirmar
              </button>
              <button
                class="text-n-slate-9 hover:text-n-slate-12 text-xs"
                @click="cancelDelete"
              >
                Cancelar
              </button>
            </template>
            <template v-else>
              <button
                v-if="inst.status !== 'connected'"
                class="text-woot-500 hover:text-woot-600 text-xs font-medium mr-3 disabled:opacity-50"
                :disabled="actionLoading === `reconnect-${inst.instance_id}`"
                @click="handleReconnect(inst)"
              >
                <span v-if="actionLoading === `reconnect-${inst.instance_id}`" class="i-woot-spinner animate-spin mr-1" />
                Reconectar
              </button>
              <button
                class="text-n-slate-9 hover:text-n-slate-12 text-xs font-medium mr-3 disabled:opacity-50"
                :disabled="actionLoading === `disconnect-${inst.instance_id}`"
                @click="handleDisconnect(inst.instance_id)"
              >
                <span v-if="actionLoading === `disconnect-${inst.instance_id}`" class="i-woot-spinner animate-spin mr-1" />
                Desconectar
              </button>
              <button
                class="text-ruby-500 hover:text-ruby-600 text-xs font-medium disabled:opacity-50"
                :disabled="!!actionLoading"
                @click="confirmDelete(inst.instance_id)"
              >
                Excluir
              </button>
            </template>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>
