<template>
  <div class="space-y-6">
    <div class="text-center">
      <h2 class="text-2xl font-bold text-gray-900 tracking-tight">Criar uma nova conta</h2>
      <p class="text-sm text-gray-500 mt-2">
        Ou 
        <router-link :to="{ name: 'login' }" class="text-zavy-600 hover:text-zavy-700 font-semibold transition-colors duration-150">
          entrar na sua conta existente
        </router-link>
      </p>
    </div>

    <form @submit.prevent="handleSubmit" class="space-y-4 mt-6">
      <!-- Campo Nome Completo -->
      <div>
        <label for="name" class="block text-sm font-semibold text-gray-700">Nome completo</label>
        <div class="mt-1 relative rounded-xl shadow-sm">
          <input
            id="name"
            v-model="form.name"
            type="text"
            required
            class="block w-full px-4 py-3 rounded-xl border border-gray-250 focus:outline-none focus:border-zavy-500 focus:ring-1 focus:ring-zavy-500 bg-gray-50/30 sm:text-sm text-gray-900 transition-all duration-150"
            :class="{ 'border-rose-300 focus:border-rose-500 focus:ring-rose-500 bg-rose-50/10': errors.name }"
            placeholder="Seu nome completo"
          />
        </div>
        <p v-if="errors.name" class="text-xs text-rose-600 mt-1.5">{{ errors.name }}</p>
      </div>

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
        <label for="password" class="block text-sm font-semibold text-gray-700">Senha</label>
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

      <!-- Campo Confirmar Senha -->
      <div>
        <label for="password_confirmation" class="block text-sm font-semibold text-gray-700">Confirmar Senha</label>
        <div class="mt-1 relative rounded-xl shadow-sm">
          <input
            id="password_confirmation"
            v-model="form.password_confirmation"
            type="password"
            required
            class="block w-full px-4 py-3 rounded-xl border border-gray-250 focus:outline-none focus:border-zavy-500 focus:ring-1 focus:ring-zavy-500 bg-gray-50/30 sm:text-sm text-gray-900 transition-all duration-150"
            :class="{ 'border-rose-300 focus:border-rose-500 focus:ring-rose-500 bg-rose-50/10': errors.password_confirmation }"
            placeholder="Repita sua senha"
          />
        </div>
        <p v-if="errors.password_confirmation" class="text-xs text-rose-600 mt-1.5">{{ errors.password_confirmation }}</p>
      </div>

      <!-- Termos de Serviço Checkbox -->
      <div class="flex items-start">
        <div class="flex items-center h-5">
          <input
            id="terms"
            v-model="form.terms"
            type="checkbox"
            required
            class="focus:ring-zavy-500 h-4 w-4 text-zavy-600 border-gray-300 rounded-lg transition-colors duration-150"
          />
        </div>
        <div class="ml-3 text-xs">
          <label for="terms" class="font-medium text-gray-650">
            Eu aceito os 
            <a href="#" class="text-zavy-600 hover:text-zavy-700 font-semibold underline">Termos de Serviço</a> 
            e a 
            <a href="#" class="text-zavy-600 hover:text-zavy-700 font-semibold underline">Política de Privacidade</a>.
          </label>
          <p v-if="errors.terms" class="text-xs text-rose-600 mt-1">{{ errors.terms }}</p>
        </div>
      </div>

      <!-- Botão Criar Conta -->
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
          <span>{{ isLoading ? 'Criando conta...' : 'Criar conta' }}</span>
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
  name: '',
  email: '',
  password: '',
  password_confirmation: '',
  terms: false
})

const errors = reactive({
  name: '',
  email: '',
  password: '',
  password_confirmation: '',
  terms: ''
})

const isLoading = ref(false)

const validate = () => {
  let isValid = true
  errors.name = ''
  errors.email = ''
  errors.password = ''
  errors.password_confirmation = ''
  errors.terms = ''

  if (!form.name.trim()) {
    errors.name = 'Nome completo é obrigatório.'
    isValid = false
  }

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

  if (form.password !== form.password_confirmation) {
    errors.password_confirmation = 'As senhas não coincidem.'
    isValid = false
  }

  if (!form.terms) {
    errors.terms = 'Você deve aceitar os Termos de Serviço.'
    isValid = false
  }

  return isValid
}

const handleSubmit = async () => {
  if (!validate()) return

  isLoading.value = true
  try {
    await authStore.register(form.name, form.email, form.password)
    toast.success('Cadastro efetuado com sucesso!')
    router.push({ name: 'onboarding' })
  } catch (error) {
    toast.error(error.message || 'Falha ao criar conta. Tente novamente.')
  } finally {
    isLoading.value = false
  }
}
</script>
