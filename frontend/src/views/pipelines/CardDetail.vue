<template>
  <div class="fixed inset-0 z-50 flex justify-end">
    <!-- Backdrop de Fundo -->
    <div 
      @click="closeDetail"
      class="absolute inset-0 bg-slate-900/40 backdrop-blur-sm transition-opacity duration-300"
    ></div>

    <!-- Painel Slide-in Lateral -->
    <div 
      class="relative w-full max-w-4xl h-full bg-white shadow-2xl flex flex-col z-10 animate-slide-in-right transition-transform duration-300"
    >
      <!-- Header do Slide-in -->
      <header class="h-16 px-6 border-b border-gray-100 flex items-center justify-between shrink-0 bg-gray-50/50">
        <div class="flex items-center space-x-3">
          <span class="px-2.5 py-1 text-xs font-bold bg-slate-950 text-white rounded-lg">Negócio #{{ cardId }}</span>
          <span class="text-gray-400">/</span>
          <span class="text-sm font-semibold text-gray-500">Detalhes do Lead</span>
        </div>

        <button 
          @click="closeDetail"
          class="p-2 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-xl transition-all duration-150"
        >
          <component :is="X" class="h-5 w-5" />
        </button>
      </header>

      <!-- Corpo do Detalhe (Duas colunas: Dados e Timeline) -->
      <div v-if="card" class="flex-1 flex overflow-hidden">
        <!-- Coluna Esquerda: Dados do Card (Painel de 320px) -->
        <aside class="w-80 border-r border-gray-100 overflow-y-auto p-6 flex flex-col space-y-6 bg-gray-50/30">
          <!-- Título do negócio -->
          <div>
            <label class="text-[10px] font-bold text-gray-400 uppercase tracking-wider">Título do Negócio</label>
            <h2 class="text-lg font-bold text-gray-900 mt-1">{{ card.title }}</h2>
          </div>

          <!-- Estágio Atual -->
          <div>
            <label class="text-[10px] font-bold text-gray-400 uppercase tracking-wider">Etapa do Funil</label>
            <div class="mt-1.5 flex items-center space-x-2 px-3 py-2 bg-white border border-gray-200 rounded-xl">
              <span class="w-2.5 h-2.5 rounded-full" :style="{ backgroundColor: stageColor }"></span>
              <span class="text-sm font-bold text-gray-700">{{ stageName }}</span>
            </div>
          </div>

          <!-- Valor e Moeda -->
          <div>
            <label class="text-[10px] font-bold text-gray-400 uppercase tracking-wider">Valor da Oportunidade</label>
            <div class="text-xl font-extrabold text-gray-900 mt-1">
              {{ formatCurrency(card.value, card.currency) }}
            </div>
          </div>

          <!-- Separador -->
          <div class="border-t border-gray-100"></div>

          <!-- Dados do Contato Principal -->
          <div class="space-y-4">
            <h3 class="text-xs font-bold text-gray-800 uppercase tracking-wider">Contato Principal</h3>
            
            <div>
              <label class="text-[10px] font-bold text-gray-400 uppercase">Nome</label>
              <div class="text-sm font-semibold text-gray-800 mt-0.5">{{ card.contact_name || 'Não informado' }}</div>
            </div>

            <div>
              <label class="text-[10px] font-bold text-gray-400 uppercase">Telefone</label>
              <div class="text-sm font-medium text-gray-800 mt-0.5">{{ card.contact_phone || 'Não informado' }}</div>
            </div>

            <div>
              <label class="text-[10px] font-bold text-gray-400 uppercase">E-mail</label>
              <div class="text-sm font-medium text-gray-800 mt-0.5 break-all">{{ card.contact_email || 'Não informado' }}</div>
            </div>
          </div>

          <!-- Separador -->
          <div class="border-t border-gray-100"></div>

          <!-- Campos Personalizados (Custom Fields) -->
          <div class="space-y-4">
            <h3 class="text-xs font-bold text-gray-800 uppercase tracking-wider">Campos Personalizados</h3>
            
            <div 
              v-for="(val, key) in card.custom_fields" 
              :key="key"
              class="bg-white p-2.5 rounded-xl border border-gray-150"
            >
              <label class="text-[10px] font-bold text-gray-400 uppercase block">{{ key }}</label>
              <span class="text-xs font-medium text-gray-700 block mt-0.5">{{ val }}</span>
            </div>
            
            <div v-if="!Object.keys(card.custom_fields || {}).length" class="text-xs text-gray-400 italic">
              Nenhum campo personalizado cadastrado.
            </div>
          </div>
        </aside>

        <!-- Coluna Direita / Centro: Timeline e Comentários -->
        <section class="flex-1 flex flex-col bg-white overflow-hidden">
          <!-- Timeline Area -->
          <div class="flex-1 overflow-y-auto p-6 space-y-6">
            <div class="flex items-center justify-between">
              <h3 class="text-sm font-bold text-gray-800 uppercase tracking-wider">Histórico de Atividades</h3>
              <span class="text-xs text-gray-400">Dados simulados (Dia 8)</span>
            </div>

            <!-- Lista de Atividades do Negócio -->
            <div class="relative pl-6 border-l-2 border-slate-100 space-y-6">
              <!-- Item 1: Criação -->
              <div class="relative">
                <span class="absolute -left-[31px] top-1.5 bg-slate-900 text-white rounded-full p-1 border-2 border-white">
                  <component :is="Plus" class="h-3 w-3" />
                </span>
                <div class="bg-gray-50 border border-gray-100 rounded-2xl p-4">
                  <div class="flex items-center justify-between">
                    <span class="text-xs font-bold text-gray-800">Negócio criado</span>
                    <span class="text-[10px] text-gray-400">Há 3 dias</span>
                  </div>
                  <p class="text-xs text-gray-600 mt-1">O negócio foi inserido no pipeline no estágio inicial.</p>
                </div>
              </div>

              <!-- Item 2: Movimentação -->
              <div class="relative">
                <span class="absolute -left-[31px] top-1.5 bg-zavy-500 text-white rounded-full p-1 border-2 border-white">
                  <component :is="MoveRight" class="h-3 w-3" />
                </span>
                <div class="bg-gray-50 border border-gray-100 rounded-2xl p-4">
                  <div class="flex items-center justify-between">
                    <span class="text-xs font-bold text-gray-800">Movido de etapa</span>
                    <span class="text-[10px] text-gray-400">Ontem</span>
                  </div>
                  <p class="text-xs text-gray-600 mt-1">
                    Negócio avançado para o estágio <strong class="text-gray-800">{{ stageName }}</strong> por João Agente.
                  </p>
                </div>
              </div>
            </div>
          </div>

          <!-- Compositor de Mensagens / Notas (Footer placeholder) -->
          <footer class="p-4 border-t border-gray-150 bg-gray-50/50">
            <div class="flex items-center space-x-2">
              <input 
                type="text" 
                placeholder="Escreva uma nota interna ou envie mensagem..." 
                disabled
                class="flex-1 bg-white border border-gray-200 rounded-xl px-4 py-2.5 text-sm focus:outline-none cursor-not-allowed opacity-60" 
              />
              <button 
                disabled 
                class="p-2.5 bg-slate-900 text-white rounded-xl cursor-not-allowed opacity-50"
              >
                <component :is="Send" class="h-4 w-4" />
              </button>
            </div>
            <p class="text-[10px] text-center text-gray-400 mt-1.5">
              Composer de mensagens funcional a partir do Sprint 3 (Canais de Chat).
            </p>
          </footer>
        </section>
      </div>

      <!-- Loader caso o card esteja sendo carregado -->
      <div v-else class="flex-1 flex items-center justify-center">
        <span class="text-sm text-gray-500">Buscando informações do card...</span>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { usePipelineStore } from '@/stores/pipeline'
import { X, Plus, MoveRight, Send } from 'lucide-vue-next'

const route = useRoute()
const router = useRouter()
const pipelineStore = usePipelineStore()

const cardId = computed(() => Number(route.params.cardId))

const card = computed(() => {
  return pipelineStore.cards.find(c => c.id === cardId.value)
})

const currentStage = computed(() => {
  if (!card.value) return null
  return pipelineStore.stages.find(s => s.id === card.value.stage_id)
})

const stageName = computed(() => {
  return currentStage.value?.name || 'Etapa desconhecida'
})

const stageColor = computed(() => {
  return currentStage.value?.color || '#CBD5E1'
})

const formatCurrency = (value, currency = 'BRL') => {
  if (value === undefined || value === null) return 'R$ 0,00'
  return new Intl.NumberFormat('pt-BR', {
    style: 'currency',
    currency: currency
  }).format(value)
}

const closeDetail = () => {
  router.push({
    name: 'pipelines-detail',
    params: { id: route.params.id }
  })
}

// Ouvinte do teclado para fechar no Esc
const handleKeyDown = (e) => {
  if (e.key === 'Escape') {
    closeDetail()
  }
}

onMounted(() => {
  window.addEventListener('keydown', handleKeyDown)
})
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
</style>
