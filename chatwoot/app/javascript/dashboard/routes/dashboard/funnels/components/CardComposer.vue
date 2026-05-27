<template>
  <div
    class="border-t border-n-weak flex-shrink-0 bg-n-solid-1"
    :class="mode === 'note' ? 'bg-amber-50/20' : ''"
  >

    <!-- ── Mode toggle ────────────────────────────────────────────────────── -->
    <div class="flex items-center gap-1 px-4 pt-3 pb-2">
      <button
        class="flex items-center gap-1.5 px-3 py-1.5 text-xs rounded-full transition-colors font-medium"
        :class="mode === 'message'
          ? 'bg-woot-100 text-woot-700 dark:bg-woot-900/30 dark:text-woot-400'
          : 'text-n-slate-9 hover:bg-n-alpha-2'"
        @click="mode = 'message'"
      >
        <i class="i-lucide-message-circle size-3.5" aria-hidden="true" />
        {{ $t('funnels.composer.mode_message') }}
      </button>
      <button
        class="flex items-center gap-1.5 px-3 py-1.5 text-xs rounded-full transition-colors font-medium"
        :class="mode === 'note'
          ? 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400'
          : 'text-n-slate-9 hover:bg-n-alpha-2'"
        @click="mode = 'note'"
      >
        <i class="i-lucide-sticky-note size-3.5" aria-hidden="true" />
        {{ $t('funnels.composer.mode_note') }}
      </button>
    </div>

    <!-- ── No primary conversation ────────────────────────────────────────── -->
    <div v-if="!primaryConversationId" class="px-4 pb-4">
      <p class="text-xs text-n-slate-8 italic leading-relaxed">
        <i class="i-lucide-info size-3.5 inline mr-1 align-[-2px]" aria-hidden="true" />
        {{ $t('funnels.composer.no_conversation') }}
      </p>
    </div>

    <!-- ── Textarea + send button ─────────────────────────────────────────── -->
    <div v-else class="px-4 pb-4">
      <div
        class="flex gap-2 rounded-xl border transition-colors overflow-hidden"
        :class="mode === 'note'
          ? 'border-amber-200 bg-amber-50/50 dark:border-amber-800/40 dark:bg-amber-900/10'
          : 'border-n-weak bg-n-solid-1 focus-within:border-woot-400'"
      >
        <textarea
          ref="textarea"
          v-model="text"
          rows="3"
          class="flex-1 px-3 py-2.5 text-sm bg-transparent resize-none outline-none
                 text-n-slate-12 placeholder:text-n-slate-7 min-h-[76px] max-h-[200px]"
          :placeholder="mode === 'note'
            ? $t('funnels.composer.note_placeholder')
            : $t('funnels.composer.message_placeholder')"
          @keydown.ctrl.enter.exact.prevent="send"
          @keydown.meta.enter.exact.prevent="send"
          @input="autoResize"
        />
        <div class="flex flex-col items-end justify-end pb-2 pr-2 gap-1.5">
          <button
            :disabled="!text.trim() || sending"
            class="p-1.5 rounded-lg transition-colors disabled:opacity-40 flex-shrink-0"
            :class="mode === 'note'
              ? 'bg-amber-500 hover:bg-amber-600 text-white'
              : 'bg-woot-500 hover:bg-woot-600 text-white'"
            :aria-label="$t('funnels.composer.send_aria')"
            @click="send"
          >
            <i
              v-if="sending"
              class="i-lucide-loader-circle animate-spin size-4"
              aria-hidden="true"
            />
            <i v-else class="i-lucide-send size-4" aria-hidden="true" />
          </button>
        </div>
      </div>
      <p class="text-xs text-n-slate-7 mt-1.5">
        {{ $t('funnels.composer.send_hint') }}
      </p>
    </div>

  </div>
</template>

<script>
import axios from 'axios';
import { useFunnelToast } from '../composables/useFunnelToast';

export default {
  name: 'CardComposer',

  setup() {
    const { success, error } = useFunnelToast();
    return { toastSuccess: success, toastError: error };
  },

  props: {
    primaryConversationId: { type: [Number, String], default: null },
  },

  emits: ['sent'],

  data() {
    return {
      mode:    'message',   // 'message' | 'note'
      text:    '',
      sending: false,
    };
  },

  methods: {
    autoResize() {
      const el = this.$refs.textarea;
      if (!el) return;
      el.style.height = 'auto';
      el.style.height = Math.min(el.scrollHeight, 200) + 'px';
    },

    async send() {
      const content = this.text.trim();
      if (!content || this.sending || !this.primaryConversationId) return;

      this.sending = true;
      const accountId = this.$store.getters['getCurrentAccountId'];

      try {
        await axios.post(
          `/api/v1/accounts/${accountId}/conversations/${this.primaryConversationId}/messages`,
          {
            content,
            message_type: 'outgoing',
            private:      this.mode === 'note',
            content_type: 'text',
          }
        );
        this.text = '';
        this.$nextTick(() => {
          if (this.$refs.textarea) this.$refs.textarea.style.height = 'auto';
        });
        this.toastSuccess(this.$t('funnels.composer.sent_success'));
        this.$emit('sent');
      } catch {
        this.toastError(this.$t('funnels.composer.sent_error'));
      } finally {
        this.sending = false;
      }
    },
  },
};
</script>
