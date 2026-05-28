<template>
  <div class="bg-white border border-gray-150 rounded-3xl p-5 shadow-sm space-y-4">
    <div class="flex items-center justify-between">
      <h3 class="text-xs font-bold text-gray-900 uppercase tracking-wider">Funil de Conversão Comercial</h3>
      <span class="text-[9px] font-bold text-gray-400 uppercase">Taxa de Conversão Global</span>
    </div>

    <!-- Skeletons se Carregando -->
    <div v-if="loading" class="space-y-3.5">
      <div v-for="i in 5" :key="i" class="h-10 bg-gray-100 rounded-xl animate-pulse"></div>
    </div>

    <!-- Empty State -->
    <div v-else-if="!data || data.length === 0" class="text-center py-10 text-xs text-gray-400 italic">
      Sem dados de funil disponíveis para este período.
    </div>

    <!-- Funil Ativo -->
    <div v-else class="space-y-3 pt-2">
      <div 
        v-for="(stage, index) in data" 
        :key="stage.name"
        class="relative group"
      >
        <!-- Card / Linha da Barra -->
        <div class="flex items-center justify-between text-xs font-bold z-10 relative px-3 py-2.5">
          <!-- Nome do Estágio -->
          <span class="text-slate-800 tracking-tight shrink-0">{{ stage.name }}</span>
          
          <!-- Contagem e Conversão -->
          <div class="flex items-center space-x-3 shrink-0">
            <span class="text-slate-900 font-extrabold">{{ stage.count }} leads</span>
            <span class="text-[10px] text-gray-450 font-bold bg-slate-100 px-2 py-0.5 rounded-md">
              {{ stage.conversion_rate }}%
            </span>
          </div>
        </div>

        <!-- Barra de Progresso com Gradiente Dinâmico -->
        <div 
          class="absolute inset-y-0 left-0 rounded-xl transition-all duration-700 ease-out origin-left"
          :class="getGradientClass(index)"
          :style="{ width: stage.conversion_rate + '%', opacity: 0.15 }"
        ></div>

        <!-- Linha Sólida Indicativa no Rodapé do Item -->
        <div 
          class="h-1 rounded-full transition-all duration-1000 ease-out"
          :class="getSolidBgClass(index)"
          :style="{ width: stage.conversion_rate + '%' }"
        ></div>

        <!-- Tooltip Customizado Flutuante no Hover -->
        <div class="absolute bottom-full left-1/2 transform -translate-x-1/2 mb-2 w-48 bg-slate-950 text-white rounded-xl p-2.5 text-[10px] font-medium leading-relaxed shadow-xl opacity-0 scale-95 group-hover:opacity-100 group-hover:scale-100 transition-all duration-150 z-30 pointer-events-none select-none">
          <span class="font-bold text-white block mb-0.5">{{ stage.name }}</span>
          <span class="text-gray-300 block">Total: <strong class="text-white">{{ stage.count }} negócios</strong></span>
          <span class="text-gray-300 block">Conversão: <strong class="text-white">{{ stage.conversion_rate }}%</strong> do topo</span>
          <!-- Seta do Tooltip -->
          <div class="absolute top-full left-1/2 transform -translate-x-1/2 -mt-1 border-4 border-transparent border-t-slate-950"></div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
const props = defineProps({
  data: {
    type: Array,
    required: true,
    default: () => []
  },
  loading: {
    type: Boolean,
    default: false
  }
})

// Retorna cores gradientes do mais largo ao mais estreito no topo
const getGradientClass = (index) => {
  const grads = [
    'bg-slate-900',
    'bg-slate-800',
    'bg-slate-700',
    'bg-slate-600',
    'bg-slate-500'
  ]
  return grads[index] || 'bg-slate-900'
}

// Retorna cores sólidas no rodapé
const getSolidBgClass = (index) => {
  const solids = [
    'bg-slate-950',
    'bg-slate-850',
    'bg-slate-750',
    'bg-slate-650',
    'bg-slate-550'
  ]
  return solids[index] || 'bg-slate-950'
}
</script>

<style scoped>
.bg-slate-850 { background-color: #1e293b; }
.bg-slate-750 { background-color: #334155; }
.bg-slate-650 { background-color: #475569; }
.bg-slate-550 { background-color: #64748b; }
</style>
