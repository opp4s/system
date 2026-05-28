<template>
  <div class="max-w-4xl mx-auto space-y-6 px-4 sm:px-6 lg:px-8 py-6">
    <!-- Header -->
    <header class="pb-5 border-b border-gray-200">
      <h1 class="text-2xl font-extrabold text-gray-900 tracking-tight flex items-center space-x-2">
        <component :is="MessageSquare" class="h-6 w-6 text-zavy-600" />
        <span>Configuração do WhatsApp</span>
      </h1>
      <p class="text-sm text-gray-500 mt-1">
        Conecte sua conta do Chatwoot para sincronizar conversas do WhatsApp e gerenciar leads em tempo real.
      </p>
    </header>

    <!-- Conteúdo Principal -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
      
      <!-- Painel do Formulário de Conexão -->
      <section class="md:col-span-2 space-y-6">
        <div class="bg-white border border-gray-200 rounded-2xl p-6 shadow-sm space-y-6">
          <header class="flex items-center justify-between pb-3 border-b border-gray-150">
            <h3 class="text-sm font-bold text-gray-800 uppercase tracking-wider">Credenciais do Chatwoot</h3>
            <span 
              class="text-xs px-2.5 py-0.5 rounded-full font-bold flex items-center space-x-1"
              :class="chatwootStore.configured ? 'bg-emerald-50 text-emerald-700' : 'bg-amber-50 text-amber-700'"
            >
              <span class="w-1.5 h-1.5 rounded-full" :class="chatwootStore.configured ? 'bg-emerald-500 animate-ping' : 'bg-amber-500'"></span>
              <span>{{ chatwootStore.configured ? 'Conectado' : 'Aguardando Configuração' }}</span>
            </span>
          </header>

          <form @submit.prevent="testConnection" class="space-y-4">
            <!-- URL do Chatwoot -->
            <div class="space-y-1.5">
              <label class="text-[10px] font-bold text-gray-400 uppercase tracking-wider block">URL da Plataforma</label>
              <input
                type="url"
                v-model="form.chatwootUrl"
                placeholder="Ex: https://chat.opp4s.com"
                required
                class="block w-full px-4 py-2.5 rounded-xl border border-gray-250 focus:outline-none focus:border-zavy-500 focus:ring-1 focus:ring-zavy-500 bg-gray-50/20 text-xs text-gray-800 transition-all"
              />
            </div>

            <!-- Account ID -->
            <div class="space-y-1.5">
              <label class="text-[10px] font-bold text-gray-400 uppercase tracking-wider block">Account ID (ID da Conta)</label>
              <input
                type="text"
                v-model="form.accountId"
                placeholder="Ex: 1"
                required
                class="block w-full px-4 py-2.5 rounded-xl border border-gray-250 focus:outline-none focus:border-zavy-500 focus:ring-1 focus:ring-zavy-500 bg-gray-50/20 text-xs text-gray-800 transition-all"
              />
            </div>

            <!-- API Token -->
            <div class="space-y-1.5">
              <label class="text-[10px] font-bold text-gray-400 uppercase tracking-wider block">Token da API do Agente</label>
              <div class="relative">
                <input
                  :type="showToken ? 'text' : 'password'"
                  v-model="form.apiToken"
                  placeholder="Seu token de acesso pessoal no Chatwoot"
                  required
                  class="block w-full pl-4 pr-10 py-2.5 rounded-xl border border-gray-250 focus:outline-none focus:border-zavy-500 focus:ring-1 focus:ring-zavy-500 bg-gray-50/20 text-xs text-gray-800 transition-all"
                />
                <button
                  type="button"
                  @click="showToken = !showToken"
                  class="absolute inset-y-0 right-0 pr-3 flex items-center text-gray-400 hover:text-gray-600 focus:outline-none"
                >
                  <component :is="showToken ? EyeOff : Eye" class="h-4 w-4" />
                </button>
              </div>
              <p class="text-[10px] text-gray-400 mt-1">Este token é obtido no Chatwoot em Configurações de Perfil > Token de Acesso.</p>
            </div>

            <!-- Botões de Ação -->
            <div class="flex items-center space-x-3 pt-4 border-t border-gray-100 justify-between">
              <button
                v-if="chatwootStore.configured"
                type="button"
                @click="disconnect"
                class="px-4 py-2 text-rose-600 hover:text-rose-700 hover:bg-rose-50 border border-transparent hover:border-rose-200 rounded-xl text-xs font-bold transition-all"
              >
                Desconectar Conta
              </button>
              <div v-else></div>

              <button
                type="submit"
                :disabled="chatwootStore.loading"
                class="flex items-center space-x-2 px-5 py-2.5 bg-slate-900 hover:bg-slate-800 disabled:bg-slate-400 text-white rounded-xl text-xs font-bold shadow-md shadow-slate-900/10 hover:shadow-lg transition-all duration-150"
              >
                <component 
                  :is="chatwootStore.loading ? Loader2 : CheckCircle" 
                  class="h-4 w-4"
                  :class="{'animate-spin': chatwootStore.loading}"
                />
                <span>{{ chatwootStore.loading ? 'Testando Conexão...' : 'Testar & Conectar' }}</span>
              </button>
            </div>
          </form>
        </div>

        <!-- Seção Auto-Link (Disponível apenas se estiver configurado) -->
        <div 
          v-if="chatwootStore.configured" 
          class="bg-white border border-gray-200 rounded-2xl p-6 shadow-sm space-y-5 animate-scale-up"
        >
          <header class="flex items-center space-x-2 pb-3 border-b border-gray-150 text-slate-850">
            <component :is="Zap" class="h-5 w-5 text-zavy-500" />
            <h3 class="text-sm font-bold text-gray-800 uppercase tracking-wider">Distribuição Automática de Leads</h3>
          </header>

          <div class="space-y-4">
            <!-- Toggle Habilitar -->
            <div class="flex items-center justify-between">
              <div>
                <h4 class="text-xs font-bold text-gray-700">Encaminhar Novas Conversas</h4>
                <p class="text-[10px] text-gray-400 mt-0.5">Criar oportunidades automaticamente para novas conversas do WhatsApp.</p>
              </div>
              <button
                @click="autoLinkSettings.autoLinkEnabled = !autoLinkSettings.autoLinkEnabled"
                class="relative inline-flex h-6 w-11 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none focus:ring-2 focus:ring-slate-900 focus:ring-offset-2"
                :class="autoLinkSettings.autoLinkEnabled ? 'bg-slate-900' : 'bg-gray-200'"
              >
                <span
                  class="pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out"
                  :class="autoLinkSettings.autoLinkEnabled ? 'translate-x-5' : 'translate-x-0'"
                ></span>
              </button>
            </div>

            <!-- Inputs Destino se Habilitado -->
            <transition
              enter-active-class="transition duration-200 ease-out"
              enter-from-class="transform -translate-y-2 opacity-0"
              enter-to-class="transform translate-y-0 opacity-100"
              leave-active-class="transition duration-150 ease-in"
              leave-from-class="transform translate-y-0 opacity-100"
              leave-to-class="transform -translate-y-2 opacity-0"
            >
              <div v-if="autoLinkSettings.autoLinkEnabled" class="grid grid-cols-1 sm:grid-cols-2 gap-4 pt-2">
                <!-- Selecionar Funil -->
                <div class="space-y-1.5">
                  <label class="text-[10px] font-bold text-gray-400 uppercase tracking-wider block">Funil (Pipeline) de Destino</label>
                  <select
                    v-model="autoLinkSettings.destinationPipelineId"
                    @change="onPipelineChange"
                    class="block w-full px-3 py-2 rounded-xl border border-gray-250 focus:outline-none focus:border-zavy-500 focus:ring-1 focus:ring-zavy-500 bg-gray-50/30 text-xs text-gray-800 transition-all"
                  >
                    <option :value="null" disabled>Selecione um funil...</option>
                    <option v-for="pipeline in pipelineStore.pipelines" :key="pipeline.id" :value="pipeline.id">
                      {{ pipeline.name }}
                    </option>
                  </select>
                </div>

                <!-- Selecionar Etapa -->
                <div class="space-y-1.5">
                  <label class="text-[10px] font-bold text-gray-400 uppercase tracking-wider block">Etapa do Funil</label>
                  <select
                    v-model="autoLinkSettings.destinationStageId"
                    :disabled="!autoLinkSettings.destinationPipelineId"
                    class="block w-full px-3 py-2 rounded-xl border border-gray-250 focus:outline-none focus:border-zavy-500 focus:ring-1 focus:ring-zavy-500 bg-gray-50/30 text-xs text-gray-800 transition-all disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    <option :value="null" disabled>Selecione uma etapa...</option>
                    <option v-for="stage in availableStages" :key="stage.id" :value="stage.id">
                      {{ stage.name }}
                    </option>
                  </select>
                </div>
              </div>
            </transition>

            <!-- Botão Salvar Configurações de Roteamento -->
            <div class="flex justify-end pt-3 border-t border-gray-100">
              <button
                @click="saveRoutingSettings"
                :disabled="chatwootStore.loading || (autoLinkSettings.autoLinkEnabled && (!autoLinkSettings.destinationPipelineId || !autoLinkSettings.destinationStageId))"
                class="flex items-center space-x-1.5 px-4 py-2 bg-slate-900 hover:bg-slate-800 disabled:bg-slate-300 text-white font-bold rounded-xl text-xs shadow-md shadow-slate-900/10 transition-all"
              >
                <component :is="Check" class="h-3.5 w-3.5" />
                <span>Salvar Configurações</span>
              </button>
            </div>
          </div>
        </div>
      </section>

      <!-- Instruções na Lateral Direita -->
      <section class="space-y-6">
        <div class="bg-slate-50 border border-gray-200 rounded-2xl p-5 shadow-sm space-y-4">
          <h4 class="text-xs font-extrabold text-slate-850 uppercase tracking-wider flex items-center space-x-1.5">
            <component :is="Info" class="h-4 w-4 text-zavy-500 shrink-0" />
            <span>Como Configurar?</span>
          </h4>
          
          <ul class="text-xs text-gray-600 space-y-3 list-decimal pl-4 leading-relaxed">
            <li>
              Acesse o painel do seu Chatwoot (URL: <a href="https://chat.opp4s.com" target="_blank" class="text-zavy-600 font-semibold hover:underline">chat.opp4s.com</a>) e faça login.
            </li>
            <li>
              Clique na sua foto de perfil no canto inferior esquerdo e vá em <strong>Configurações do Perfil</strong>.
            </li>
            <li>
              Role a página até o final e copie a sequência de caracteres em <strong>Token de Acesso</strong>.
            </li>
            <li>
              Insira o token copiado e o <strong>ID da sua Conta</strong> nos campos ao lado para autenticar a conexão.
            </li>
          </ul>
        </div>
      </section>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted, watch } from 'vue'
