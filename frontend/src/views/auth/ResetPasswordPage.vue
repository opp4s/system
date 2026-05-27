<template>
  <div class="space-y-6">
    <div class="text-center">
      <h2 class="text-2xl font-bold text-gray-900 tracking-tight">Definir nova senha</h2>
      <p class="text-sm text-gray-500 mt-2">
        Escolha uma nova senha forte para acessar sua conta
      </p>
    </div>

    <form @submit.prevent="handleSubmit" class="space-y-4 mt-6">
      <!-- Campo Nova Senha -->
      <div>
        <label for="password" class="block text-sm font-semibold text-gray-700">Nova Senha</label>
        <div class="mt-1 relative rounded-xl shadow-sm">
          <input
            id="password"
            v-model="form.password"
            type="password"
            required
            class="block w-full px-4 py-3 rounded-xl border border-gray-250 focus:outline-none focus:border-zavy-500 focus:ring-1 focus:ring-zavy-500 bg-gray-50/30 sm:text-sm text-gray-900 transition-all duration-150"
            :class="{ 'border-rose-300 focus:border-rose-500 focus:ring-rose-500 bg-rose-50/10': errors.password }"
            placeholder="Mínimo de 8 caracteres"
          />
        </div>
        <p v-if="errors.password" class="text-xs text-rose-600 mt-1.5">{{ errors.password }}</p>
      </div>

      <!-- Campo Confirmar Nova Senha -->
      <div>
        <label for="password_confirmation" class="block text-sm font-semibold text-gray-700">Confirmar Nova Senha</label>
        <div class="mt-1 relative rounded-xl shadow-sm">
          <input
            id="password_confirmation"
            v-model="form.password_confirmation"
            type="password"
            required
            class="block w-full px-4 py-3 rounded-xl border border-gray-250 focus:outline-none focus:border-zavy-500 focus:ring-1 focus:ring-zavy-500 bg-gray-50/30 sm:text-sm text-gray-900 transition-all duration-150"
            :class="{ 'border-rose-300 focus:border-rose-500 focus:ring-rose-500 bg-rose-50/10': errors.password_confirmation }"
            placeholder="Repita a nova senha"
          />
        </div>
        <p v-if="errors.password_confirmation" class="text-xs text-rose-600 mt-1.5">{{ errors.password_confirmation }}</p>
      </div>

      <!-- Botão Redefinir -->
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
          <span>{{ isLoading ? 'Redefinindo...' : 'Redefinir senha' }}</span>
        </button>
      </div>
    </form>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useToast } from '@/composables/useToast'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()
const toast = useToast()

const form = reactive({
  password: '',
  password_confirmation: ''
})

const errors = reactive({
  password: '',
  password_confirmation: ''
})

const isLoading = ref(false)

const validate = () => {
  let isValid = true
  errors.password = ''
  errors.password_confirmation = ''

  if (!form.password) {
    errors.password = 'Nova senha é obrigatória.'
    isValid = false
  } else if (form.password.length < 8) {
    errors.password = 'A senha deve conter no mínimo 8 caracteres.'
    isValid = false
  }

  if (form.password !== form.password_confirmation) {
    errors.password_confirmation = 'As senhas não coincidem.'
    isValid = false
  }

  return isValid
}

const handleSubmit = async () => {
  if (!validate()) return

  const token = route.query.token || ''

  isLoading.value = true
  try {
    await authStore.resetPassword(token, form.password)
    toast.success('Senha redefinida com sucesso! Faça login para acessar.')
    router.push({ name: 'login' })
  } catch (error) {
    toast.error(error.message || 'Falha ao redefinir senha. Tente novamente.')
  } finally {
    isLoading.value = false
  }
}
</script>
