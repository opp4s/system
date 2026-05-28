<template>
  <div class="flex-1 flex flex-col h-full overflow-hidden bg-slate-50/30">
    <!-- Header Principal -->
    <header class="h-16 px-6 border-b border-gray-100 flex items-center justify-between shrink-0 bg-white">
      <div class="flex items-center space-x-3">
        <div class="p-2 bg-violet-50 text-violet-650 rounded-xl">
          <component :is="Zap" class="h-5 w-5 animate-pulse" />
        </div>
        <div>
          <h1 class="text-base font-extrabold text-gray-900 tracking-tight">Automações Comerciais</h1>
          <p class="text-xs text-gray-400">Automatize tarefas, mensagens e movimentações baseadas em eventos.</p>
        </div>
      </div>

      <!-- Seletor de Pipeline e Nova Automação -->
      <div class="flex items-center space-x-3">
        <!-- Pipeline Select -->
        <div class="flex items-center space-x-2 text-xs">
          <span class="text-gray-400 font-medium">Funil ativo:</span>
          <select
            v-model="selectedPipelineId"
            @change="onPipelineChange"
            class="block px-3 py-1.5 rounded-xl border border-gray-200 bg-white focus:outline-none focus:border-slate-800 text-xs font-bold text-gray-800 transition-all shadow-sm"
          >
            <option 
              v-for="pipe in pipelineStore.pipelines" 
              :key="pipe.id" 
              :value="pipe.id"
            >
              {{ pipe.name }}
            </option>
          </select>
        </div>

        <button
          @click="openNewAutomation"
          type="button"
          class="px-4 py-2 bg-slate-900 hover:bg-slate-800 text-white rounded-xl text-xs font-bold shadow transition-all flex items-center space-x-1.5"
        >
          <component :is="Plus" class="h-3.5 w-3.5" />
          <span>Nova Automação</span>
        </button>
      </div>
    </header>

    <!-- Área de Conteúdo Principal -->
    <div class="flex-1 overflow-y-auto p-6">
      <div v-if="automationStore.loading.list" class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div v-for="i in 4" :key="i" class="h-44 bg-white border border-gray-150 rounded-3xl animate-pulse"></div>
      </div>

      <div 
        v-else-if="automationStore.automations.length === 0" 
        class="h-full flex flex-col items-center justify-center text-center text-sm text-gray-400 py-16 bg-white rounded-3xl border border-dashed border-gray-200"
      >
        <component :is="Zap" class="h-12 w-12 text-gray-300 mb-3" />
        <span class="font-semibold text-gray-700">Nenhuma automação configurada</span>
        <span class="text-xs text-gray-400 mt-1 max-w-xs">Crie regras de automação para mover cards ou enviar WhatsApp automaticamente neste funil.</span>
        <button
          @click="openNewAutomation"
          type="button"
          class="mt-4 px-4 py-2 border border-slate-900 hover:bg-slate-50 text-slate-900 rounded-xl text-xs font-bold transition-all"
        >
          Criar Primeira Automação
        </button>
      </div>

      <!-- Grid de Automações -->
      <div v-else class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div 
          v-for="auto in automationStore.automations" 
          :key="auto.id"
          class="bg-white border border-gray-150 rounded-3xl p-5 shadow-sm hover:shadow-md hover:border-gray-250 transition-all flex flex-col relative group"
        >
          <!-- Topo do Card (Nome, Ativo Toggle) -->
          <div class="flex items-start justify-between space-x-3 mb-3.5">
            <div class="min-w-0">
              <h3 class="text-xs font-bold text-gray-900 leading-snug group-hover:text-violet-650 transition-colors truncate">
                {{ auto.name }}
              </h3>
              <p class="text-[10px] text-gray-400 mt-0.5 font-medium">ID: #{{ auto.id }}</p>
            </div>

            <!-- Toggle Ativo/Inativo -->
            <button
              @click="toggleActive(auto.id)"
              :disabled="automationStore.loading.mutation"
              class="relative inline-flex h-5 w-9 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-150 ease-in-out focus:outline-none disabled:opacity-50"
              :class="auto.active ? 'bg-slate-950' : 'bg-gray-200'"
            >
              <span
                class="pointer-events-none inline-block h-4 w-4 transform rounded-full bg-white shadow ring-0 transition duration-150 ease-in-out"
                :class="auto.active ? 'translate-x-4' : 'translate-x-0'"
              ></span>
            </button>
          </div>

          <!-- Gatilho (Trigger) -->
          <div class="bg-slate-550/5 bg-slate-50 border border-gray-150/50 rounded-2xl p-3 flex items-start space-x-2.5 text-xs text-slate-700 mb-4">
            <span class="text-base shrink-0 select-none">{{ getTriggerIcon(auto.trigger_type) }}</span>
            <div class="min-w-0">
              <span class="font-bold text-slate-800 text-[10px] uppercase tracking-wider block leading-none mb-1">Gatilho (Trigger)</span>
              <span class="font-medium text-gray-650 leading-relaxed">{{ getTriggerText(auto.trigger_type, auto.trigger_config) }}</span>
            </div>
          </div>

          <!-- Ações Resumidas (Icons) -->
          <div class="space-y-1.5 mb-5 flex-1">
            <span class="text-[9px] font-bold text-gray-400 uppercase tracking-wider block">Ações Executadas</span>
            <div class="flex flex-wrap gap-1.5">
              <span 
                v-for="act in auto.actions" 
                :key="act.id"
                class="inline-flex items-center space-x-1 px-2.5 py-1 rounded-xl text-[10px] font-bold shadow-sm transition-all"
                :class="getActionBadgeColor(act.action_type)"
                :title="getActionTypeLabel(act.action_type)"
              >
                <span>{{ getActionIcon(act.action_type) }}</span>
                <span>{{ getActionTypeLabel(act.action_type) }}</span>
              </span>
            </div>
          </div>

          <!-- Rodapé do Card (Métricas, Controles rápidos) -->
          <footer class="pt-3 border-t border-gray-100 flex items-center justify-between text-[10px] text-gray-400 shrink-0">
            <div class="flex items-center space-x-3 font-semibold">
              <span :title="auto.last_triggered_at ? `Último disparo: ${formatFriendlyTime(auto.last_triggered_at)}` : 'Nunca disparado'">
                Disparo: {{ auto.last_triggered_at ? formatShortDate(auto.last_triggered_at) : 'Nunca' }}
              </span>
              <span>•</span>
              <span>Execuções: <strong class="text-gray-700">{{ auto.trigger_count }}</strong></span>
            </div>

            <!-- Botões Rápidos -->
            <div class="flex items-center space-x-1.5 opacity-80 group-hover:opacity-100 transition-opacity">
              <button 
                @click="openLogs(auto)" 
                type="button" 
                class="px-2 py-1 text-slate-700 hover:text-slate-900 hover:bg-gray-100 border border-gray-200 rounded-lg font-bold transition-all"
                title="Histórico de Execuções"
              >
                Histórico
              </button>
              <button 
                @click="duplicateAuto(auto.id)" 
                type="button" 
                class="p-1 text-slate-500 hover:text-slate-800 hover:bg-gray-100 rounded-lg transition-colors"
                title="Duplicar"
              >
                <component :is="Copy" class="h-3.5 w-3.5" />
              </button>
              <button 
                @click="editAuto(auto)" 
                type="button" 
                class="p-1 text-slate-500 hover:text-slate-800 hover:bg-gray-100 rounded-lg transition-colors"
                title="Editar"
              >
                <component :is="Edit2" class="h-3.5 w-3.5" />
              </button>
              <button 
                @click="deleteAuto(auto.id)" 
                type="button" 
                class="p-1 text-rose-500 hover:text-rose-700 hover:bg-rose-50 rounded-lg transition-colors"
                title="Excluir"
              >
                <component :is="Trash2" class="h-3.5 w-3.5" />
              </button>
            </div>
          </footer>
        </div>
      </div>
    </div>

    <!-- Drawer de Logs de Automação (Slide-in) -->
    <transition name="slide-panel">
      <div v-if="selectedAutoForLogs" class="fixed inset-0 z-40 flex justify-end">
        <!-- Backdrop -->
        <div 
          @click="closeLogs"
          class="absolute inset-0 bg-slate-900/40 backdrop-blur-sm transition-opacity duration-300"
        ></div>

        <!-- Painel lateral (Logs) -->
        <div class="relative w-full max-w-lg h-full bg-white shadow-2xl flex flex-col z-10 animate-slide-in-right">
          <!-- Header do Painel -->
          <header class="h-16 px-6 border-b border-gray-100 flex items-center justify-between shrink-0 bg-gray-50/50">
            <div>
              <span class="text-xs font-bold text-gray-400 uppercase tracking-wider block">Histórico de Disparos</span>
              <h2 class="text-xs font-bold text-gray-800 truncate max-w-[280px] mt-0.5">{{ selectedAutoForLogs.name }}</h2>
            </div>
            <button 
              @click="closeLogs"
              class="p-2 text-gray-400 hover:text-gray-650 hover:bg-gray-150 rounded-xl transition-all"
            >
              <component :is="X" class="h-4 w-4" />
            </button>
          </header>

          <!-- Corpo dos Logs -->
          <div class="flex-1 overflow-y-auto p-6 space-y-4">
            <div v-if="automationStore.loading.logs" class="space-y-3">
              <div v-for="i in 3" :key="i" class="h-20 bg-gray-50 rounded-2xl animate-pulse"></div>
            </div>

            <div v-else-if="automationStore.logs.length === 0" class="text-center py-12 text-xs text-gray-400 italic">
              Nenhum disparo registrado para esta automação.
            </div>

            <div v-else class="space-y-3">
              <div 
                v-for="log in automationStore.logs" 
                :key="log.id"
                class="p-4 rounded-2xl border flex flex-col space-y-2 shadow-sm transition-all"
                :class="log.status === 'success' ? 'bg-white border-gray-150' : 'bg-rose-50/10 border-rose-100'"
              >
                <!-- Topo Log -->
                <div class="flex items-center justify-between text-[9px] font-bold">
                  <span class="text-gray-400">{{ formatFriendlyTime(log.created_at) }}</span>
                  <span 
                    class="px-2 py-0.5 rounded-full font-bold uppercase tracking-wider"
                    :class="log.status === 'success' ? 'bg-emerald-50 text-emerald-700' : 'bg-rose-550/15 text-rose-700'"
                  >
                    {{ log.status === 'success' ? 'Sucesso' : 'Falha' }}
                  </span>
                </div>

                <!-- Card Relacionado -->
                <div class="text-xs font-semibold text-gray-850 flex items-center space-x-1.5">
                  <component :is="Briefcase" class="h-3.5 w-3.5 text-gray-400" />
                  <span>Negócio:</span>
                  <a 
                    @click.prevent="goToCard(log.card_id)"
                    href="#" 
                    class="text-violet-650 hover:underline font-bold"
                  >
                    {{ log.card_title || `Lead #${log.card_id}` }}
                  </a>
                </div>

                <!-- Detalhe das Ações -->
                <div class="pt-1.5 border-t border-dashed border-gray-100 space-y-1.5">
                  <div 
                    v-for="(summary, idx) in log.actions_summary" 
                    :key="idx"
                    class="text-[10px] leading-relaxed text-gray-600 font-medium"
                  >
                    {{ summary }}
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Footer da Drawer -->
          <footer class="h-16 px-6 border-t border-gray-100 flex items-center justify-end shrink-0 bg-gray-50/50">
            <button 
              type="button" 
              @click="closeLogs"
              class="px-4 py-2 border border-gray-250 text-gray-650 rounded-xl text-xs font-semibold hover:bg-gray-100 transition-colors"
            >
              Fechar
            </button>
          </footer>
        </div>
      </div>
    </transition>

    <!-- Modal Provisório para Indicação do Editor -->
    <div v-if="showEditorPlaceholder" class="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div @click="showEditorPlaceholder = false" class="absolute inset-0 bg-slate-900/60 backdrop-blur-sm"></div>
      <div class="relative bg-white rounded-3xl shadow-2xl max-w-sm w-full p-6 z-10 animate-scale-up border border-gray-100 text-center space-y-4">
        <div class="h-12 w-12 rounded-full bg-violet-50 text-violet-650 flex items-center justify-center mx-auto">
          <component :is="Zap" class="h-6 w-6 animate-bounce" />
        </div>
        <div>
          <h3 class="text-base font-extrabold text-gray-900">Editor de Automação</h3>
          <p class="text-xs text-gray-400 mt-1">O Construtor Visual de Automações em Etapas (Triggers, Conditions, Actions) será totalmente implementado a partir do Dia 17.</p>
        </div>
        <button 
          @click="showEditorPlaceholder = false" 
          type="button"
          class="w-full py-2.5 bg-slate-900 hover:bg-slate-800 text-white rounded-xl text-xs font-bold transition-colors"
        >
          Entendido
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useAutomationStore } from '@/stores/automation'
import { usePipelineStore } from '@/stores/pipeline'
import { useToast } from '@/composables/useToast'
import { 
  Zap, 
  Plus, 
  Trash2, 
  Copy, 
  Edit2, 
  X, 
  Loader2, 
  Briefcase,
  AlertCircle
} from 'lucide-vue-next'

