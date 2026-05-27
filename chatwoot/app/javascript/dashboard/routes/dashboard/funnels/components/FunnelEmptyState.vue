<template>
  <div class="flex-1 flex flex-col items-center justify-center gap-6 p-8 text-center">
    <div class="size-20 rounded-2xl bg-n-alpha-1 flex items-center justify-center">
      <i class="i-lucide-kanban size-10 text-n-slate-9" aria-hidden="true" />
    </div>

    <div class="max-w-xs">
      <h2 class="text-base font-semibold text-n-slate-12 mb-1">
        {{ hasFunnels
            ? $t('funnels.empty_state.select_title')
            : $t('funnels.empty_state.no_funnels_title') }}
      </h2>
      <p class="text-sm text-n-slate-9">
        {{ hasFunnels
            ? $t('funnels.empty_state.select_desc')
            : $t('funnels.empty_state.no_funnels_desc') }}
      </p>
    </div>

    <button
      v-if="!hasFunnels"
      class="flex items-center gap-2 px-5 py-2.5 text-sm font-medium text-white
             bg-woot-500 rounded-lg hover:bg-woot-600 transition-colors"
      @click="$emit('create')"
    >
      <i class="i-lucide-plus size-4" aria-hidden="true" />
      {{ $t('funnels.empty_state.cta') }}
    </button>
  </div>
</template>

<script>
export default {
  name: 'FunnelEmptyState',
  props: {
    hasFunnels: { type: Boolean, default: false },
  },
  emits: ['create'],
};
</script>
