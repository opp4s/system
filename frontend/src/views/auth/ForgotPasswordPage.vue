<template>
  <div class="space-y-6">
    <div class="text-center">
      <h2 class="text-2xl font-bold text-gray-900 tracking-tight">Recuperar senha</h2>
      <p class="text-sm text-gray-500 mt-2">
        Digite seu e-mail de cadastro e enviaremos um link de recuperação
      </p>
    </div>

    <!-- Tela de Sucesso após envio -->
    <div v-if="isSent" class="space-y-6 mt-6">
      <div class="p-4 bg-emerald-50 border border-emerald-100 rounded-2xl text-emerald-800 flex items-start space-x-3">
        <svg class="h-6 w-6 text-emerald-500 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
        <div>
          <h4 class="font-bold text-emerald-950">Instruções enviadas!</h4>
          <p class="text-sm text-emerald-700 mt-1">Verifique a caixa de entrada do e-mail <strong>{{ form.email }}</strong> para redefinir sua senha.</p>
        </div>
      </div>
      
      <div class="text-center pt-2">
        <router-link :to="{ name: 'login' }" class="text-sm font-semibold text-zavy-600 hover:text-zavy-700 transition-colors duration-150">
          Voltar para o Login
        </router-link>
      </div>
    </div>

    <!-- Formulário Principal -->
    <form v-else @submit.prevent="handleSubmit" class="space-y-4 mt-6">
      <div>
        <label for="email" class="block text-sm font-semibold text-gray-700">E-mail de cadastro</label>
        <div class="mt-1 relative rounded-xl shadow-sm">
          <input
            id="email"
            v-model="form.email"
            type="email"
            required
            class="block w-full px-4 py-3 rounded-xl border border-gray-250 focus:outline-none focus:border-zavy-500 focus:ring-1 focus:ring-zavy-500 bg-gray-50/30 sm:text-sm text-gray-900 transition-all duration-150"
            :class="{ 'border-rose-300 focus:border-rose-500 focus:ring-rose-500 bg-rose-50/10': errorMsg }"
            placeholder="seu@email.com"
          />
        </div>
        <p v-if="errorMsg" class="text-xs text-rose-600 mt-1.5">{{ errorMsg }}</p>
      </div>

      <div class="pt-2">
        <button
          type="submit"
          :disabled="isLoading"
          class="w-full flex justify-center items-center px-4 py-3 rounded-xl bg-zavy-600 hover:bg-zavy-700 text-white font-semibold text-sm shadow-md hover:shadow-lg focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-zavy-500 transition-all duration-150 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          <!-- Spinner -->
          <svg v-if="isLoading" class="animate-spin -ml-1 mr-3 h-5 w-5 text-white" fill="none" viewBox="0 0 24 24">
            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
          </svg>
          <span>{{ isLoading ? 'Enviando...' : 'Enviar link de recuperação' }}</span>
        </button>
      </div>

      <div class="text-center pt-2">
        <router-link :to="{ name: 'login' }" class="text-sm font-semibold text-gray-500 hover:text-gray-700 transition-colors duration-150">
          Voltar para o Login
        </router-link>
      </div>
    </form>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { useToast } from '@/composables/useToast'

const authStore = useAuthStore()
const toast = useToast()

const form = reactive({
  email: ''
})

const errorMsg = ref('')
const isLoading = ref(false)
const isSent = ref(false)

const handleSubmit = async () => {
  errorMsg.value = ''
  
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
  if (!form.email || !emailRegex.test(form.email)) {
    errorMsg.value = 'Por favor, insira um e-mail válido.'
    return
  }

  isLoading.value = true
  try {
    await authStore.forgotPassword(form.email)
    isSent.value = true
    toast.success('Instruções de recuperação enviadas com sucesso!')
  } catch (error) {
    errorMsg.value = error.message || 'Erro ao enviar. Tente novamente.'
    toast.error(errorMsg.value)
  } finally {
    isLoading.value = false
  }
}
</script>
