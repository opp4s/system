<template>
  <div v-if="show" class="fixed inset-0 z-50 flex items-center justify-center p-4">
    <!-- Backdrop de fundo com desfoque -->
    <div 
      @click="close"
      class="absolute inset-0 bg-slate-900/60 backdrop-blur-sm transition-opacity duration-300"
    ></div>

    <!-- Container do Modal -->
    <div 
      class="relative bg-white rounded-3xl shadow-2xl max-w-lg w-full overflow-hidden p-6 z-10 animate-scale-up border border-gray-100 flex flex-col max-h-[90vh]"
    >
      <!-- Header -->
      <header class="flex items-center justify-between pb-4 border-b border-gray-105 shrink-0">
        <div>
          <h3 class="text-lg font-bold text-gray-900">Novo Negócio</h3>
          <p class="text-xs text-gray-400 mt-0.5">Cadastre uma nova oportunidade de venda no funil.</p>
        </div>
        <button 
          @click="close"
          class="p-2 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-xl transition-all duration-150"
        >
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
      </header>

      <!-- Formulário com scroll se necessário -->
      <form @submit.prevent="handleSubmit" class="flex-1 overflow-y-auto py-4 space-y-4 pr-1">
        <!-- Título do Negócio -->
        <div>
          <label for="card-title" class="block text-xs font-bold text-gray-700 uppercase tracking-wider mb-1">Título do Negócio *</label>
          <input
            id="card-title"
            v-model="form.title"
            type="text"
            required
            class="block w-full px-4 py-3 rounded-xl border border-gray-250 focus:outline-none focus:border-slate-800 focus:ring-1 focus:ring-slate-800 bg-gray-50/30 text-sm text-gray-900 transition-all"
            placeholder="Ex: Consultoria de TI, Licença Anual..."
            :class="{'border-rose-300 focus:border-rose-500 focus:ring-rose-500': errors.title}"
          />
          <p v-if="errors.title" class="text-xs text-rose-600 mt-1">{{ errors.title }}</p>
        </div>

        <!-- Grupo de Valor e Etapa -->
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <!-- Valor -->
          <div>
            <label for="card-value" class="block text-xs font-bold text-gray-700 uppercase tracking-wider mb-1">Valor (R$)</label>
            <input
              id="card-value"
              v-model.number="form.value"
              type="number"
              min="0"
              step="0.01"
              class="block w-full px-4 py-3 rounded-xl border border-gray-250 focus:outline-none focus:border-slate-800 focus:ring-1 focus:ring-slate-800 bg-gray-50/30 text-sm text-gray-900 transition-all"
              placeholder="0,00"
            />
          </div>

          <!-- Etapa Inicial -->
          <div>
            <label for="card-stage" class="block text-xs font-bold text-gray-700 uppercase tracking-wider mb-1">Etapa Inicial *</label>
            <select
              id="card-stage"
              v-model="form.stage_id"
              class="block w-full px-4 py-3 rounded-xl border border-gray-250 focus:outline-none focus:border-slate-800 focus:ring-1 focus:ring-slate-800 bg-gray-50/30 text-sm text-gray-950 transition-all font-semibold"
              :class="{'border-rose-300 focus:border-rose-500 focus:ring-rose-500': errors.stage_id}"
            >
              <option :value="null" disabled>Selecione uma etapa</option>
              <option 
                v-for="stage in pipelineStore.stages" 
                :key="stage.id" 
                :value="stage.id"
              >
                {{ stage.name }}
              </option>
            </select>
            <p v-if="errors.stage_id" class="text-xs text-rose-600 mt-1">{{ errors.stage_id }}</p>
          </div>
        </div>

        <!-- Separador -->
        <div class="border-t border-gray-100"></div>

        <!-- Informações do Contato -->
        <div class="space-y-3">
          <span class="text-xs font-bold text-gray-400 uppercase tracking-wider block">Contato Principal</span>

          <!-- Nome do Contato -->
          <div>
            <label for="contact-name" class="block text-[10px] font-bold text-gray-600 uppercase mb-0.5">Nome completo</label>
            <input
              id="contact-name"
              v-model="form.contact_name"
              type="text"
              class="block w-full px-4 py-2.5 rounded-xl border border-gray-250 focus:outline-none focus:border-slate-800 focus:ring-1 focus:ring-slate-800 bg-gray-50/30 text-sm text-gray-900 transition-all"
              placeholder="Ex: Carlos Souza"
            />
          </div>

          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <!-- Telefone -->
            <div>
              <label for="contact-phone" class="block text-[10px] font-bold text-gray-600 uppercase mb-0.5">Telefone / WhatsApp</label>
              <input
                id="contact-phone"
                v-model="form.contact_phone"
                type="text"
                class="block w-full px-4 py-2.5 rounded-xl border border-gray-250 focus:outline-none focus:border-slate-800 focus:ring-1 focus:ring-slate-800 bg-gray-50/30 text-sm text-gray-900 transition-all"
                placeholder="Ex: (11) 99999-9999"
              />
            </div>

            <!-- E-mail -->
            <div>
              <label for="contact-email" class="block text-[10px] font-bold text-gray-600 uppercase mb-0.5">E-mail</label>
              <input
                id="contact-email"
                v-model="form.contact_email"
                type="email"
                class="block w-full px-4 py-2.5 rounded-xl border border-gray-250 focus:outline-none focus:border-slate-800 focus:ring-1 focus:ring-slate-800 bg-gray-50/30 text-sm text-gray-900 transition-all"
                placeholder="Ex: carlos@empresa.com"
                :class="{'border-rose-300 focus:border-rose-500 focus:ring-rose-500': errors.email}"
              />
              <p v-if="errors.email" class="text-xs text-rose-600 mt-1">{{ errors.email }}</p>
            </div>
          </div>
        </div>
      </form>

      <!-- Rodapé / Ações -->
      <footer class="pt-4 border-t border-gray-100 flex items-center justify-end space-x-3 shrink-0">
        <button
          type="button"
          @click="close"
          class="px-4 py-2 border border-gray-200 rounded-xl text-sm font-semibold text-gray-600 hover:text-gray-900 hover:bg-gray-50 transition-all duration-150"
        >
          Cancelar
        </button>
        <button
          type="button"
          @click="handleSubmit"
          :disabled="pipelineStore.loading.mutation"
          class="px-5 py-2.5 bg-slate-900 hover:bg-slate-800 text-white rounded-xl text-sm font-semibold shadow-md shadow-slate-900/10 hover:shadow-lg transition-all duration-150 disabled:opacity-50 flex items-center space-x-2"
        >
          <svg v-if="pipelineStore.loading.mutation" class="animate-spin -ml-1 mr-2 h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
          </svg>
          <span>{{ pipelineStore.loading.mutation ? 'Salvando...' : 'Salvar Negócio' }}</span>
        </button>
      </footer>
    </div>
  </div>
