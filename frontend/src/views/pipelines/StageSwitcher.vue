<template>
  <div class="relative" ref="dropdownRef">
    <!-- Botão Seletor -->
    <button
      @click="isOpen = !isOpen"
      type="button"
      class="w-full flex items-center justify-between px-4 py-2.5 bg-white border border-gray-200 hover:border-gray-300 rounded-xl text-sm font-semibold text-gray-700 focus:outline-none focus:ring-1 focus:ring-slate-900 transition-all duration-150 shadow-sm"
    >
      <div class="flex items-center space-x-2.5 truncate">
        <!-- Indicador de cor do estágio atual -->
        <span 
          class="w-2.5 h-2.5 rounded-full shrink-0" 
          :style="{ backgroundColor: currentStage?.color || '#CBD5E1' }"
        ></span>
        <span class="truncate">{{ currentStage?.name || 'Selecione a etapa' }}</span>
      </div>
      <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-gray-400 shrink-0 ml-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
      </svg>
    </button>

    <!-- Menu Dropdown -->
    <div
      v-if="isOpen"
      class="absolute left-0 mt-2 w-full min-w-[220px] bg-white border border-gray-150 rounded-2xl shadow-xl py-2 z-50 animate-fade-in"
    >
      <div class="px-3 py-1.5 border-b border-gray-100 mb-1">
        <span class="text-[10px] font-bold text-gray-400 uppercase tracking-wider">Mudar Etapa</span>
      </div>
      
      <button
        v-for="stage in pipelineStore.stages"
        :key="stage.id"
        @click="selectStage(stage)"
        type="button"
        class="w-full flex items-center justify-between px-4 py-2 text-sm text-left hover:bg-gray-50 transition-colors"
        :class="{'bg-slate-50 font-bold text-slate-900': stage.id === activeStageId}"
      >
        <div class="flex items-center space-x-2.5 truncate">
          <span 
            class="w-2.5 h-2.5 rounded-full shrink-0" 
            :style="{ backgroundColor: stage.color || '#CBD5E1' }"
          ></span>
          <span class="truncate">{{ stage.name }}</span>
        </div>
        
        <!-- Checkmark if active -->
        <svg 
          v-if="stage.id === activeStageId"
          xmlns="http://www.w3.org/2000/svg" 
          class="h-4 w-4 text-slate-800 shrink-0" 
          fill="none" 
          viewBox="0 0 24 24" 
          stroke="currentColor"
        >
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M5 13l4 4L19 7" />
        </svg>
      </button>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { usePipelineStore } from '@/stores/pipeline'

const props = defineProps({
  activeStageId: {
    type: Number,
    required: true
  }
})

const emits = defineEmits(['change-stage'])

const pipelineStore = usePipelineStore()
const isOpen = ref(false)
const dropdownRef = ref(null)

const currentStage = computed(() => {
  return pipelineStore.stages.find(s => s.id === props.activeStageId) || null
})

const selectStage = (stage) => {
  isOpen.value = false
  if (stage.id !== props.activeStageId) {
    emits('change-stage', stage.id)
  }
}

// Fecha dropdown ao clicar fora
const handleClickOutside = (e) => {
  if (dropdownRef.value && !dropdownRef.value.contains(e.target)) {
    isOpen.value = false
  }
}

onMounted(() => {
  document.addEventListener('click', handleClickOutside)
})

onUnmounted(() => {
  document.removeEventListener('click', handleClickOutside)
})
</script>

<style scoped>
@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(-4px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
.animate-fade-in {
  animation: fadeIn 0.15s ease-out forwards;
}
</style>
