<script setup>
import { Loader2 } from 'lucide-vue-next'

defineProps({
  instances: { type: Array, default: () => [] },
  loading: { type: Boolean, default: false },
})

defineEmits(['on-disconnect', 'on-reconnect', 'on-delete'])

const statusConfig = {
  connected: {
    label: 'Conectado',
    color: 'text-emerald-600 font-bold',
    dot: 'bg-emerald-500 animate-ping',
    canDisconnect: true,
    canReconnect: false,
    canDelete: true,
  },
  qr_pending: {
    label: 'Aguardando conexão',
    color: 'text-amber-600 font-bold',
    dot: 'bg-amber-500 animate-pulse',
    canDisconnect: false,
    canReconnect: true,
    canDelete: true,
  },
  user_disconnected: {
    label: 'Desconectado',
    color: 'text-gray-500 font-medium',
    dot: 'bg-gray-400',
    canDisconnect: false,
    canReconnect: true,
    canDelete: true,
  }
}

function cfg(status) {
  return statusConfig[status] || {
    label: 'Desconectado',
    color: 'text-gray-500 font-medium',
    dot: 'bg-gray-400',
    canDisconnect: false,
    canReconnect: true,
    canDelete: false,
  }
}
</script>

<template>
  <div v-if="loading" class="flex flex-col items-center justify-center py-16 text-gray-500">
    <Loader2 class="animate-spin h-8 w-8 text-zavy-600 mb-3" />
    <span class="text-xs font-bold uppercase tracking-wider">Carregando conexões...</span>
  </div>

  <div v-else-if="!instances.length" class="flex flex-col items-center justify-center py-16 text-center">
    <div class="w-16 h-16 rounded-full bg-emerald-50 border border-emerald-100 flex items-center justify-center mb-4">
      <svg viewBox="0 0 24 24" class="w-8 h-8 fill-emerald-500">
        <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347z"/>
        <path d="M12 0C5.373 0 0 5.373 0 12c0 2.124.554 4.118 1.524 5.845L.057 23.07a.75.75 0 00.932.932l5.226-1.467A11.944 11.944 0 0012 24c6.627 0 12-5.373 12-12S18.627 0 12 0zm0 22c-1.89 0-3.663-.497-5.193-1.367l-.372-.214-3.852 1.081 1.081-3.852-.214-.372A9.944 9.944 0 012 12C2 6.477 6.477 2 12 2s10 4.477 10 10-4.477 10-10 10z"/>
      </svg>
    </div>
    <h3 class="text-base font-bold text-gray-800 mb-1">Nenhuma conexão WhatsApp ativa</h3>
    <p class="text-xs text-gray-500 max-w-xs mx-auto">
      Clique em "Conectar WhatsApp" para parear um número de celular via QR Code ou código.
    </p>
  </div>

  <div v-else class="overflow-x-auto border border-gray-150 rounded-3xl bg-white shadow-sm">
    <table class="w-full text-left border-collapse">
      <thead>
        <tr class="border-b border-gray-100 bg-gray-50/50 text-[10px] font-bold text-gray-400 uppercase tracking-wider">
          <th class="px-6 py-4">ID da Instância</th>
          <th class="px-6 py-4">Número Conectado</th>
          <th class="px-6 py-4">Status</th>
          <th class="px-6 py-4 text-right">Ações</th>
        </tr>
      </thead>
      <tbody>
        <tr
          v-for="inst in instances"
          :key="inst.instance_id"
          class="border-b border-gray-100 last:border-0 hover:bg-gray-50/30 transition-colors text-xs text-gray-800"
        >
          <td class="px-6 py-4 font-mono font-medium text-gray-600">{{ inst.instance_id }}</td>
          <td class="px-6 py-4 font-semibold">{{ inst.phone_number || '—' }}</td>
          <td class="px-6 py-4">
            <span class="inline-flex items-center gap-2">
              <span class="relative flex h-2 w-2">
                <span :class="['absolute inline-flex h-full w-full rounded-full opacity-75', cfg(inst.status).dot]" />
                <span :class="['relative inline-flex rounded-full h-2 w-2', cfg(inst.status).dot.split(' ')[0]]" />
              </span>
              <span :class="cfg(inst.status).color">{{ cfg(inst.status).label }}</span>
            </span>
          </td>
          <td class="px-6 py-4 text-right">
            <div class="flex items-center justify-end gap-3">
              <button
                v-if="cfg(inst.status).canReconnect"
                class="px-3 py-1.5 bg-zavy-50 hover:bg-zavy-100 text-zavy-700 font-bold rounded-xl transition-all"
                @click="$emit('on-reconnect', inst)"
              >
                Reconectar
              </button>
              <button
                v-if="cfg(inst.status).canDisconnect"
                class="px-3 py-1.5 border border-gray-250 hover:bg-gray-50 text-gray-700 font-bold rounded-xl transition-all"
                @click="$emit('on-disconnect', inst)"
              >
                Desconectar
              </button>
              <button
                v-if="cfg(inst.status).canDelete"
                class="px-3 py-1.5 border border-rose-250 hover:bg-rose-50 text-rose-650 font-bold rounded-xl transition-all"
                @click="$emit('on-delete', inst)"
              >
                Excluir
              </button>
            </div>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>
