<template>
  <div class="space-y-6">
    <!-- Título e Nome do Workspace Atual -->
    <div class="flex justify-between items-center">
      <h1 class="text-2xl font-bold text-gray-900 tracking-tight">Dashboard</h1>
      <span class="text-xs font-semibold px-3 py-1 bg-zavy-50 text-zavy-600 rounded-full border border-zavy-100">
        {{ workspaceStore.currentWorkspace.name }}
      </span>
    </div>

    <!-- Banner informativo do WhatsApp (Mostra se não conectado no workspace) -->
    <div 
      v-if="!isWhatsappConnected" 
      class="bg-zavy-50 border border-zavy-100 rounded-2xl p-6 flex items-start space-x-4 transition-all duration-200"
    >
      <div class="p-3 bg-zavy-500 text-white rounded-xl shadow-md">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
        </svg>
      </div>
      <div class="flex-1">
        <h3 class="text-base font-semibold text-zavy-950">Conecte seu WhatsApp para começar</h3>
        <p class="text-sm text-zavy-700 mt-1">Para habilitar a automação de mensagens e sincronização de leads em tempo real, conecte sua conta do WhatsApp via QR Code.</p>
        <div class="mt-3">
          <button 
            @click="connectWhatsapp"
            class="bg-zavy-600 hover:bg-zavy-700 text-white text-sm font-medium py-2 px-4 rounded-xl shadow-sm transition-all hover:shadow duration-200 focus:outline-none"
          >
            Conectar Dispositivo
          </button>
        </div>
      </div>
    </div>

    <!-- Feedback de Conexão WhatsApp Ativa -->
    <div 
      v-else 
      class="bg-emerald-50 border border-emerald-100 rounded-2xl p-5 flex items-center justify-between transition-all duration-200"
    >
      <div class="flex items-center space-x-3">
        <div class="p-2 bg-emerald-500 text-white rounded-xl shadow">
          <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
          </svg>
        </div>
        <div>
          <h4 class="text-sm font-bold text-emerald-950">WhatsApp Conectado</h4>
          <p class="text-xs text-emerald-600">Sincronização ativa no workspace <strong>{{ workspaceStore.currentWorkspace.name }}</strong>.</p>
        </div>
      </div>
      <button 
        @click="disconnectWhatsapp"
        class="text-xs font-semibold text-rose-600 hover:text-rose-700 hover:bg-rose-50 px-3 py-2 rounded-xl transition-all duration-200 focus:outline-none"
      >
        Desconectar
      </button>
    </div>

    <!-- Cards KPI -->
    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
      <div 
        v-for="kpi in currentKpis" 
        :key="kpi.title" 
        class="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm flex flex-col justify-between"
      >
        <div>
          <span class="text-xs font-semibold text-gray-400 uppercase tracking-wider">{{ kpi.title }}</span>
          <div class="text-3xl font-bold text-gray-900 mt-2">{{ kpi.value }}</div>
        </div>
        <div class="mt-4 flex items-center text-xs font-semibold" :class="kpi.trendUp ? 'text-emerald-600' : 'text-rose-500'">
          <span>{{ kpi.trend }}</span>
          <span class="text-gray-400 font-medium ml-1">este mês</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useWorkspaceStore } from '@/stores/workspace'
import { useChatwootStore } from '@/stores/chatwoot'
import { useToast } from '@/composables/useToast'

const workspaceStore = useWorkspaceStore()
const chatwootStore = useChatwootStore()
const toast = useToast()
const router = useRouter()

onMounted(async () => {
  await chatwootStore.fetchSettings()
})

const isWhatsappConnected = computed(() => {
  return chatwootStore.configured
})

const connectWhatsapp = () => {
  router.push('/settings/whatsapp')
}

const disconnectWhatsapp = async () => {
  if (!confirm('Deseja realmente desconectar o WhatsApp?')) return
  try {
    await chatwootStore.disconnectChatwoot()
    toast.warning('WhatsApp desconectado do workspace.')
  } catch (e) {
    toast.error('Erro ao desconectar.')
  }
}

// Dados de KPIs dinâmicos para cada Workspace
const kpiData = computed(() => {
  return {
    1: [
      { title: 'Total Leads', value: '142', trend: '+12%', trendUp: true },
      { title: 'Valor Pipeline', value: 'R$ 24.500,00', trend: '+8.4%', trendUp: true },
      { title: 'Conversão', value: '18.2%', trend: '-1.5%', trendUp: false },
      { title: 'Tempo Médio', value: '14 min', trend: '-2 min', trendUp: true }
    ],
    2: [
      { title: 'Total Leads', value: '84', trend: '+22%', trendUp: true },
      { title: 'Valor Pipeline', value: 'R$ 11.200,00', trend: '+15.2%', trendUp: true },
      { title: 'Conversão', value: '24.1%', trend: '+4.3%', trendUp: true },
      { title: 'Tempo Médio', value: '9 min', trend: '-5 min', trendUp: true }
    ]
  }
})

const currentKpis = computed(() => {
  const id = workspaceStore.currentWorkspaceId
  return kpiData.value[id] || [
    { title: 'Total Leads', value: '12', trend: '+100%', trendUp: true },
    { title: 'Valor Pipeline', value: 'R$ 1.500,00', trend: '+100%', trendUp: true },
    { title: 'Conversão', value: '8.3%', trend: '+100%', trendUp: true },
    { title: 'Tempo Médio', value: '25 min', trend: '0 min', trendUp: true }
  ]
})
</script>
