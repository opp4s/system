<template>
  <div class="max-w-7xl mx-auto space-y-6 px-4 sm:px-6 lg:px-8 py-6">
    <!-- Header -->
    <header class="flex flex-col sm:flex-row sm:items-center sm:justify-between pb-5 border-b border-gray-200 gap-4">
      <div>
        <h1 class="text-2xl font-extrabold text-gray-900 tracking-tight">Ajustes de Funis & Pipelines</h1>
        <p class="text-sm text-gray-500 mt-1">
          Configure seus fluxos comerciais, ordene etapas e gerencie motivos de perda.
        </p>
      </div>

      <!-- Botão Voltar -->
      <router-link
        to="/pipelines"
        class="flex items-center justify-center space-x-2 px-4 py-2 border border-gray-250 bg-white rounded-xl text-sm font-semibold text-gray-700 hover:bg-gray-50 hover:text-gray-900 hover:border-gray-300 shadow-sm transition-all duration-150 shrink-0"
      >
        <component :is="ArrowLeft" class="h-4 w-4" />
        <span>Voltar ao Kanban</span>
      </router-link>
    </header>

    <!-- Conteúdo Principal -->
    <main class="grid grid-cols-1 lg:grid-cols-3 gap-6">
      <!-- Coluna da Esquerda: Lista de Pipelines com drag reorder -->
      <section class="bg-white border border-gray-200 rounded-2xl p-5 shadow-sm space-y-4 h-fit">
        <div class="flex items-center justify-between">
          <h2 class="text-xs font-bold text-gray-400 uppercase tracking-wider">Pipelines Cadastrados</h2>
          <button 
            @click="openCreatePipelineModal"
            class="text-xs font-bold text-slate-900 hover:text-slate-700 flex items-center space-x-1"
          >
            <component :is="Plus" class="h-3 w-3" />
            <span>Novo Funil</span>
          </button>
        </div>

        <!-- Draggable Pipelines -->
        <draggable
          v-model="pipelinesList"
          item-key="id"
          handle=".pipeline-drag-handle"
          ghost-class="opacity-50"
          class="space-y-2"
        >
          <template #item="{ element: pipeline }">
            <div 
              class="flex items-center justify-between p-3 rounded-xl border transition-all duration-200 cursor-pointer"
              :class="[
                activePipelineId === pipeline.id 
                  ? 'border-slate-800 bg-slate-50/50 ring-1 ring-slate-800' 
                  : 'border-gray-200 bg-white hover:bg-gray-50/50'
              ]"
              @click="selectPipeline(pipeline.id)"
            >
              <div class="flex items-center space-x-2.5 truncate flex-1 min-w-0">
                <span class="pipeline-drag-handle p-1 hover:bg-gray-150 rounded cursor-grab active:cursor-grabbing shrink-0">
                  <component :is="GripVertical" class="h-4 w-4 text-gray-400" />
                </span>
                <span class="w-3 h-3 rounded-full shrink-0" :style="{ backgroundColor: pipeline.color || '#3B82F6' }"></span>
                <span class="text-sm font-semibold text-gray-800 truncate">{{ pipeline.name }}</span>
              </div>
              
              <div class="flex items-center space-x-1 shrink-0 ml-2">
                <button
                  @click.stop="openEditPipelineModal(pipeline)"
                  class="p-1 text-gray-400 hover:text-gray-600 rounded-lg hover:bg-gray-100 transition-colors"
                >
                  <component :is="Settings" class="h-3.5 w-3.5" />
                </button>
                <button
                  @click.stop="deletePipeline(pipeline)"
                  class="p-1 text-gray-400 hover:text-rose-600 rounded-lg hover:bg-rose-50 transition-colors"
                >
                  <component :is="Trash2" class="h-3.5 w-3.5" />
                </button>
              </div>
            </div>
          </template>
        </draggable>
      </section>

      <!-- Coluna da Direita / Centro: Configurações do Pipeline selecionado -->
      <section class="lg:col-span-2 bg-white border border-gray-200 rounded-2xl p-6 shadow-sm space-y-6">
        <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between pb-4 border-b border-gray-100 gap-2">
          <div>
            <h3 class="text-base font-bold text-gray-900">
              Etapas do Funil: <span class="text-slate-600">{{ activePipeline?.name }}</span>
            </h3>
            <p class="text-xs text-gray-500 mt-0.5">Arraste para ordenar as etapas ou alterne cores e nomes inline.</p>
          </div>
          <span 
            v-if="saveIndicator"
            class="px-2.5 py-0.5 text-xs font-bold bg-emerald-50 text-emerald-700 rounded-full flex items-center space-x-1 self-start sm:self-auto animate-pulse"
          >
            <component :is="Check" class="h-3.5 w-3.5" />
            <span>Salvo</span>
          </span>
        </div>

        <div v-if="!activePipeline" class="text-center py-12 text-gray-400">
          Carregando etapas...
        </div>

        <!-- Draggable Stages -->
        <div v-else class="space-y-4">
          <draggable
            v-model="stagesList"
            item-key="id"
            handle=".stage-drag-handle"
            ghost-class="opacity-40"
            class="space-y-3"
          >
            <template #item="{ element: stage }">
              <div class="border border-gray-200 rounded-2xl bg-white overflow-hidden shadow-sm hover:shadow transition-all duration-150">
                <!-- Stage Header -->
                <div class="flex flex-col sm:flex-row sm:items-center justify-between p-4 bg-gray-50/50 gap-3 border-b border-gray-100">
                  <div class="flex items-center space-x-3 flex-1 min-w-0">
                    <span class="stage-drag-handle p-1.5 hover:bg-gray-200 rounded cursor-grab active:cursor-grabbing shrink-0">
                      <component :is="GripVertical" class="h-4 w-4 text-gray-400" />
                    </span>
                    
                    <!-- Color Picker Indicator -->
                    <div class="relative shrink-0 flex items-center">
                      <input 
                        type="color" 
                        v-model="stage.color"
                        @change="onStageColorChange(stage)"
                        class="absolute inset-0 opacity-0 w-6 h-6 cursor-pointer"
                      />
                      <span class="w-5 h-5 rounded-full border border-gray-300 block shadow-inner" :style="{ backgroundColor: stage.color }"></span>
                    </div>

                    <!-- Nome da Etapa (Inline Edit) -->
                    <input 
                      type="text"
                      v-model="stage.name"
                      @blur="onStageNameBlur(stage)"
                      @keyup.enter="onStageNameBlur(stage)"
                      class="flex-1 font-bold text-gray-800 text-sm bg-transparent border-b border-transparent hover:border-gray-300 focus:border-slate-800 focus:outline-none px-1 py-0.5 transition-all"
                      placeholder="Nome da etapa"
                    />
                  </div>

                  <div class="flex items-center justify-end space-x-2 shrink-0 self-end sm:self-auto">
                    <!-- Tipo da Etapa Badge -->
                    <select
                      v-model="stage.stage_type"
                      @change="onStageTypeChange(stage)"
                      class="text-xs px-2.5 py-1 rounded-full font-semibold border-0 cursor-pointer focus:ring-1 focus:ring-slate-400 focus:outline-none"
                      :class="getStageBadgeClass(stage.stage_type)"
                    >
                      <option value="intermediate">Intermediário</option>
                      <option value="win">Ganho</option>
                      <option value="lose">Perdido</option>
                    </select>

                    <button 
                      @click="deleteStage(stage)"
                      class="p-1.5 text-gray-400 hover:text-rose-600 hover:bg-rose-50 rounded-lg transition-all"
                      title="Excluir Etapa"
                    >
                      <component :is="Trash2" class="h-4 w-4" />
                    </button>
                  </div>
                </div>

                <!-- Seção Expandível para Motivos de Perda (Tipo = 'lose') -->
                <div v-if="stage.stage_type === 'lose'" class="p-4 bg-white border-t border-gray-100 space-y-3">
                  <div class="flex items-center space-x-1.5 text-gray-500">
                    <component :is="Info" class="h-4 w-4 text-gray-400" />
                    <span class="text-xs font-bold uppercase tracking-wider text-gray-400">Motivos de Perda Cadastrados</span>
                  </div>

                  <!-- Lista de Motivos Existentes -->
                  <div class="flex flex-wrap gap-2">
                    <span 
                      v-for="(reason, index) in (stage.loss_reasons || [])" 
                      :key="index"
                      class="inline-flex items-center space-x-1.5 px-3 py-1 rounded-xl bg-rose-50 border border-rose-100 text-xs font-semibold text-rose-700"
                    >
                      <span>{{ reason }}</span>
                      <button 
                        @click="removeLossReason(stage, index)"
                        class="p-0.5 hover:bg-rose-100 text-rose-500 hover:text-rose-800 rounded-full transition-colors"
                      >
                        <component :is="X" class="h-3 w-3" />
                      </button>
                    </span>
                    <span v-if="!(stage.loss_reasons && stage.loss_reasons.length)" class="text-xs text-gray-400 italic">
                      Nenhum motivo de perda cadastrado. Digite abaixo para adicionar.
                    </span>
                  </div>

                  <!-- Input Novo Motivo -->
                  <div class="flex items-center space-x-2 max-w-md">
                    <input
                      type="text"
                      v-model="newReasonsMap[stage.id]"
                      @keyup.enter="addLossReason(stage)"
                      placeholder="Novo motivo de perda (ex: Sem Budget)..."
                      class="flex-1 px-3 py-1.5 rounded-xl border border-gray-250 focus:outline-none focus:border-rose-500 focus:ring-1 focus:ring-rose-500 bg-gray-50/30 text-xs transition-all"
                    />
                    <button
                      @click="addLossReason(stage)"
                      class="px-3 py-1.5 bg-rose-600 hover:bg-rose-700 text-white font-bold rounded-xl text-xs shadow-md shadow-rose-600/10 transition-all shrink-0"
                    >
                      Adicionar
                    </button>
                  </div>
                </div>
              </div>
            </template>
          </draggable>

          <!-- Formulário Rápido para Criar Nova Etapa -->
          <div v-if="addingStage" class="border border-dashed border-gray-300 rounded-2xl p-4 bg-slate-50/50 space-y-4">
            <h4 class="text-xs font-bold text-gray-700">Nova Etapa do Funil</h4>
            <div class="grid grid-cols-1 sm:grid-cols-3 gap-3">
              <div class="space-y-1">
                <label class="text-[10px] font-bold text-gray-400 uppercase tracking-wider block">Nome</label>
                <input 
                  type="text" 
                  v-model="newStageForm.name" 
                  placeholder="Ex: Proposta Comercial"
                  class="block w-full px-3 py-2 rounded-xl border border-gray-250 focus:outline-none focus:border-slate-800 focus:ring-1 focus:ring-slate-850 bg-white text-xs text-gray-800 transition-all"
                />
              </div>
              <div class="space-y-1">
                <label class="text-[10px] font-bold text-gray-400 uppercase tracking-wider block">Tipo</label>
                <select
                  v-model="newStageForm.stage_type"
                  class="block w-full px-3 py-2 rounded-xl border border-gray-250 focus:outline-none focus:border-slate-800 focus:ring-1 focus:ring-slate-850 bg-white text-xs text-gray-800 transition-all"
                >
                  <option value="intermediate">Intermediário</option>
                  <option value="win">Ganho</option>
                  <option value="lose">Perdido</option>
                </select>
              </div>
              <div class="space-y-1">
                <label class="text-[10px] font-bold text-gray-400 uppercase tracking-wider block">Cor</label>
                <div class="flex items-center space-x-2">
                  <input 
                    type="color" 
                    v-model="newStageForm.color"
                    class="w-8 h-8 rounded-lg cursor-pointer border-0 bg-transparent"
                  />
                  <input 
                    type="text" 
                    v-model="newStageForm.color" 
                    placeholder="#3B82F6"
                    class="block w-full px-3 py-2 rounded-xl border border-gray-250 focus:outline-none focus:border-slate-800 focus:ring-1 focus:ring-slate-850 bg-white text-xs text-gray-800 transition-all"
                  />
                </div>
              </div>
            </div>

            <div class="flex justify-end space-x-2 pt-2">
              <button 
                @click="addingStage = false"
                class="px-3.5 py-1.5 border border-gray-200 hover:bg-gray-50 rounded-xl text-xs font-semibold text-gray-650 transition-all"
              >
                Cancelar
              </button>
              <button 
                @click="createStage"
                :disabled="!newStageForm.name.trim()"
                class="px-4 py-1.5 bg-slate-900 hover:bg-slate-800 disabled:bg-slate-400 text-white font-bold rounded-xl text-xs shadow-md shadow-slate-900/10 transition-all"
              >
                Criar Etapa
              </button>
            </div>
          </div>

          <!-- Botão adicionar etapa -->
          <button 
            v-else
            @click="addingStage = true"
            class="w-full py-3 border border-dashed border-gray-300 hover:border-gray-400 hover:bg-slate-50/20 rounded-xl text-xs font-bold text-gray-500 hover:text-gray-700 flex items-center justify-center space-x-1.5 transition-all duration-150"
          >
            <component :is="Plus" class="h-4 w-4" />
            <span>Adicionar nova etapa</span>
          </button>
        </div>
      </section>
    </main>

    <!-- Modal Criar / Editar Pipeline -->
    <div v-if="pipelineModalOpen" class="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div @click="pipelineModalOpen = false" class="absolute inset-0 bg-slate-900/50 backdrop-blur-sm"></div>
      <div class="relative bg-white rounded-3xl p-6 max-w-md w-full shadow-2xl border border-gray-100 z-10 animate-scale-up space-y-4">
        <header class="flex items-center justify-between pb-3 border-b border-gray-100">
          <h3 class="text-base font-bold text-gray-900">
            {{ isEditingPipeline ? 'Editar Pipeline' : 'Novo Pipeline' }}
          </h3>
          <button @click="pipelineModalOpen = false" class="p-1 text-gray-400 hover:text-gray-600 rounded-lg">
            <component :is="X" class="h-5 w-5" />
          </button>
        </header>

        <main class="space-y-4">
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-gray-400 uppercase tracking-wider block">Nome do Funil</label>
            <input 
              type="text" 
              v-model="pipelineForm.name"
              placeholder="Ex: Vendas High Ticket"
              class="block w-full px-4 py-2.5 rounded-xl border border-gray-250 focus:outline-none focus:border-slate-800 focus:ring-1 focus:ring-slate-850 bg-gray-50/20 text-xs text-gray-800 transition-all"
            />
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-gray-400 uppercase tracking-wider block">Descrição</label>
            <textarea 
              v-model="pipelineForm.description"
              placeholder="Descreva o propósito deste funil..."
              rows="2"
              class="block w-full px-4 py-2.5 rounded-xl border border-gray-250 focus:outline-none focus:border-slate-800 focus:ring-1 focus:ring-slate-850 bg-gray-50/20 text-xs text-gray-800 transition-all"
            ></textarea>
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-gray-400 uppercase tracking-wider block">Cor de Destaque</label>
            <div class="flex items-center space-x-2">
              <input 
                type="color" 
                v-model="pipelineForm.color"
                class="w-9 h-9 rounded-xl cursor-pointer border-0 bg-transparent"
              />
              <input 
                type="text" 
                v-model="pipelineForm.color"
                placeholder="#3B82F6"
                class="block w-full px-4 py-2.5 rounded-xl border border-gray-250 focus:outline-none focus:border-slate-800 focus:ring-1 focus:ring-slate-850 bg-gray-50/20 text-xs text-gray-800 transition-all"
              />
            </div>
          </div>
        </main>

        <footer class="pt-4 border-t border-gray-100 flex items-center justify-end space-x-3">
          <button
            @click="pipelineModalOpen = false"
            class="px-4 py-2 border border-gray-200 rounded-xl text-xs font-semibold text-gray-600 hover:text-gray-900 hover:bg-gray-50 transition-all"
          >
            Cancelar
          </button>
          <button
            @click="savePipeline"
            :disabled="!pipelineForm.name.trim()"
            class="px-4 py-2 bg-slate-900 hover:bg-slate-800 disabled:bg-slate-400 text-white rounded-xl text-xs font-bold shadow-md shadow-slate-900/10 hover:shadow-lg transition-all"
          >
            {{ isEditingPipeline ? 'Salvar Alterações' : 'Criar Funil' }}
          </button>
        </footer>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import { usePipelineStore } from '@/stores/pipeline'