import { useChatwootStore } from '@/stores/chatwoot'
import { usePipelineStore } from '@/stores/pipeline'
import { useToast } from '@/composables/useToast'
import { 
  MessageSquare, 
  Eye, 
  EyeOff, 
  Loader2, 
  CheckCircle,
  Zap,
  Info,
  Check,
  X
} from 'lucide-vue-next'

const chatwootStore = useChatwootStore()
const pipelineStore = usePipelineStore()
const toast = useToast()

const showToken = ref(false)

// Estado local do form
const form = reactive({
  chatwootUrl: chatwootStore.chatwootUrl || 'https://chat.opp4s.com',
  accountId: chatwootStore.accountId || '',
  apiToken: chatwootStore.apiToken || ''
})

// Configurações de Roteamento Automático
const autoLinkSettings = reactive({
  autoLinkEnabled: chatwootStore.autoLinkEnabled,
  destinationPipelineId: chatwootStore.destinationPipelineId,
  destinationStageId: chatwootStore.destinationStageId
})

const availableStages = ref([])

onMounted(async () => {
  await chatwootStore.fetchSettings()
  await pipelineStore.fetchPipelines()
  
  // Atualiza local state com o que foi carregado da store
  form.chatwootUrl = chatwootStore.chatwootUrl
  form.accountId = chatwootStore.accountId
  form.apiToken = chatwootStore.apiToken
  
  autoLinkSettings.autoLinkEnabled = chatwootStore.autoLinkEnabled
  autoLinkSettings.destinationPipelineId = chatwootStore.destinationPipelineId
  autoLinkSettings.destinationStageId = chatwootStore.destinationStageId
  
  if (autoLinkSettings.destinationPipelineId) {
    await loadStagesForPipeline(autoLinkSettings.destinationPipelineId)
  }
})

