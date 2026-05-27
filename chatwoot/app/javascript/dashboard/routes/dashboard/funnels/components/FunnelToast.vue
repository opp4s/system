<template>
  <Teleport to="body">
    <div
      aria-live="polite"
      aria-atomic="false"
      class="fixed bottom-5 right-5 z-[9999] flex flex-col gap-2 pointer-events-none"
    >
      <TransitionGroup
        enter-active-class="transition-all duration-300 ease-out"
        enter-from-class="opacity-0 translate-y-2 scale-95"
        enter-to-class="opacity-100 translate-y-0 scale-100"
        leave-active-class="transition-all duration-200 ease-in"
        leave-from-class="opacity-100 translate-y-0 scale-100"
        leave-to-class="opacity-0 translate-y-1 scale-95"
        tag="div"
        class="flex flex-col gap-2"
      >
        <div
          v-for="toast in toasts"
          :key="toast.id"
          class="flex items-center gap-3 px-4 py-3 rounded-xl shadow-lg text-sm font-medium pointer-events-auto max-w-sm"
          :class="toastClass(toast.type)"
          role="alert"
        >
          <i :class="toastIcon(toast.type)" class="size-4 flex-shrink-0" />
          <span>{{ toast.message }}</span>
          <button
            class="ml-auto flex-shrink-0 opacity-60 hover:opacity-100 transition-opacity"
            :aria-label="$t('funnels.close')"
            @click="dismiss(toast.id)"
          >
            <i class="i-lucide-x size-3.5" />
          </button>
        </div>
      </TransitionGroup>
    </div>
  </Teleport>
</template>

<script>
import { useFunnelToast } from '../composables/useFunnelToast';

export default {
  name: 'FunnelToast',
  setup() {
    const { toasts, dismiss } = useFunnelToast();
    return { toasts, dismiss };
  },
  methods: {
    toastClass(type) {
      return {
        success: 'bg-green-50 text-green-800 border border-green-200',
        error:   'bg-red-50   text-red-800   border border-red-200',
        info:    'bg-blue-50  text-blue-800  border border-blue-200',
      }[type] || 'bg-n-solid-1 text-n-slate-12 border border-n-weak';
    },
    toastIcon(type) {
      return {
        success: 'i-lucide-check-circle',
        error:   'i-lucide-alert-circle',
        info:    'i-lucide-info',
      }[type] || 'i-lucide-bell';
    },
  },
};
</script>