const router = useRouter()
const automationStore = useAutomationStore()
const pipelineStore = usePipelineStore()
const toast = useToast()

const selectedPipelineId = ref(null)
const selectedAutoForLogs = ref(null)
const showEditorPlaceholder = ref(false)

onMounted(async () => {
  // Sincroniza pipelines e etapas se a store de pipelines estiver vazia
  if (pipelineStore.pipelines.length === 0) {
    await pipelineStore.fetchPipelines()
  }
  
  // Define o pipeline ativo inicial na interface
  selectedPipelineId.value = pipelineStore.currentPipelineId || (pipelineStore.pipelines[0]?.id || null)
  
  if (selectedPipelineId.value) {
    await loadAutomations()
  }
})

// Recarrega as automações baseadas no pipeline selecionado
const loadAutomations = async () => {
  if (selectedPipelineId.value) {
    await automationStore.fetchAutomations(selectedPipelineId.value)
  }
}

const onPipelineChange = async () => {
  // Atualiza o pipeline atual na store de pipelines para consistência
  if (selectedPipelineId.value) {
    pipelineStore.currentPipelineId = selectedPipelineId.value
    await pipelineStore.fetchStages(selectedPipelineId.value)
    await loadAutomations()
  }
}

// Alternar status ativo/inativo
const toggleActive = async (id) => {
  try {
    const updated = await automationStore.toggleAutomation(selectedPipelineId.value, id)
    toast.success(updated.active ? 'Automação ativada!' : 'Automação pausada.')
  } catch (error) {
    toast.error('Erro ao atualizar status da automação.')
  }
}