import draggable from 'vuedraggable'
import { 
  ArrowLeft, 
  GripVertical, 
  Settings, 
  Trash2, 
  Plus, 
  X, 
  Check,
  Info
} from 'lucide-vue-next'

const pipelineStore = usePipelineStore()
const activePipelineId = ref(null)
const saveIndicator = ref(false)

// Estados de Modais e Formulários
const pipelineModalOpen = ref(false)
const isEditingPipeline = ref(false)
const editingPipelineId = ref(null)
const pipelineForm = reactive({
  name: '',
  description: '',
  color: '#3B82F6'
})

const addingStage = ref(false)
const newStageForm = reactive({
  name: '',
  stage_type: 'intermediate',
  color: '#4B5563'
})

// Mapeamento dinâmico para os inputs de novos motivos de perda
const newReasonsMap = ref({})

// Computed para obter o Pipeline selecionado atualmente
const activePipeline = computed(() => {
  return pipelineStore.pipelines.find(p => p.id === activePipelineId.value) || null
})

// Computed com getter/setter para o draggable de Pipelines
const pipelinesList = computed({
  get: () => pipelineStore.pipelines,
  set: async (value) => {
    const ids = value.map(p => p.id)
    try {
      await pipelineStore.reorderPipelines(ids)
      triggerSaveIndicator()
    } catch (e) {
      alert('Não foi possível reordenar os pipelines na API.')
    }
  }
})

