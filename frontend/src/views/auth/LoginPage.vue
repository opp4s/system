<template>
  <div class="text-center">
    <h2 class="text-2xl font-bold text-gray-900">Entrar na sua conta</h2>
    <p class="text-sm text-gray-600 mt-2">Acesse o Zavy CRM</p>
    <div class="mt-6 text-left">
      <!-- Form placeholder -->
      <div class="space-y-4">
        <div>
          <label class="block text-sm font-medium text-gray-700">E-mail</label>
          <input type="email" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-zavy-500 focus:ring-zavy-500 sm:text-sm" placeholder="seu@email.com" disabled />
        </div>
        <div>
          <label class="block text-sm font-medium text-gray-700">Senha</label>
          <input type="password" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-zavy-500 focus:ring-zavy-500 sm:text-sm" placeholder="••••••••" disabled />
        </div>
        <button class="w-full bg-zavy-600 hover:bg-zavy-700 text-white font-medium py-2 px-4 rounded-md shadow-sm text-sm focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-zavy-500 opacity-60 cursor-not-allowed" disabled>
          Entrar
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
// Placeholder para a página de Login (refinada no Dia 2)
</script>