// Duplicar automação
const duplicateAuto = async (id) => {
  try {
    const copy = await automationStore.duplicateAutomation(selectedPipelineId.value, id)
    if (copy) {
      toast.success('Automação duplicada com sucesso!')
    }
  } catch (error) {
    toast.error('Erro ao duplicar automação.')
  }
}

// Excluir automação com confirmação nativa
const deleteAuto = async (id) => {
  if (!confirm('Tem certeza de que deseja excluir permanentemente esta automação?')) return

  try {
    await automationStore.deleteAutomation(selectedPipelineId.value, id)
    toast.warning('Automação excluída.')
  } catch (error) {
    toast.error('Erro ao deletar automação.')
  }
}

// Abre Logs Drawer
const openLogs = async (auto) => {
  selectedAutoForLogs.value = auto
  await automationStore.fetchLogs(selectedPipelineId.value, auto.id)
}

const closeLogs = () => {
  selectedAutoForLogs.value = null
  automationStore.logs = []
}

// Redireciona o usuário para abrir o card de detalhes do negócio a partir dos logs
const goToCard = (cardId) => {
  closeLogs()
  router.push({
    name: 'card-detail',
    params: {
      id: selectedPipelineId.value,
      cardId: cardId
    }
  })
}

// Nova Automação / Editar (Placeholders provisórios para o Dia 16)
const openNewAutomation = () => {
  showEditorPlaceholder.value = true
}