</template>

<script setup>
import { reactive, watch } from 'vue'
import { usePipelineStore } from '@/stores/pipeline'
import { useToast } from '@/composables/useToast'

const props = defineProps({
  show: {
    type: Boolean,
    default: false
  },
  defaultStageId: {
    type: Number,
    default: null
  },
  initialContactData: {
    type: Object,
    default: null
  }
})

const emits = defineEmits(['close', 'created'])

const pipelineStore = usePipelineStore()
const toast = useToast()

const form = reactive({
  title: '',
  value: null,
  stage_id: null,
  contact_name: '',
  contact_phone: '',
  contact_email: ''
})

const errors = reactive({
  title: '',
  email: '',
  stage_id: ''
})

const resetForm = () => {
  form.title = ''
  form.value = null
  
  // Acha a primeira etapa intermediária (não ganha e não perdida)
  const firstActiveStage = pipelineStore.stages.find(
    s => s.stage_type !== 'win' && s.stage_type !== 'lost' && s.stage_type !== 'lose'
  ) || pipelineStore.stages[0]
  
  form.stage_id = props.defaultStageId || (firstActiveStage?.id || null)
  
  if (props.initialContactData) {
    form.contact_name = props.initialContactData.contact_name || ''
    form.contact_phone = props.initialContactData.contact_phone || ''
    form.contact_email = props.initialContactData.contact_email || ''
  } else {
    form.contact_name = ''
    form.contact_phone = ''
    form.contact_email = ''
  }
  
  errors.title = ''
  errors.email = ''
  errors.stage_id = ''
}

const validate = () => {
  let isValid = true
  errors.title = ''
  errors.email = ''
  errors.stage_id = ''

  if (!form.title.trim()) {
    errors.title = 'O título do negócio é obrigatório.'
    isValid = false
  }

  if (!form.stage_id) {
    errors.stage_id = 'A etapa inicial é obrigatória.'
    isValid = false
  }

  if (form.contact_email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
    if (!emailRegex.test(form.contact_email)) {
      errors.email = 'Insira um e-mail válido.'
      isValid = false
    }
  }

  return isValid
}

const handleSubmit = async () => {
  if (!validate()) return

  try {
    const newCard = await pipelineStore.createCard({
      title: form.title,
      value: form.value || 0,
      stage_id: form.stage_id,
      contact_name: form.contact_name,
      contact_phone: form.contact_phone,
      contact_email: form.contact_email
    })
    
    // Recarrega a store de contatos para incluir o contato criado/vinculado automaticamente
    if (form.contact_name) {
      try {
        const { useContactStore } = await import('@/stores/contact')
        const contactStore = useContactStore()
        await contactStore.fetchContacts()
      } catch (err) {
        console.warn('Erro ao atualizar store de contatos:', err)
      }
    }
    
    toast.success('Negócio cadastrado com sucesso!')
    emits('created', newCard)
    close()
  } catch (error) {
    toast.error('Falha ao cadastrar negócio. Tente novamente.')
  }
}

const close = () => {
  emits('close')
}

// Observa abertura do modal para resetar formulário
watch(() => props.show, (newVal) => {
  if (newVal) {
    resetForm()
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
