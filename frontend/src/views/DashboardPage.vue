<template>
  <div class="flex-1 flex flex-col h-full overflow-hidden bg-slate-50/30 text-left">
    <!-- Header Principal -->
    <header class="h-16 px-6 border-b border-gray-100 flex items-center justify-between shrink-0 bg-white">
      <div class="flex items-center space-x-3">
        <div class="p-2 bg-slate-900 text-white rounded-xl">
          <component :is="LayoutDashboard" class="h-5 w-5" />
        </div>
        <div>
          <h1 class="text-base font-extrabold text-gray-900 tracking-tight">Dashboard Executivo</h1>
          <p class="text-xs text-gray-400">Analise o funil de conversão, metas financeiras e performance de atendimento.</p>
        </div>
      </div>

      <!-- Filtro de Período e Workspace -->
      <div class="flex items-center space-x-4">
        <!-- Período Seletor -->
        <div class="flex bg-slate-100 p-0.5 rounded-xl border border-gray-200">
          <button 
            v-for="p in periods" 
            :key="p.value"
            @click="changePeriod(p.value)"
            type="button"
            class="px-3 py-1.5 rounded-lg text-[10px] font-extrabold uppercase tracking-wider transition-all"
            :class="selectedPeriod === p.value ? 'bg-white text-slate-900 shadow-sm' : 'text-gray-400 hover:text-slate-700'"
          >
            {{ p.label }}
          </button>
        </div>

        <span class="text-xs font-semibold px-3 py-1 bg-slate-100 text-slate-700 rounded-full border border-gray-200">
          {{ workspaceStore.currentWorkspace?.name || 'Workspace' }}
        </span>
      </div>
    </header>

    <!-- Área de Rolagem -->
    <div class="flex-1 overflow-y-auto p-6 space-y-6">
      
      <!-- Banner informativo do WhatsApp (Status de Conexão) -->
      <div 
        v-if="!isWhatsappConnected" 
        class="bg-[#efeae2]/40 border border-[#efeae2] rounded-3xl p-6 flex items-start space-x-4 transition-all duration-200 shadow-sm"
      >
        <div class="p-3 bg-emerald-500 text-white rounded-2xl shadow-sm">
          <component :is="MessageSquare" class="h-6 w-6" />
        </div>
        <div class="flex-1">
          <h3 class="text-xs font-black text-slate-900 uppercase tracking-wider">Conecte seu WhatsApp para habilitar o Broadcast</h3>
          <p class="text-xs text-slate-600 mt-1 leading-normal font-semibold">
            Para realizar campanhas de Transmissão (Broadcast) e enviar mensagens em massa de forma automática, conecte sua conta do WhatsApp via QR Code em Configurações.
          </p>
          <div class="mt-3">
            <button 
              @click="connectWhatsapp"
              class="bg-slate-900 hover:bg-slate-800 text-white text-[10px] font-bold uppercase tracking-wider py-2 px-4 rounded-xl shadow-sm transition-all focus:outline-none"
            >
              Conectar Dispositivo
            </button>
          </div>
        </div>
      </div>

      <!-- Feedback de Conexão WhatsApp Ativa -->
      <div 
        v-else 
        class="bg-emerald-50/50 border border-emerald-100 rounded-3xl p-5 flex items-center justify-between transition-all duration-200 shadow-sm"
      >
        <div class="flex items-center space-x-3">
          <div class="p-2.5 bg-emerald-500 text-white rounded-xl shadow-sm">
            <component :is="MessageSquare" class="h-4.5 w-4.5" />
          </div>
          <div>
            <h4 class="text-xs font-bold text-emerald-950 uppercase tracking-wider">WhatsApp Integrado & Ativo</h4>
            <p class="text-[10px] text-emerald-700 font-semibold mt-0.5">Sincronização operacional no workspace <strong>{{ workspaceStore.currentWorkspace?.name }}</strong>.</p>
          </div>
        </div>
        <button 
          @click="disconnectWhatsapp"
          class="text-[10px] font-bold uppercase tracking-wider text-rose-600 hover:text-rose-700 hover:bg-rose-50 px-3 py-2 rounded-xl transition-all focus:outline-none"
        >
          Desconectar
        </button>
      </div>

      <!-- Row 1: 4 Cards de KPI -->
      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
        <!-- KPI 1: Leads Ativos -->
        <div class="bg-white p-5 rounded-3xl border border-gray-150 shadow-sm flex flex-col justify-between">
          <div class="flex items-start justify-between">
            <div>
              <span class="text-[9px] font-bold text-gray-400 uppercase tracking-wider">Negócios Ativos</span>
              <div class="text-2xl font-black text-gray-900 mt-1.5">
                {{ dashboardStore.loading ? '...' : dashboardStore.kpis.active_leads }}
              </div>
            </div>
            <div class="p-2 bg-slate-50 text-slate-650 rounded-xl">
              <component :is="Users" class="h-4.5 w-4.5" />
            </div>
          </div>
          <div class="mt-4 flex items-center text-[10px] font-bold text-slate-500">
            <span class="text-emerald-600 font-extrabold mr-1">+12%</span>
            <span>em relação ao mês anterior</span>
          </div>
        </div>

        <!-- KPI 2: Valor do Funil -->
        <div class="bg-white p-5 rounded-3xl border border-gray-150 shadow-sm flex flex-col justify-between">
          <div class="flex items-start justify-between">
            <div>
              <span class="text-[9px] font-bold text-gray-400 uppercase tracking-wider">Valor em Negociação</span>
              <div class="text-2xl font-black text-gray-900 mt-1.5">
                {{ dashboardStore.loading ? '...' : formatCurrency(dashboardStore.kpis.pipeline_value) }}
              </div>
            </div>
            <div class="p-2 bg-slate-50 text-slate-650 rounded-xl">
              <component :is="DollarSign" class="h-4.5 w-4.5" />
            </div>
          </div>
          <div class="mt-4 flex items-center text-[10px] font-bold text-slate-500">
            <span class="text-emerald-600 font-extrabold mr-1">+8.4%</span>
            <span>pipeline estendido</span>
          </div>
        </div>

        <!-- KPI 3: Vendas Ganhas -->
        <div class="bg-white p-5 rounded-3xl border border-gray-150 shadow-sm flex flex-col justify-between">
          <div class="flex items-start justify-between">
            <div>
              <span class="text-[9px] font-bold text-gray-400 uppercase tracking-wider">Faturamento Confirmado</span>
              <div class="text-2xl font-black text-emerald-700 mt-1.5">
                {{ dashboardStore.loading ? '...' : formatCurrency(dashboardStore.kpis.won_this_month) }}
              </div>
            </div>
            <div class="p-2 bg-emerald-50 text-emerald-600 rounded-xl">
              <component :is="TrendingUp" class="h-4.5 w-4.5" />
            </div>
          </div>
          <div class="mt-4 flex items-center text-[10px] font-bold text-slate-500">
            <span class="text-emerald-600 font-extrabold mr-1">+14.2%</span>
            <span>este período</span>
          </div>
        </div>

        <!-- KPI 4: Conversão de Leads -->
        <div class="bg-white p-5 rounded-3xl border border-gray-150 shadow-sm flex flex-col justify-between">
          <div class="flex items-start justify-between">
            <div>
              <span class="text-[9px] font-bold text-gray-400 uppercase tracking-wider">Taxa de Conversão</span>
              <div class="text-2xl font-black text-gray-900 mt-1.5">
                {{ dashboardStore.loading ? '...' : dashboardStore.kpis.conversion_rate }}%
              </div>
            </div>
            <div class="p-2 bg-slate-50 text-slate-650 rounded-xl">
              <component :is="Percent" class="h-4.5 w-4.5" />
            </div>
          </div>
          <div class="mt-4 flex items-center text-[10px] font-bold text-slate-500">
            <span class="text-rose-500 font-extrabold mr-1">-1.5%</span>
            <span>média nacional</span>
          </div>
        </div>
      </div>

      <!-- Grid Duplo: Row 2 (Atividades Recentes) + Row 3 (Resumo por Pipeline) -->
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <!-- Row 2: Atividades Recentes -->
        <div class="bg-white border border-gray-150 rounded-3xl p-5 shadow-sm space-y-4">
          <div class="flex items-center justify-between border-b border-gray-100 pb-3">
            <h3 class="text-xs font-bold text-gray-900 uppercase tracking-wider">Histórico de Atividades Recentes</h3>
            <span class="text-[9px] font-bold text-gray-400 uppercase">Ações Live</span>
          </div>

          <div v-if="dashboardStore.loading" class="space-y-3.5">
            <div v-for="i in 5" :key="i" class="h-10 bg-gray-50 rounded-xl animate-pulse"></div>
          </div>

          <div v-else-if="dashboardStore.activities.length === 0" class="text-center py-10 text-xs text-gray-400 italic">
            Nenhuma atividade registrada no período.
          </div>

          <div v-else class="space-y-3 max-h-[300px] overflow-y-auto pr-1">
            <div 
              v-for="act in dashboardStore.activities" 
              :key="act.id"
              class="flex items-start space-x-3 p-2 hover:bg-slate-50/50 rounded-xl transition-all"
            >
              <!-- Ícone por tipo -->
              <span class="text-base p-1.5 bg-slate-100 rounded-lg shrink-0 select-none">
                {{ getActivityIcon(act.type) }}
              </span>
              <div class="min-w-0 flex-1">
                <p class="text-xs text-slate-700 font-semibold leading-normal break-words">{{ act.text }}</p>
                <span class="text-[9px] text-gray-400 font-bold block mt-0.5">{{ formatFriendlyTime(act.created_at) }}</span>
              </div>
            </div>
          </div>
        </div>

        <!-- Row 3: Resumo por Pipeline -->
        <div class="bg-white border border-gray-150 rounded-3xl p-5 shadow-sm space-y-4">
          <div class="flex items-center justify-between border-b border-gray-100 pb-3">
            <h3 class="text-xs font-bold text-gray-900 uppercase tracking-wider">Carga de Trabalho por Pipeline</h3>
            <span class="text-[9px] font-bold text-gray-400 uppercase">Visualização Geral</span>
          </div>

          <div v-if="dashboardStore.loading" class="space-y-4">
            <div v-for="i in 2" :key="i" class="h-28 bg-gray-50 rounded-2xl animate-pulse"></div>
          </div>

          <div v-else-if="dashboardStore.pipelinesSummary.length === 0" class="text-center py-10 text-xs text-gray-400 italic">
            Sem pipelines ativos neste workspace.
          </div>

          <div v-else class="space-y-4">
            <div 
              v-for="pipe in dashboardStore.pipelinesSummary" 
              :key="pipe.id"
              class="p-4 bg-slate-50 border border-gray-150/60 rounded-2xl space-y-2.5"
            >
              <div class="flex justify-between items-center text-xs">
                <span class="font-extrabold text-slate-800">{{ pipe.name }}</span>
                <span class="font-black text-slate-900 bg-white px-2 py-0.5 rounded-md border border-gray-150">
                  {{ pipe.total_leads }} leads
                </span>
              </div>

              <!-- Mini-funil visual proporcional -->
              <div class="h-4 bg-gray-200/60 rounded-lg overflow-hidden flex w-full">
                <div 
                  v-for="(stage, idx) in pipe.stages" 
                  :key="stage.name"
                  class="h-full transition-all duration-500"
                  :class="getStageColor(idx)"
                  :style="{ width: stage.percentage + '%' }"
                  :title="`${stage.name}: ${stage.count} leads (${stage.percentage}%)`"
                ></div>
              </div>

              <!-- Legenda do mini-funil -->
              <div class="flex flex-wrap gap-x-3 gap-y-1 pt-1.5 text-[9px] text-gray-400 font-bold">
                <div 
                  v-for="(stage, idx) in pipe.stages" 
                  :key="stage.name"
                  class="flex items-center space-x-1"
                >
                  <span class="h-1.5 w-1.5 rounded-full shrink-0" :class="getStageColor(idx)"></span>
                  <span class="text-slate-600">{{ stage.name }} ({{ stage.count }})</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Row 4 e 5: Funil de Conversão e Ranking de Agentes -->
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <!-- Gráfico do Funil -->
        <FunnelChart 
          :data="dashboardStore.funnel"
          :loading="dashboardStore.loading"
        />

        <!-- Ranking dos Agentes -->
        <AgentRanking 
          :agents="dashboardStore.agents"
          :loading="dashboardStore.loading"
        />
      </div>

    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useWorkspaceStore } from '@/stores/workspace'
