<template>
  <div
    class="fixed inset-0 z-50 flex items-center justify-center bg-black/40"
    role="dialog"
    :aria-modal="true"
    :aria-label="$t('funnels.lost_modal.title')"
    @click.self="cancel"
  >
    <div class="bg-n-solid-1 rounded-xl shadow-xl w-full max-w-sm mx-4 p-6">
      <h2 class="text-base font-semibold text-n-slate-12 mb-1">
        {{ $t('funnels.lost_modal.title') }}
      </h2>
      <p class="text-sm text-n-slate-9 mb-4">
        {{ $t('funnels.lost_modal.hint') }}
      </p>
      <input
        ref="input"
        v-model="reason"
        type="text"
        :placeholder="$t('funnels.lost_modal.placeholder')"
        class="w-full px-3 py-2 text-sm border border-n-weak rounded-lg bg-n-solid-1
               text-n-slate-12 placeholder-n-slate-9 focus:outline-none focus:border-woot-400 mb-4"
        @keyup.enter="confirm"
        @keyup.esc="cancel"
      />
      <div class="flex gap-3">
        <button
          class="flex-1 px-4 py-2 text-sm border border-n-weak rounded-lg
                 text-n-slate-11 hover:bg-n-alpha-1 transition-colors"
          @click="cancel"
        >
          {{ $t('funnels.cancel') }}
        </button>
        <button
          class="flex-1 px-4 py-2 text-sm font-medium text-white bg-red-500
                 rounded-lg hover:bg-red-600 transition-colors"
          @click="confirm"
        >
          {{ $t('funnels.lost_modal.confirm') }}
        </button>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'LostReasonModal',
  emits: ['confirm', 'cancel'],
  data() {
    return { reason: '' };
  },
  mounted() {
    this.$nextTick(() => this.$refs.input?.focus());
  },
  methods: {
    confirm() {
      this.$emit('confirm', this.reason.trim());
      this.reason = '';
    },
    cancel() {
      this.$emit('cancel');
      this.reason = '';
    },
  },
};
</script>