const editAuto = (auto) => {
  showEditorPlaceholder.value = true
}

// Helpers Formatação & UI
const getTriggerIcon = (type) => {
  switch (type) {
    case 'card_created': return '➕'
    case 'card_enters_stage': return '🎯'
    case 'time_in_stage': return '⏰'
    case 'card_updated': return '✏️'
    default: return '⚙️'
  }
}

const getTriggerText = (type, config) => {
  switch (type) {
    case 'card_created':
      return 'Quando um novo card for criado no pipeline'
    case 'card_enters_stage': {
      const stageName = getStageName(config?.stage_id)
      return `Quando um card for movido para a etapa: "${stageName}"`
    }
    case 'time_in_stage': {
      const stageName = getStageName(config?.stage_id)
      return `Quando um card ficar estagnado por mais de ${config?.days || 0} dias na etapa: "${stageName}"`
    }
    case 'card_updated':
      return `Quando o campo "${config?.field || 'específico'}" do card for alterado`
    default:
      return 'Gatilho de execução automática'
  }
}

const getStageName = (stageId) => {
  const stage = pipelineStore.stages.find(s => s.id === stageId)
  return stage ? stage.name : `Etapa #${stageId}`
}

const getActionIcon = (type) => {
  switch (type) {
    case 'send_whatsapp': return '💬'
    case 'create_task': return '📋'
    case 'move_card': return '🔀'
    case 'assign_agent': return '👤'
    case 'webhook': return '🔗'
    case 'update_field': return '✏️'
    default: return '⚙'
  }
}