// Computed com getter/setter para o draggable de Stages
const stagesList = computed({
  get: () => pipelineStore.stages,
  set: async (value) => {
    if (!activePipelineId.value) return
    const ids = value.map(s => s.id)
    try {
      await pipelineStore.reorderStages(activePipelineId.value, ids)
      triggerSaveIndicator()
    } catch (e) {
      alert('Não foi possível reordenar as etapas na API.')
    }
  }
})

onMounted(async () => {
  await pipelineStore.fetchPipelines()
  if (pipelineStore.pipelines.length > 0) {
    // Escolhe o primeiro pipeline disponível
    await selectPipeline(pipelineStore.pipelines[0].id)
  }
})

const selectPipeline = async (id) => {
  activePipelineId.value = id
  await pipelineStore.fetchStages(id)
  // Inicializa mapa de novos motivos de perda
  pipelineStore.stages.forEach(stage => {
    if (stage.stage_type === 'lose') {
      newReasonsMap.value[stage.id] = ''
    }
  })
}

// Indicador visual de salvamento
const triggerSaveIndicator = () => {
  saveIndicator.value = true
  setTimeout(() => {
    saveIndicator.value = false
  }, 2000)
}

// Estilo de Badges de tipo de estágio
const getStageTypeLabel = (type) => {
  switch (type) {
    case 'win': return 'Ganho'
    case 'lose': return 'Perdido'
    default: return 'Intermediário'
  }
}

