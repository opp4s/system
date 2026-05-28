<template>
  <div class="max-w-6xl mx-auto space-y-6">
    <!-- Header -->
    <header class="flex items-center justify-between pb-5 border-b border-gray-200">
      <div>
        <h1 class="text-2xl font-extrabold text-gray-900 tracking-tight">Ajustes de Funis & Pipelines</h1>
        <p class="text-sm text-gray-500 mt-1">
          Crie, edite e organize a estrutura dos seus estágios de vendas.
        </p>
      </div>

      <!-- Botão Voltar -->
      <router-link
        to="/pipelines"
        class="flex items-center space-x-2 px-4 py-2 border border-gray-250 bg-white rounded-xl text-sm font-semibold text-gray-700 hover:bg-gray-50 hover:text-gray-900 hover:border-gray-300 shadow-sm transition-all duration-150"
      >
        <component :is="ArrowLeft" class="h-4 w-4" />
        <span>Voltar ao Kanban</span>
      </router-link>
    </header>

    <!-- Conteúdo Principal (Mock Visual para o Dia 10) -->
    <main class="grid grid-cols-1 lg:grid-cols-3 gap-6">
      <!-- Coluna da Esquerda: Lista de Pipelines -->
      <section class="bg-white border border-gray-200 rounded-2xl p-6 shadow-sm space-y-4">
        <div class="flex items-center justify-between">
          <h2 class="text-sm font-bold text-gray-800 uppercase tracking-wider">Pipelines Cadastrados</h2>
          <button class="text-xs font-bold text-zavy-600 hover:text-zavy-700">+ Novo Funil</button>
        </div>

        <div class="space-y-2">
          <div 
            v-for="pipeline in pipelineStore.pipelines" 
            :key="pipeline.id"
            class="flex items-center justify-between p-3 rounded-xl border border-gray-200 bg-gray-50/50 hover:bg-white hover:shadow-sm cursor-pointer transition-all duration-200"
            :class="{'border-slate-800 bg-white ring-1 ring-slate-850': activePipelineId === pipeline.id}"
            @click="activePipelineId = pipeline.id"
          >
            <div class="flex items-center space-x-2.5 truncate">
              <span class="w-3 h-3 rounded-full shrink-0" :style="{backgroundColor: pipeline.color}"></span>
              <span class="text-sm font-bold text-gray-800 truncate">{{ pipeline.name }}</span>
            </div>
            <component :is="GripVertical" class="h-4 w-4 text-gray-400 cursor-grab active:cursor-grabbing" />
          </div>
        </div>
      </section>

      <!-- Coluna da Direita / Centro: Configurações do Pipeline selecionado -->
      <section class="lg:col-span-2 bg-white border border-gray-200 rounded-2xl p-6 shadow-sm space-y-6">
        <div class="flex items-center justify-between pb-3 border-b border-gray-100">
          <div>
            <h3 class="text-base font-bold text-gray-900">Configuração das Etapas</h3>
            <p class="text-xs text-gray-500 mt-0.5">Arraste para reordenar, clique para editar.</p>
          </div>
          <span class="px-2 py-0.5 text-xs font-bold bg-slate-100 text-slate-700 rounded-full">Dia 10</span>
        </div>

        <!-- Etapas Mock (Dia 10) -->
        <div class="space-y-3">
          <div 
            v-for="stage in selectedStages" 
            :key="stage.id"
            class="flex items-center justify-between p-4 rounded-xl border border-gray-200 bg-white hover:shadow-sm transition-all duration-150"
          >
            <div class="flex items-center space-x-4">
              <component :is="GripVertical" class="h-5 w-5 text-gray-400 cursor-grab" />
              <!-- Cor indicador -->
              <span class="w-3.5 h-3.5 rounded-full" :style="{backgroundColor: stage.color}"></span>
              <!-- Nome etapa -->
              <span class="text-sm font-bold text-gray-800">{{ stage.name }}</span>
            </div>

            <div class="flex items-center space-x-2">
              <span class="text-xs px-2.5 py-1 rounded-full font-semibold capitalize" :class="getStageBadgeClass(stage.stage_type)">
                {{ getStageTypeLabel(stage.stage_type) }}
              </span>
              <button class="p-1.5 text-gray-400 hover:text-gray-600 hover:bg-gray-50 rounded-lg">
                <component :is="Settings" class="h-4 w-4" />
              </button>
            </div>
          </div>
        </div>

        <!-- Botão adicionar etapa -->
        <button class="w-full py-3 border border-dashed border-gray-300 hover:border-gray-400 rounded-xl text-xs font-bold text-gray-500 hover:text-gray-700 flex items-center justify-center space-x-1.5 transition-all duration-150">
          <span>+ Adicionar nova etapa</span>
        </button>
      </section>
    </main>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { usePipelineStore } from '@/stores/pipeline'
import { ArrowLeft, GripVertical, Settings } from 'lucide-vue-next'

const pipelineStore = usePipelineStore()
const activePipelineId = ref(1)

const selectedStages = computed(() => {
  // Mock stages para o funil ativo
  if (activePipelineId.value === 1) {
    return [
      { id: 101, name: 'Novo Lead', color: '#3B82F6', stage_type: 'intermediate' },
      { id: 102, name: 'Qualificado', color: '#8B5CF6', stage_type: 'intermediate' },
      { id: 103, name: 'Proposta Enviada', color: '#EAB308', stage_type: 'intermediate' },
      { id: 104, name: 'Negociação', color: '#F97316', stage_type: 'intermediate' },
      { id: 105, name: 'Fechado Ganho', color: '#10B981', stage_type: 'win' },
      { id: 106, name: 'Fechado Perdido', color: '#EF4444', stage_type: 'lose' }
    ]
  } else {
    return [
      { id: 201, name: 'Kickoff', color: '#3B82F6', stage_type: 'intermediate' },
      { id: 202, name: 'Configuração', color: '#8B5CF6', stage_type: 'intermediate' },
      { id: 203, name: 'Treinamento', color: '#EAB308', stage_type: 'intermediate' },
      { id: 204, name: 'Em Produção', color: '#10B981', stage_type: 'win' },
      { id: 205, name: 'Cancelado', color: '#EF4444', stage_type: 'lose' }
    ]
  }
})

const getStageTypeLabel = (type) => {
  switch (type) {
    case 'win': return 'Ganho'
    case 'lose': return 'Perdido'
    default: return 'Intermediário'
  }
}

const getStageBadgeClass = (type) => {
  switch (type) {
    case 'win': return 'bg-emerald-50 text-emerald-700'
    case 'lose': return 'bg-rose-50 text-rose-700'
    default: return 'bg-slate-100 text-slate-700'
  }
}
</script>
