<script setup>
defineProps({
  instances: { type: Array, default: () => [] },
  loading: { type: Boolean, default: false },
});

defineEmits(['on-disconnect', 'on-reconnect', 'on-delete']);

const statusConfig = {
  connected: {
    label: 'Conectado',
    color: 'text-green-500',
    dot: 'bg-green-500',
    canDisconnect: true,
    canReconnect: false,
    canDelete: true,
  },
  qr_pending: {
    label: 'Aguardando conexão',
    color: 'text-orange-500',
    dot: 'bg-orange-500',
    canDisconnect: false,
    canReconnect: true,
    canDelete: true,
  },
  auto_disconnected: {
    label: 'Reconectar',
    color: 'text-red-500',
    dot: 'bg-red-500',
    canDisconnect: false,
    canReconnect: true,
    canDelete: true,
  },
  user_disconnected: {
    label: 'Desconectado',
    color: 'text-gray-500',
    dot: 'bg-gray-400',
    canDisconnect: false,
    canReconnect: true,
    canDelete: true,
  },
  deleted: {
    label: 'Excluído',
    color: 'text-gray-300',
    dot: 'bg-gray-300',
    canDisconnect: false,
    canReconnect: false,
    canDelete: false,
  },
};

function cfg(status) {
  return statusConfig[status] || {
    label: status,
    color: 'text-gray-400',
    dot: 'bg-gray-400',
    canDisconnect: false,
    canReconnect: false,
    canDelete: false,
  };
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
            <span class="inline-flex items-center gap-2">
              <span :class="['inline-block w-2 h-2 rounded-full flex-shrink-0', cfg(inst.status).dot]" />
              <span :class="cfg(inst.status).color">{{ cfg(inst.status).label }}</span>
            </span>
          </td>
          <td class="py-3 text-right space-x-3">
            <button
              v-if="cfg(inst.status).canReconnect"
              class="text-woot-500 hover:underline text-xs font-medium"
              @click="$emit('on-reconnect', inst)"
            >
              Reconectar
            </button>
            <button
              v-if="cfg(inst.status).canDisconnect"
              class="text-n-slate-9 hover:underline text-xs font-medium"
              @click="$emit('on-disconnect', inst)"
            >
              Desconectar
            </button>
            <button
              v-if="cfg(inst.status).canDelete"
              class="text-ruby-500 hover:underline text-xs font-medium"
              @click="$emit('on-delete', inst)"
            >
              Excluir
            </button>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>