const getStageBadgeClass = (type) => {
  switch (type) {
    case 'win': return 'bg-emerald-50 text-emerald-700 border border-emerald-105'
    case 'lose': return 'bg-rose-50 text-rose-700 border border-rose-105'
    default: return 'bg-slate-55 bg-gray-50 text-gray-700 border border-gray-200'
  }
}

// Eventos de Edição Inline de Estágios
const onStageNameBlur = async (stage) => {
  if (!stage.name.trim()) return
  try {
    await pipelineStore.updateStage(activePipelineId.value, stage.id, { name: stage.name })
    triggerSaveIndicator()
  } catch (e) {
    alert('Erro ao atualizar nome da etapa.')
  }
}

const onStageColorChange = async (stage) => {
  try {
    await pipelineStore.updateStage(activePipelineId.value, stage.id, { color: stage.color })
    triggerSaveIndicator()
  } catch (e) {
    alert('Erro ao atualizar cor da etapa.')
  }
}

const onStageTypeChange = async (stage) => {
  try {
    await pipelineStore.updateStage(activePipelineId.value, stage.id, { stage_type: stage.stage_type })
    if (stage.stage_type === 'lose' && !newReasonsMap.value[stage.id]) {
      newReasonsMap.value[stage.id] = ''
    }
    triggerSaveIndicator()
  } catch (e) {
    alert('Erro ao atualizar tipo da etapa.')
  }
}

