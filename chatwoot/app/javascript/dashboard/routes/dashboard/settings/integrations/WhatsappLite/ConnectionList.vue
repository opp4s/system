<script setup>
defineProps({
  instances: { type: Array, default: () => [] },
  loading: { type: Boolean, default: false },
});

defineEmits(['disconnect']);

function statusColor(status) {
  return status === 'open' ? 'text-green-500' : 'text-n-slate-9';
}

function statusLabel(status) {
  const map = { open: 'Conectado', close: 'Desconectado', connecting: 'Conectando...' };
  return map[status] || status;
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
          <th class="pb-3 pr-4 font-medium">Nome</th>
          <th class="pb-3 pr-4 font-medium">Número</th>
          <th class="pb-3 pr-4 font-medium">Estado</th>
          <th class="pb-3 font-medium text-right">Ações</th>
        </tr>
      </thead>
      <tbody>
        <tr
          v-for="inst in instances"
          :key="inst.id"
          class="border-b border-n-weak last:border-0"
        >
          <td class="py-3 pr-4 font-medium text-n-slate-12">{{ inst.name }}</td>
          <td class="py-3 pr-4 text-n-slate-11">{{ inst.phone || '—' }}</td>
          <td class="py-3 pr-4">
            <span class="flex items-center gap-1.5" :class="statusColor(inst.status)">
              <span class="w-2 h-2 rounded-full bg-current" />
              {{ statusLabel(inst.status) }}
            </span>
          </td>
          <td class="py-3 text-right">
            <button
              class="text-ruby-500 hover:text-ruby-600 text-xs font-medium"
              @click="$emit('disconnect', inst.id)"
            >
              Desconectar
            </button>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>
