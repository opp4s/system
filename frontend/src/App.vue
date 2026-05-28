<template>
  <div class="h-full relative font-sans">
    <!-- Roteamento Principal -->
    <router-view v-slot="{ Component }">
      <transition name="fade" mode="out-in">
        <component :is="Component" />
      </transition>
    </router-view>

    <!-- Container Global de Notificações Toast -->
    <div class="fixed top-4 right-4 z-50 pointer-events-none flex flex-col space-y-2 max-w-sm w-full">
      <transition-group name="toast-list">
        <div 
          v-for="toast in uiStore.toasts" 
          :key="toast.id" 
          class="pointer-events-auto flex items-center p-4 rounded-2xl shadow-xl border transition-all duration-300 bg-white"
          :class="{
            'bg-emerald-50/90 backdrop-blur-sm border-emerald-100 text-emerald-900': toast.type === 'success',
            'bg-rose-50/90 backdrop-blur-sm border-rose-100 text-rose-900': toast.type === 'error',
            'bg-amber-50/90 backdrop-blur-sm border-amber-100 text-amber-900': toast.type === 'warning',
            'bg-sky-50/90 backdrop-blur-sm border-sky-100 text-sky-900': toast.type === 'info'
          }"
        >
          <!-- Ícone do tipo -->
          <div class="mr-3 shrink-0">
            <!-- Sucesso -->
            <svg v-if="toast.type === 'success'" class="h-5 w-5 text-emerald-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <!-- Erro -->
            <svg v-else-if="toast.type === 'error'" class="h-5 w-5 text-rose-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <!-- Aviso -->
            <svg v-else-if="toast.type === 'warning'" class="h-5 w-5 text-amber-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
            </svg>
            <!-- Info -->
            <svg v-else class="h-5 w-5 text-sky-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
          
          <!-- Conteúdo -->
          <span class="text-sm font-semibold leading-5">{{ toast.message }}</span>
          
          <!-- Botão Fechar -->
          <button @click="uiStore.removeToast(toast.id)" class="ml-auto pl-3 text-gray-400 hover:text-gray-600 focus:outline-none transition-colors shrink-0">
            <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>
      </transition-group>
    </div>
  </div>
</template>

<script setup>
import { useUiStore } from '@/stores/ui'

const uiStore = useUiStore()
</script>

<style>
/* Animação do Toast (Transições) */
.toast-list-enter-active,
.toast-list-leave-active {
  transition: all 0.25s cubic-bezier(0.4, 0, 0.2, 1);
}
.toast-list-enter-from {
  opacity: 0;
  transform: translateY(-15px) scale(0.95);
}
.toast-list-leave-to {
  opacity: 0;
  transform: translateY(-5px) scale(0.98);
}
</style>