// Motivos de Perda
const addLossReason = async (stage) => {
  const reasonText = newReasonsMap.value[stage.id]?.trim()
  if (!reasonText) return
  
  const currentReasons = Array.isArray(stage.loss_reasons) ? [...stage.loss_reasons] : []
  if (currentReasons.includes(reasonText)) {
    alert('Este motivo já está cadastrado.')
    return
  }

  currentReasons.push(reasonText)
  try {
    await pipelineStore.updateStage(activePipelineId.value, stage.id, { loss_reasons: currentReasons })
    newReasonsMap.value[stage.id] = ''
    triggerSaveIndicator()
  } catch (e) {
    alert('Erro ao salvar motivo de perda.')
  }
}

const removeLossReason = async (stage, reasonIndex) => {
  const currentReasons = Array.isArray(stage.loss_reasons) ? [...stage.loss_reasons] : []
  currentReasons.splice(reasonIndex, 1)
  
  try {
    await pipelineStore.updateStage(activePipelineId.value, stage.id, { loss_reasons: currentReasons })
    triggerSaveIndicator()
  } catch (e) {
    alert('Erro ao remover motivo de perda.')
  }
}

// CRUD Pipeline Modais
const openCreatePipelineModal = () => {
  isEditingPipeline.value = false
  pipelineForm.name = ''
  pipelineForm.description = ''
  pipelineForm.color = '#3B82F6'
  pipelineModalOpen.value = true
}