const getActionTypeLabel = (type) => {
  switch (type) {
    case 'send_whatsapp': return 'WhatsApp'
    case 'create_task': return 'Criar Tarefa'
    case 'move_card': return 'Mover Negócio'
    case 'assign_agent': return 'Atribuir Agente'
    case 'webhook': return 'Webhook API'
    case 'update_field': return 'Atualizar Campo'
    default: return 'Ação'
  }
}

const getActionBadgeColor = (type) => {
  switch (type) {
    case 'send_whatsapp': return 'bg-emerald-50 text-emerald-700 border border-emerald-100 hover:bg-emerald-100'
    case 'create_task': return 'bg-blue-50 text-blue-700 border border-blue-100 hover:bg-blue-100'
    case 'move_card': return 'bg-amber-50 text-amber-700 border border-amber-100 hover:bg-amber-100'
    case 'assign_agent': return 'bg-purple-50 text-purple-700 border border-purple-100 hover:bg-purple-100'
    case 'webhook': return 'bg-slate-50 text-slate-700 border border-slate-200 hover:bg-slate-100'
    case 'update_field': return 'bg-pink-50 text-pink-700 border border-pink-100 hover:bg-pink-100'
    default: return 'bg-gray-50 text-gray-700 border border-gray-200 hover:bg-gray-100'
  }
}

const formatShortDate = (isoString) => {
  if (!isoString) return ''
  const date = new Date(isoString)
  const day = date.getDate().toString().padStart(2, '0')
  const month = (date.getMonth() + 1).toString().padStart(2, '0')
  return `${day}/${month}`
}

const formatFriendlyTime = (isoString) => {
  if (!isoString) return ''
  const date = new Date(isoString)
  const hours = date.getHours().toString().padStart(2, '0')
  const minutes = date.getMinutes().toString().padStart(2, '0')
  return `${date.toLocaleDateString('pt-BR')} às ${hours}:${minutes}`
}
</script>

<style scoped>
@keyframes slideInRight {
  from {
    transform: translateX(100%);
  }
  to {
    transform: translateX(0);
  }
}
.animate-slide-in-right {
  animation: slideInRight 0.25s cubic-bezier(0.16, 1, 0.3, 1) forwards;
}

@keyframes scaleUp {
  from {
    opacity: 0;
    transform: scale(0.96);
  }
  to {
    opacity: 1;
    transform: scale(1);
  }
}
.animate-scale-up {
  animation: scaleUp 0.16s cubic-bezier(0.16, 1, 0.3, 1) forwards;
}
</style>
