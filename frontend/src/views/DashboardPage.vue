<template>
  <div class="space-y-6">
    <!-- Título -->
    <div class="flex justify-between items-center">
      <h1 class="text-2xl font-semibold text-gray-900">Dashboard</h1>
    </div>

    <!-- Banner informativo do WhatsApp -->
    <div class="bg-zavy-50 border border-zavy-100 rounded-2xl p-6 flex items-start space-x-4">
      <div class="p-3 bg-zavy-500 text-white rounded-xl shadow-md">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
        </svg>
      </div>
      <div class="flex-1">
        <h3 class="text-base font-semibold text-zavy-950">Conecte seu WhatsApp para começar</h3>
        <p class="text-sm text-zavy-700 mt-1">Para habilitar a automação e o gerenciamento de leads em tempo real, conecte sua conta do WhatsApp por meio de QR Code.</p>
        <div class="mt-3">
          <button class="bg-zavy-600 hover:bg-zavy-700 text-white text-sm font-medium py-2 px-4 rounded-xl shadow-sm transition-all hover:shadow duration-200">
            Conectar Dispositivo
          </button>
        </div>
      </div>
    </div>

    <!-- Cards KPI -->
    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
      <div v-for="kpi in kpis" :key="kpi.title" class="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm flex flex-col justify-between">
        <div>
          <span class="text-xs font-semibold text-gray-400 uppercase tracking-wider">{{ kpi.title }}</span>
          <div class="text-3xl font-bold text-gray-900 mt-2">{{ kpi.value }}</div>
        </div>
        <div class="mt-4 flex items-center text-xs text-gray-400 font-medium">
          <span>Sem dados adicionais</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'

const kpis = ref([
  { title: 'Total Leads', value: '0' },
  { title: 'Valor Pipeline', value: 'R$ 0,00' },
  { title: 'Conversão', value: '0%' },
  { title: 'Tempo Médio', value: '0 min' }
])
</script>
