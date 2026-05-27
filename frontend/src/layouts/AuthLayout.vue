<template>
  <div class="min-h-screen flex items-center justify-center bg-gradient-to-tr from-slate-950 via-slate-900 to-indigo-950 px-4 py-12 sm:px-6 lg:px-8">
    <div class="max-w-md w-full space-y-8 bg-white p-8 sm:p-10 rounded-3xl shadow-2xl border border-gray-100 flex flex-col">
      <!-- Logo do Zavy CRM -->
      <div class="flex flex-col items-center">
        <div class="flex items-center space-x-2 text-3xl font-extrabold tracking-tight text-gray-900">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-9 w-9 text-zavy-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M13 10V3L4 14h7v7l9-11h-7z" />
          </svg>
          <span>Zavy<span class="text-zavy-500">.</span></span>
        </div>
      </div>
      
      <!-- Renderiza as páginas filhas (login, register, etc.) -->
      <div class="mt-6 flex-1">
        <router-view />
      </div>
    </div>
  </div>
</template>

<script setup>
// Layout para telas de Autenticação (Login, Cadastro, Esqueci a Senha)
</script>
