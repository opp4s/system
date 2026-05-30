<template>
  <div class="overflow-x-auto">
    <table class="w-full min-w-[700px]">
      <thead>
        <tr class="text-left text-xs text-slate-400 uppercase tracking-wider border-b border-slate-100">
          <th class="py-3 px-4 font-medium">Nome</th>
          <th class="py-3 px-4 font-medium">Número</th>
          <th class="py-3 px-4 font-medium">Funil</th>
          <th class="py-3 px-4 font-medium">Estado</th>
          <th class="py-3 px-4 font-medium text-right">Ações</th>
        </tr>
      </thead>
      <tbody>
        <tr
          v-for="inst in instances"
          :key="inst.instance_id"
          class="border-b border-slate-50 hover:bg-slate-50/50 transition-colors"
        >
          <!-- NOME — editável inline -->
          <td class="py-3 px-4">
            <input
              :value="inst.name || ''"
              @blur="onNameBlur($event, inst)"
              @keyup.enter="$event.target.blur()"
              class="bg-transparent border-0 border-b border-transparent hover:border-slate-300 focus:border-indigo-500 focus:ring-0 text-sm text-slate-800 w-full max-w-[200px] px-0 py-1 placeholder:text-slate-300"
              placeholder="Dar um nome..."
            />
          </td>

          <!-- NÚMERO — formatado, não editável -->
          <td class="py-3 px-4 text-sm text-slate-700 font-mono">
            {{ formatPhone(inst.phone_number) }}
          </td>

          <!-- FUNIL — dropdown -->
          <td class="py-3 px-4">
            <select
              :value="inst.pipeline_id"
              @change="onPipelineChange($event, inst)"
              class="text-sm border border-slate-200 rounded-lg px-3 py-1.5 bg-white hover:border-slate-300 focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500 cursor-pointer min-w-[180px]"
            >
              <option :value="null">Selecionar funil...</option>
              <option v-for="p in pipelines" :key="p.id" :value="p.id">
                {{ p.name }}
              </option>
            </select>
          </td>

          <!-- ESTADO — bolinha + label -->
          <td class="py-3 px-4">
            <span class="inline-flex items-center gap-2">
              <span
                class="w-2.5 h-2.5 rounded-full"
                :class="statusDotClass(inst.status)"
              ></span>
              <span class="text-sm" :class="statusTextClass(inst.status)">
                {{ statusLabel(inst.status) }}
              </span>
            </span>
          </td>

          <!-- AÇÕES -->
          <td class="py-3 px-4 text-right whitespace-nowrap">
            <button
              v-if="inst.status === 'connected'"
              @click="$emit('disconnect', inst)"
              class="text-slate-400 hover:text-slate-600 text-sm mr-4 transition-colors"
            >
              Desconectar
            </button>
            <button
              v-else
              @click="$emit('reconnect', inst)"
              class="text-indigo-500 hover:text-indigo-700 text-sm mr-4 transition-colors"
            >
              Reconectar
            </button>
            <button
              @click="confirmDelete(inst)"
              class="text-red-400 hover:text-red-600 transition-colors"
              title="Excluir instância permanentemente"
            >
              <svg class="w-4 h-4 inline" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
              </svg>
            </button>
          </td>
        </tr>
      </tbody>
    </table>

    <!-- Empty state -->
    <div v-if="!instances || instances.length === 0" class="text-center py-12 text-slate-400">
      <p class="text-lg">Nenhuma conexão WhatsApp</p>
      <p class="text-sm mt-1">Clique em "+ Conectar WhatsApp" para adicionar</p>
    </div>
  </div>
</template>

<script setup>
import { defineProps, defineEmits } from 'vue'
import api from '@/plugins/axios'

const props = defineProps({
  instances: { type: Array, default: () => [] },
  pipelines: { type: Array, default: () => [] }
})

const emit = defineEmits(['disconnect', 'reconnect', 'delete'])

// --- Formatação ---

function formatPhone(phone) {
  if (!phone) return '—'
  const clean = String(phone).replace(/\D/g, '')
  // Formato brasileiro: +55 XX XXXXX-XXXX
  if (clean.length === 13) {
    return `+${clean.slice(0,2)} ${clean.slice(2,4)} ${clean.slice(4,9)}-${clean.slice(9)}`
  }
  if (clean.length === 12) {
    return `+${clean.slice(0,2)} ${clean.slice(2,4)} ${clean.slice(4,8)}-${clean.slice(8)}`
  }
  return phone.startsWith('+') ? phone : `+${clean}`
}

function statusDotClass(status) {
  switch (status) {
    case 'connected': return 'bg-green-500'
    case 'connecting': return 'bg-yellow-400 animate-pulse'
    case 'qr_pending': return 'bg-yellow-400 animate-pulse'
    default: return 'bg-red-400'
  }
}

function statusTextClass(status) {
  switch (status) {
    case 'connected': return 'text-green-700'
    case 'connecting': return 'text-yellow-600'
    case 'qr_pending': return 'text-yellow-600'
    default: return 'text-red-500'
  }
}

function statusLabel(status) {
  switch (status) {
    case 'connected': return 'Conectado'
    case 'connecting': return 'Conectando...'
    case 'qr_pending': return 'Aguardando conexão'
    default: return 'Desconectado'
  }
}

// --- Ações inline ---

async function onNameBlur(event, inst) {
  const newName = event.target.value.trim()
  if (newName === (inst.name || '')) return // sem mudança

  try {
    await api.patch(`/api/v1/whatsapp/instances/${inst.instance_id}`, {
      instance: { name: newName }
    })
    inst.name = newName
  } catch (e) {
    console.error('[WhatsApp] Erro ao salvar nome:', e)
    event.target.value = inst.name || '' // reverter
  }
}

async function onPipelineChange(event, inst) {
  const newPipelineId = event.target.value ? Number(event.target.value) : null

  try {
    await api.patch(`/api/v1/whatsapp/instances/${inst.instance_id}`, {
      instance: { pipeline_id: newPipelineId }
    })
    inst.pipeline_id = newPipelineId
  } catch (e) {
    console.error('[WhatsApp] Erro ao vincular funil:', e)
    event.target.value = inst.pipeline_id || '' // reverter
  }
}

function confirmDelete(inst) {
  const msg = `Tem certeza que deseja EXCLUIR a conexão "${inst.name || inst.phone_number || inst.instance_id}"?\n\nEsta ação é irreversível e desconectará o WhatsApp permanentemente.`
  if (confirm(msg)) {
    emit('delete', inst)
  }
}
</script>
