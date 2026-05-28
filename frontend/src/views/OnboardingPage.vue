<template>
  <div class="min-h-screen flex items-center justify-center bg-gray-50 px-4 py-12 sm:px-6 lg:px-8">
    <div class="max-w-md w-full space-y-8 bg-white p-8 sm:p-10 rounded-3xl shadow-xl border border-gray-100 text-center">
      <div class="flex flex-col items-center">
        <!-- Ícone animado -->
        <div class="p-3.5 bg-zavy-50 text-zavy-600 rounded-2xl shadow-inner mb-4 animate-bounce">
          <svg class="h-8 w-8 text-zavy-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M9 12l2 2 4-4M7.835 4.697a3.42 3.42 0 001.946-.806 3.42 3.42 0 014.438 0 3.42 3.42 0 001.946.806 3.42 3.42 0 013.138 3.138 3.42 3.42 0 00.806 1.946 3.42 3.42 0 010 4.438 3.42 3.42 0 00-.806 1.946 3.42 3.42 0 01-3.138 3.138 3.42 3.42 0 00-1.946.806 3.42 3.42 0 01-4.438 0 3.42 3.42 0 00-1.946-.806 3.42 3.42 0 01-3.138-3.138 3.42 3.42 0 00-.806-1.946 3.42 3.42 0 010-4.438 3.42 3.42 0 00.806-1.946 3.42 3.42 0 013.138-3.138z" />
          </svg>
        </div>
        <h2 class="text-2xl font-bold text-gray-900 tracking-tight">Bem-vindo ao Zavy CRM!</h2>
        <p class="text-sm text-gray-505 mt-2">Sua conta foi criada e configurada com sucesso.</p>
      </div>

      <div class="space-y-4 pt-4">
        <p class="text-sm text-gray-600 leading-relaxed">
          Prepare-se para otimizar seu funil de vendas, gerenciar seus contatos em massa e criar automações de conversas diretamente integradas ao seu WhatsApp.
        </p>
        
        <router-link 
          :to="{ name: 'dashboard' }" 
          class="w-full flex justify-center items-center px-4 py-3 rounded-xl bg-zavy-600 hover:bg-zavy-700 text-white font-semibold text-sm shadow-md hover:shadow-lg transition-all duration-150"
        >
          Acessar o Painel Principal
        </router-link>
      </div>
    </div>
  </div>
</template>

<script setup>
// Página de boas-vindas/Onboarding
</script>