// Observa mudança de pipeline
const onPipelineChange = async () => {
  autoLinkSettings.destinationStageId = null
  if (autoLinkSettings.destinationPipelineId) {
    await loadStagesForPipeline(autoLinkSettings.destinationPipelineId)
  } else {
    availableStages.value = []
  }
}

const loadStagesForPipeline = async (pipelineId) => {
  await pipelineStore.fetchStages(pipelineId)
  availableStages.value = pipelineStore.stages
}

const testConnection = async () => {
  if (!form.chatwootUrl.trim() || !form.accountId.trim() || !form.apiToken.trim()) {
    toast.error('Por favor, preencha todos os campos.')
    return
  }

  try {
    const result = await chatwootStore.configureChatwoot({
      chatwootUrl: form.chatwootUrl,
      accountId: form.accountId,
      apiToken: form.apiToken
    })
    
    if (result.success) {
      toast.success(result.message)
    }
  } catch (e) {
    toast.error('Falha ao conectar com o Chatwoot. Verifique as credenciais.')
  }
}

const saveRoutingSettings = async () => {
  try {
    await chatwootStore.updateSettings({
      autoLinkEnabled: autoLinkSettings.autoLinkEnabled,
      destinationPipelineId: autoLinkSettings.destinationPipelineId,
      destinationStageId: autoLinkSettings.destinationStageId
    })
    toast.success('Configurações de distribuição atualizadas!')
  } catch (e) {
    toast.error('Erro ao atualizar configurações de distribuição.')
  }
}

const disconnect = async () => {
  if (!confirm('Tem certeza de que deseja desconectar o Chatwoot? A sincronização de mensagens será interrompida.')) return
  
  try {
    await chatwootStore.disconnectChatwoot()
    form.accountId = ''
    form.apiToken = ''
    autoLinkSettings.autoLinkEnabled = false
    autoLinkSettings.destinationPipelineId = null
    autoLinkSettings.destinationStageId = null
    toast.warning('Chatwoot desconectado.')
  } catch (e) {
    toast.error('Erro ao desconectar.')
  }
}
</script>

<style scoped>
@keyframes scaleUp {
  from {
    opacity: 0;
    transform: scale(0.97);
  }
  to {
    opacity: 1;
    transform: scale(1);
  }
}
.animate-scale-up {
  animation: scaleUp 0.15s cubic-bezier(0.16, 1, 0.3, 1) forwards;
}
</style>
