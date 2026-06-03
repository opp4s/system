<template>
  <div class="flex h-[calc(100vh-4rem)] -m-6 md:-m-8 bg-slate-55 bg-slate-100 overflow-hidden">
    <!-- Coluna 1: Lista de Chats (~25%) -->
    <div class="w-full md:w-80 lg:w-[25vw] h-full shrink-0 flex flex-col bg-white z-15 border-r border-gray-150">
      <ConversationList 
        :selected-card-id="selectedCardId"
        @select="handleSelectConversation"
      />
    </div>

    <!-- Coluna 2: Dados do Lead (~25%) -->
    <div class="w-full md:w-80 lg:w-[25vw] h-full shrink-0 flex flex-col border-r border-gray-150 bg-white" v-if="selectedCard">
      <CardDataPanel 
        :card-id="selectedCard.id" 
        :pipeline-id="selectedCard.pipeline_id" 
      />
    </div>
    <!-- Coluna 2: Empty State -->
    <div class="w-full md:w-80 lg:w-[25vw] h-full shrink-0 flex flex-col items-center justify-center border-r border-gray-150 bg-slate-50/50 p-6 text-center text-xs text-gray-400 select-none" v-else>
      <svg xmlns="http://www.w3.org/2000/svg" class="h-8 w-8 text-gray-300 mb-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
      </svg>
      <span>Nenhum lead selecionado</span>
    </div>

    <!-- Coluna 3: Timeline / Conversa (~50%) -->
    <div class="flex-1 h-full flex flex-col bg-white" v-if="selectedCard">
      <!-- Chat Header -->
      <header class="h-16 px-6 border-b border-gray-100 flex items-center justify-between shrink-0 bg-gray-50/50 select-none">
        <div class="flex items-center space-x-3">
          <span class="px-2.5 py-1 text-xs font-bold bg-slate-950 text-white rounded-lg">Negócio #{{ selectedCard.id }}</span>
          <span class="text-gray-400">/</span>
          <span class="text-sm font-semibold text-slate-800">{{ selectedCard.contact_name || 'Ficha do Lead' }}</span>
        </div>
      </header>
      
      <!-- Timeline Area -->
      <div class="flex-1 overflow-hidden">
        <ChatTimeline 
          :card-id="selectedCard.id" 
          :pipeline-id="selectedCard.pipeline_id" 
        />
      </div>
    </div>
    <!-- Coluna 3: Empty State -->
    <div class="flex-1 h-full flex flex-col items-center justify-center bg-slate-50/50 p-8 text-center text-sm text-gray-400 select-none" v-else>
      <svg xmlns="http://www.w3.org/2000/svg" class="h-12 w-12 text-gray-300 mb-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
      </svg>
      <span class="font-bold text-gray-700 block mb-1">Central de Comunicações</span>
      <span class="text-xs text-gray-400">Selecione um contato na lista ao lado para iniciar a conversa</span>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { usePipelineStore } from '@/stores/pipeline'
import ConversationList from './ConversationList.vue'
import CardDataPanel from '../pipelines/CardDataPanel.vue'
import ChatTimeline from '../pipelines/ChatTimeline.vue'

const pipelineStore = usePipelineStore()
const selectedCardId = ref(null)

const selectedCard = computed(() => {
  if (!selectedCardId.value) return null
  return pipelineStore.cards.find(c => c.id === selectedCardId.value)
})

const handleSelectConversation = async (conv) => {
  // Seta o pipeline ID ativo na store para as chamadas internas
  pipelineStore.currentPipelineId = conv.pipeline_id
  
  // Seta o card selecionado localmente
  selectedCardId.value = conv.card_id

  // Carrega as etapas do pipeline correspondente para o StageSwitcher funcionar
  await pipelineStore.fetchStages(conv.pipeline_id)

  // Carrega detalhes atualizados e a timeline
  await pipelineStore.fetchCardDetail(conv.pipeline_id, conv.card_id)
}
</script>
