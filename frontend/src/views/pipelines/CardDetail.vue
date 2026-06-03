<template>
  <div class="fixed inset-0 z-50 flex justify-end">
    <!-- Backdrop de Fundo -->
    <div 
      @click="closeDetail"
      class="absolute inset-0 bg-slate-900/40 backdrop-blur-sm transition-opacity duration-300"
    ></div>

    <!-- Painel Slide-in Lateral (ocupando 60% de largura no desktop, layout dividido) -->
    <div 
      class="relative w-full md:w-[65vw] lg:w-[60vw] h-full bg-white shadow-2xl flex flex-col z-10 animate-slide-in-right transition-transform duration-300"
    >
      <!-- Header do Slide-in -->
      <header class="h-16 px-6 border-b border-gray-100 flex items-center justify-between shrink-0 bg-gray-50/50">
        <div class="flex items-center space-x-3">
          <span class="px-2.5 py-1 text-xs font-bold bg-slate-950 text-white rounded-lg">Negócio #{{ cardId }}</span>
          <span class="text-gray-400">/</span>
          <span class="text-sm font-semibold text-gray-500">Ficha do Lead</span>
        </div>

        <button 
          @click="closeDetail"
          class="p-2 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-xl transition-all duration-150"
        >
          <component :is="X" class="h-5 w-5" />
        </button>
      </header>

      <!-- Corpo do Detalhe -->
      <div v-if="card" class="flex-1 flex flex-col md:flex-row overflow-hidden">
        <!-- Coluna Esquerda: Dados do Card (Painel de ~38% de largura no desktop) -->
        <aside class="w-full md:w-80 border-b md:border-b-0 md:border-r border-gray-100 overflow-hidden flex flex-col">
          <CardDataPanel :card-id="cardId" :pipeline-id="pipelineId" />
        </aside>

        <!-- Coluna Direita / Centro: Timeline de Atividades / WhatsApp Chat -->
        <section class="flex-1 flex flex-col bg-slate-50/50 overflow-hidden">
          <ChatTimeline :card-id="cardId" :pipeline-id="pipelineId" />
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
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { usePipelineStore } from '@/stores/pipeline'
import CardDataPanel from './CardDataPanel.vue'
import ChatTimeline from './ChatTimeline.vue'
import { X } from 'lucide-vue-next'

const route = useRoute()
const router = useRouter()
const pipelineStore = usePipelineStore()

const cardId = computed(() => Number(route.params.cardId))
const pipelineId = computed(() => Number(route.params.id))

const card = computed(() => {
  return pipelineStore.cards.find(c => c.id === cardId.value)
})

const closeDetail = () => {
  router.push({
    name: 'pipelines-detail',
    params: { id: route.params.id }
  })
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
</style>