import { useChatwootStore } from '@/stores/chatwoot'
import { useDashboardStore } from '@/stores/dashboard'
import { useToast } from '@/composables/useToast'
import FunnelChart from './dashboard/FunnelChart.vue'
import AgentRanking from './dashboard/AgentRanking.vue'
import { 
  LayoutDashboard, 
  MessageSquare,
  Users, 
  DollarSign, 
  TrendingUp, 
  Percent 
} from 'lucide-vue-next'

const workspaceStore = useWorkspaceStore()
const chatwootStore = useChatwootStore()
const dashboardStore = useDashboardStore()
const toast = useToast()
const router = useRouter()

const selectedPeriod = ref('30d')

const periods = [
  { label: '7 dias', value: '7d' },
  { label: '30 dias', value: '30d' }
]

onMounted(async () => {
  if (!chatwootStore.configured) {
    await chatwootStore.fetchSettings()
  }
  await loadDashboardData()
})

const changePeriod = async (period) => {
  selectedPeriod.value = period
  await loadDashboardData()
}

const loadDashboardData = async () => {
  await dashboardStore.fetchDashboardMetrics(selectedPeriod.value)
}

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

// Formatadores
const formatCurrency = (val) => {
  return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(val || 0)
}

const formatFriendlyTime = (isoString) => {
  if (!isoString) return ''
  const date = new Date(isoString)
  return date.toLocaleDateString('pt-BR') + ' às ' + date.toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' })
}

const getActivityIcon = (type) => {
  switch (type) {
    case 'card_moved': return '🔀'
    case 'card_created': return '✨'
    case 'card_won': return '🏆'
    case 'card_lost': return '😢'
    case 'message_received': return '📩'
    case 'message_sent': return '📤'
    case 'task_created': return '📋'
    default: return '⚡'
  }
}

const getStageColor = (idx) => {
  const colors = [
    'bg-slate-900',
    'bg-slate-700',
    'bg-slate-500',
    'bg-slate-400',
    'bg-slate-300'
  ]
  return colors[idx % colors.length]
}
</script>
