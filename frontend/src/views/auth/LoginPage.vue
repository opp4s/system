<template>
  <div class="space-y-6">
    <div class="text-center">
      <h2 class="text-2xl font-bold text-gray-900 tracking-tight">Entrar na sua conta</h2>
      <p class="text-sm text-gray-500 mt-2">
        Ou 
        <router-link :to="{ name: 'register' }" class="text-zavy-600 hover:text-zavy-700 font-semibold transition-colors duration-150">
          criar uma nova conta gratuitamente
        </router-link>
      </p>
    </div>

    <form @submit.prevent="handleSubmit" class="space-y-4 mt-6">
      <!-- Campo E-mail -->
      <div>
        <label for="email" class="block text-sm font-semibold text-gray-700">E-mail</label>
        <div class="mt-1 relative rounded-xl shadow-sm">
          <input
            id="email"
            v-model="form.email"
            type="email"
            required
            class="block w-full px-4 py-3 rounded-xl border border-gray-250 focus:outline-none focus:border-zavy-500 focus:ring-1 focus:ring-zavy-500 bg-gray-50/30 sm:text-sm text-gray-900 transition-all duration-150"
            :class="{ 'border-rose-300 focus:border-rose-500 focus:ring-rose-500 bg-rose-50/10': errors.email }"
            placeholder="seu@email.com"
          />
        </div>
        <p v-if="errors.email" class="text-xs text-rose-600 mt-1.5">{{ errors.email }}</p>
      </div>

      <!-- Campo Senha -->
      <div>
        <div class="flex justify-between items-center">
          <label for="password" class="block text-sm font-semibold text-gray-700">Senha</label>
          <router-link :to="{ name: 'forgot-password' }" class="text-xs font-semibold text-zavy-600 hover:text-zavy-700 transition-colors duration-150">
            Esqueci minha senha
          </router-link>
        </div>
        <div class="mt-1 relative rounded-xl shadow-sm">
          <input
            id="password"
            v-model="form.password"
            type="password"
            required
            class="block w-full px-4 py-3 rounded-xl border border-gray-250 focus:outline-none focus:border-zavy-500 focus:ring-1 focus:ring-zavy-500 bg-gray-50/30 sm:text-sm text-gray-900 transition-all duration-150"
            :class="{ 'border-rose-300 focus:border-rose-500 focus:ring-rose-500 bg-rose-50/10': errors.password }"
            placeholder="••••••••"
          />
        </div>
        <p v-if="errors.password" class="text-xs text-rose-600 mt-1.5">{{ errors.password }}</p>
      </div>

      <!-- Botão de Login -->
      <div class="pt-2">
        <button
          type="submit"
          :disabled="isLoading"
          class="w-full flex justify-center items-center px-4 py-3 rounded-xl bg-zavy-600 hover:bg-zavy-700 text-white font-semibold text-sm shadow-md hover:shadow-lg focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-zavy-500 transition-all duration-150 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          <!-- Spinner animado -->
          <svg v-if="isLoading" class="animate-spin -ml-1 mr-3 h-5 w-5 text-white" fill="none" viewBox="0 0 24 24">
            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
          </svg>
          <span>{{ isLoading ? 'Entrando...' : 'Entrar' }}</span>
        </button>
      </div>
    </form>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useToast } from '@/composables/useToast'

const router = useRouter()
const authStore = useAuthStore()
const toast = useToast()

const form = reactive({
  email: '',
  password: ''
})

const errors = reactive({
  email: '',
  password: ''
})

const isLoading = ref(false)

const validate = () => {
  let isValid = true
  errors.email = ''
  errors.password = ''

  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
  if (!form.email) {
    errors.email = 'E-mail é obrigatório.'
    isValid = false
  } else if (!emailRegex.test(form.email)) {
    errors.email = 'Insira um e-mail válido.'
    isValid = false
  }

  if (!form.password) {
    errors.password = 'Senha é obrigatória.'
    isValid = false
  } else if (form.password.length < 8) {
    errors.password = 'A senha deve conter no mínimo 8 caracteres.'
    isValid = false
  }

  return isValid
}

const handleSubmit = async () => {
  if (!validate()) return

  isLoading.value = true
  try {
    await authStore.login(form.email, form.password)
    toast.success('Login efetuado com sucesso!')
    router.push({ name: 'dashboard' })
  } catch (error) {
    toast.error(error.message || 'Falha ao autenticar. Verifique seus dados.')
  } finally {
    isLoading.value = false
  }
}
</script>