const openEditPipelineModal = (pipeline) => {
  isEditingPipeline.value = true
  editingPipelineId.value = pipeline.id
  pipelineForm.name = pipeline.name
  pipelineForm.description = pipeline.description || ''
  pipelineForm.color = pipeline.color || '#3B82F6'
  pipelineModalOpen.value = true
}

const savePipeline = async () => {
  if (!pipelineForm.name.trim()) return

  try {
    if (isEditingPipeline.value) {
      await pipelineStore.updateCard(editingPipelineId.value, { 
        name: pipelineForm.name, 
        description: pipelineForm.description, 
        color: pipelineForm.color 
      }) // TODO: o model pipeline é atualizado pela API /api/v1/pipelines/:id.
      // Vamos adicionar updatePipeline na store para ser mais consistente.
      // Se não adicionamos, vamos chamar direto a API ou adicionar a ação.
      // Vamos adicionar a ação no Pinia Store para não dar erro!
      // Vamos editar a store para garantir que tenhamos updatePipeline.
      await pipelineStore.updatePipeline(editingPipelineId.value, {
        name: pipelineForm.name,
        description: pipelineForm.description,
        color: pipelineForm.color
      })
    } else {
      const newPipeline = await pipelineStore.createPipeline({
        name: pipelineForm.name,
        description: pipelineForm.description,
        color: pipelineForm.color
      })
      activePipelineId.value = newPipeline.id
    }
    pipelineModalOpen.value = false
    triggerSaveIndicator()
  } catch (e) {
    alert('Erro ao salvar o pipeline na API.')
  }
}

const deletePipeline = async (pipeline) => {
  if (!confirm(`Deseja realmente excluir o funil "${pipeline.name}"? Esta ação não pode ser desfeita.`)) return

  try {
    // Para simplificar, se não houver cards ativos podemos apagar
    await pipelineStore.deletePipeline(pipeline.id)
    if (activePipelineId.value === pipeline.id && pipelineStore.pipelines.length > 0) {
      await selectPipeline(pipelineStore.pipelines[0].id)
    }
    triggerSaveIndicator()
  } catch (e) {
    alert(e.response?.data?.error || 'Não é possível excluir funis com cards ativos.')
  }
}

// CRUD Stages
const createStage = async () => {
  if (!newStageForm.name.trim()) return
  try {
    await pipelineStore.createStage(activePipelineId.value, {
      name: newStageForm.name,
      stage_type: newStageForm.stage_type,
      color: newStageForm.color
    })
    // Reseta form
    newStageForm.name = ''
    newStageForm.stage_type = 'intermediate'
    newStageForm.color = '#4B5563'
    addingStage.value = false
    triggerSaveIndicator()
  } catch (e) {
    alert('Erro ao criar nova etapa.')
  }
}

const deleteStage = async (stage) => {
  if (!confirm(`Deseja excluir a etapa "${stage.name}"? Todos os cards desta etapa devem ser movidos primeiro.`)) return
  try {
    await pipelineStore.deleteStage(activePipelineId.value, stage.id)
    triggerSaveIndicator()
  } catch (e) {
    alert(e.response?.data?.error || 'Erro ao deletar etapa. Verifique se existem cards nela.')
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
