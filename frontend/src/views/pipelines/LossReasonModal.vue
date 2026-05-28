<template>
  <div v-if="show" class="fixed inset-0 z-[100] flex items-center justify-center p-4">
    <!-- Backdrop com desfoque -->
    <div 
      @click="cancel"
      class="absolute inset-0 bg-slate-900/60 backdrop-blur-sm transition-opacity duration-300"
    ></div>

    <!-- Container do Modal -->
    <div 
      class="relative bg-white rounded-3xl shadow-2xl max-w-md w-full overflow-hidden p-6 z-10 animate-scale-up border border-gray-100"
    >
      <!-- Header -->
      <header class="flex items-center justify-between pb-4 border-b border-gray-100">
        <div class="flex items-center space-x-2 text-rose-600">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
          </svg>
          <h3 class="text-base font-extrabold text-gray-900">Perder Oportunidade</h3>
        </div>
        <button 
          @click="cancel"
          class="p-1 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-lg transition-colors"
        >
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
      </header>

      <!-- Corpo -->
      <main class="py-4 space-y-4">
        <p class="text-xs text-gray-500">
          Você está movendo o lead <strong class="text-gray-800">{{ cardTitle }}</strong> para a coluna de perda. Por favor, descreva o motivo da perda.
        </p>

        <!-- Botões de Motivos Rápidos -->
        <div>
          <label class="text-[10px] font-bold text-gray-400 uppercase tracking-wider block mb-2">Motivos comuns</label>
          <div class="flex flex-wrap gap-2">
            <button 
              v-for="reason in QUICK_REASONS" 
              :key="reason"
              type="button"
              @click="setQuickReason(reason)"
              class="px-3 py-1.5 text-xs font-semibold rounded-xl border border-gray-250 bg-gray-50 hover:bg-gray-100 text-gray-700 transition-all duration-150"
              :class="{'border-rose-500 bg-rose-50/20 text-rose-700': formReason === reason}"
            >
              {{ reason }}
            </button>
          </div>
        </div>

        <!-- Campo Texto livre -->
        <div>
          <label for="reason-input" class="text-[10px] font-bold text-gray-400 uppercase tracking-wider block mb-1.5">Justificativa Detalhada</label>
          <textarea
            id="reason-input"
            v-model="formReason"
            rows="3"
            required
            class="block w-full px-4 py-3 rounded-xl border border-gray-250 focus:outline-none focus:border-rose-500 focus:ring-1 focus:ring-rose-500 bg-gray-50/30 text-sm text-gray-900 placeholder-gray-400 transition-all duration-150"
            placeholder="Descreva detalhadamente o motivo da perda..."
          ></textarea>
        </div>
      </main>

      <!-- Rodapé / Ações -->
      <footer class="pt-4 border-t border-gray-100 flex items-center justify-end space-x-3">
        <button
          type="button"
          @click="cancel"
          class="px-4 py-2 border border-gray-200 rounded-xl text-sm font-semibold text-gray-600 hover:text-gray-900 hover:bg-gray-50 transition-all"
        >
          Cancelar
        </button>
        <button
          type="button"
          @click="confirm"
          :disabled="!formReason.trim()"
          class="px-4 py-2 bg-rose-600 hover:bg-rose-700 disabled:bg-rose-400 text-white rounded-xl text-sm font-semibold shadow-md shadow-rose-600/10 hover:shadow-lg transition-all disabled:cursor-not-allowed"
        >
          Confirmar Perda
        </button>
      </footer>
    </div>
  </div>
</template>

<script setup>
import { ref, watch } from 'vue'

const props = defineProps({
  show: {
    type: Boolean,
    default: false
  },
  cardTitle: {
    type: String,
    default: 'Negócio'
  }
})

const emits = defineEmits(['confirm', 'cancel'])

const QUICK_REASONS = [
  'Preço muito alto',
  'Sem resposta (ghosting)',
  'Comprou do concorrente',
  'Sem fit técnico',
  'Sem orçamento/Budget',
  'Decidiu adiar projeto'
]

const formReason = ref('')

const setQuickReason = (reason) => {
  formReason.value = reason
}

const confirm = () => {
  if (formReason.value.trim()) {
    emits('confirm', formReason.value.trim())
  }
}

const cancel = () => {
  emits('cancel')
}

// Reseta o campo quando o modal abre/fecha
watch(() => props.show, (newVal) => {
  if (newVal) {
    formReason.value = ''
  }
})
</script>

<style scoped>
@keyframes scaleUp {
  from {
    opacity: 0;
    transform: scale(0.95);
  }
  to {
    opacity: 1;
    transform: scale(1);
  }
}
.animate-scale-up {
  animation: scaleUp 0.2s cubic-bezier(0.16, 1, 0.3, 1) forwards;
}
</style>
