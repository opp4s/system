<template>
  <!-- Backdrop -->
  <div
    class="fixed inset-0 z-[60] flex items-end sm:items-center justify-center bg-black/40 backdrop-blur-sm"
    role="dialog"
    aria-modal="true"
    :aria-label="$t('funnels.linker.title')"
    @click.self="$emit('close')"
    @keyup.esc="$emit('close')"
  >
    <div
      class="w-full sm:w-[520px] max-h-[80vh] bg-n-solid-1 rounded-t-2xl sm:rounded-2xl
             shadow-2xl flex flex-col overflow-hidden
             animate-[fadeSlideUp_0.2s_ease-out]"
    >

      <!-- Header -->
      <div class="flex items-center justify-between px-5 py-4 border-b border-n-weak flex-shrink-0">
        <div class="flex items-center gap-2">
          <i class="i-lucide-link size-4 text-woot-500" aria-hidden="true" />
          <h3 class="text-sm font-semibold text-n-slate-12">
            {{ $t('funnels.linker.title') }}
          </h3>
        </div>
        <button
          class="text-n-slate-9 hover:text-n-slate-12 transition-colors"
          :aria-label="$t('funnels.linker.close_aria')"
          @click="$emit('close')"
        >
          <i class="i-lucide-x size-4" aria-hidden="true" />
        </button>
      </div>

      <!-- Already linked conversations -->
      <div
        v-if="linkedConversations.length"
        class="flex-shrink-0 px-5 pt-4 pb-2"
      >
        <p class="text-xs font-medium text-n-slate-9 uppercase tracking-wide mb-2">
          {{ $t('funnels.card_detail.conversations_label') }}
        </p>
        <div class="flex flex-col gap-1">
          <div
            v-for="conv in linkedConversations"
            :key="conv.id"
            class="flex items-center gap-3 py-1.5 px-2 rounded-lg hover:bg-n-alpha-1
                   transition-colors group"
          >
            <i class="i-lucide-message-square size-3.5 text-woot-500 flex-shrink-0" aria-hidden="true" />
            <span class="flex-1 text-sm text-n-slate-12 min-w-0 truncate">
              #{{ conv.id }}
              <span v-if="conv.meta?.sender?.name" class="text-n-slate-9">
                — {{ conv.meta.sender.name }}
              </span>
            </span>
            <span
              v-if="conv.is_primary"
              class="text-xs text-woot-600 font-medium flex-shrink-0"
            >
              {{ $t('funnels.card_detail.primary_badge') }}
            </span>
            <button
              class="opacity-0 group-hover:opacity-100 transition-opacity text-xs text-red-500
                     hover:text-red-700 px-2 py-0.5 rounded flex-shrink-0"
              :aria-label="`${$t('funnels.linker.unlink_aria')} #${conv.id}`"
              :disabled="unlinkingId === conv.id"
              @click="unlink(conv.id)"
            >
              <i
                v-if="unlinkingId === conv.id"
                class="i-lucide-loader-circle animate-spin size-3"
                aria-hidden="true"
              />
              <span v-else>{{ $t('funnels.linker.unlink_btn') }}</span>
            </button>
          </div>
        </div>
        <div class="border-t border-n-weak mt-3" />
      </div>

      <!-- Search input -->
      <div class="px-5 py-3 flex-shrink-0">
        <div class="relative">
          <i
            class="i-lucide-search absolute left-3 top-1/2 -translate-y-1/2
                   size-4 text-n-slate-8 pointer-events-none"
            aria-hidden="true"
          />
          <input
            ref="searchInput"
            v-model="query"
            type="search"
            class="w-full pl-9 pr-4 py-2 text-sm border border-n-weak rounded-lg
                   bg-n-solid-1 text-n-slate-12 outline-none focus:border-woot-400
                   transition-colors placeholder:text-n-slate-7"
            :placeholder="$t('funnels.linker.search_placeholder')"
            @input="onSearchInput"
          />
        </div>
      </div>

      <!-- Results -->
      <div class="flex-1 overflow-y-auto px-5 pb-4 min-h-[120px]">

        <!-- Loading -->
        <div v-if="searching" class="flex items-center gap-2 py-4 text-sm text-n-slate-9">
          <i class="i-lucide-loader-circle animate-spin size-4" aria-hidden="true" />
          {{ $t('funnels.linker.searching') }}
        </div>

        <!-- Empty state -->
        <div
          v-else-if="results.length === 0 && query.length >= 2"
          class="flex flex-col items-center py-8 text-center"
        >
          <i class="i-lucide-search-x size-7 text-n-slate-8 mb-2" aria-hidden="true" />
          <p class="text-sm text-n-slate-9">{{ $t('funnels.linker.no_results') }}</p>
        </div>

        <!-- Hint — type to search -->
        <div
          v-else-if="!results.length && query.length < 2"
          class="flex flex-col items-center py-8 text-center"
        >
          <i class="i-lucide-message-circle size-7 text-n-slate-8 mb-2" aria-hidden="true" />
          <p class="text-sm text-n-slate-9">{{ $t('funnels.linker.search_placeholder') }}</p>
        </div>

        <!-- Results list -->
        <ul v-else class="flex flex-col gap-1">
          <li
            v-for="conv in results"
            :key="conv.id"
            class="flex items-center gap-3 px-3 py-2.5 rounded-lg hover:bg-n-alpha-1
                   transition-colors group"
          >
            <!-- Channel icon -->
            <div
              class="size-8 rounded-full flex items-center justify-center flex-shrink-0"
              :class="channelColor(conv)"
            >
              <i :class="channelIcon(conv)" class="size-3.5" aria-hidden="true" />
            </div>

            <!-- Info -->
            <div class="flex-1 min-w-0">
              <div class="flex items-center gap-1.5 min-w-0">
                <span class="text-sm font-medium text-n-slate-12">#{{ conv.id }}</span>
                <span
                  class="text-xs px-1.5 py-0.5 rounded-full"
                  :class="statusClass(conv.status)"
                >
                  {{ $t(`funnels.linker.status_${conv.status || 'open'}`) }}
                </span>
              </div>
              <p v-if="conv.meta?.sender?.name" class="text-xs text-n-slate-9 truncate">
                {{ $t('funnels.linker.contact') }}: {{ conv.meta.sender.name }}
              </p>
            </div>

            <!-- Link button -->
            <button
              :disabled="linkingId === conv.id || isAlreadyLinked(conv.id)"
              class="flex-shrink-0 px-3 py-1 text-xs rounded-lg font-medium transition-colors
                     disabled:opacity-50"
              :class="isAlreadyLinked(conv.id)
                ? 'bg-n-alpha-2 text-n-slate-9 cursor-default'
                : 'bg-woot-500 hover:bg-woot-600 text-white'"
              :aria-label="`${$t('funnels.linker.link_aria')} #${conv.id}`"
              @click="link(conv.id)"
            >
              <i
                v-if="linkingId === conv.id"
                class="i-lucide-loader-circle animate-spin size-3"
                aria-hidden="true"
              />
              <span v-else-if="isAlreadyLinked(conv.id)">✓</span>
              <span v-else>{{ $t('funnels.linker.link_btn') }}</span>
            </button>
          </li>
        </ul>
      </div>

    </div>
  </div>
</template>

<script>
import axios from 'axios';
import { useFunnelToast } from '../composables/useFunnelToast';

export default {
  name: 'ConversationLinker',

  setup() {
    const { success, error } = useFunnelToast();
    return { toastSuccess: success, toastError: error };
  },

  props: {
    cardId:               { type: [Number, String], required: true },
    funnelId:             { type: [Number, String], required: true },
    linkedConversations:  { type: Array, default: () => [] },
  },

  emits: ['close', 'linked', 'unlinked'],

  data() {
    return {
      query:      '',
      results:    [],
      searching:  false,
      linkingId:  null,
      unlinkingId: null,
      _timer:     null,
    };
  },

  mounted() {
    this.$nextTick(() => this.$refs.searchInput?.focus());
  },

  beforeUnmount() {
    clearTimeout(this._timer);
  },

  methods: {
    // ── Search ───────────────────────────────────────────────────────────────

    onSearchInput() {
      clearTimeout(this._timer);
      if (this.query.length < 2) {
        this.results = [];
        return;
      }
      this._timer = setTimeout(() => this.search(), 400);
    },

    async search() {
      this.searching = true;
      try {
        const accountId  = this.$store.getters['getCurrentAccountId'];
        const { data }   = await axios.get(
          `/api/v1/accounts/${accountId}/search`,
          { params: { q: this.query, include_contacts: false, include_conversations: true } }
        );
        // Chatwoot search returns { payload: { conversations: [...] } }
        this.results = data?.payload?.conversations || data?.conversations || [];
      } catch {
        this.results = [];
      } finally {
        this.searching = false;
      }
    },

    // ── Link / Unlink ─────────────────────────────────────────────────────────

    async link(conversationId) {
      if (this.linkingId) return;
      this.linkingId = conversationId;
      const accountId = this.$store.getters['getCurrentAccountId'];
      try {
        const { data } = await axios.post(
          `/api/v1/accounts/${accountId}/funnels/${this.funnelId}/cards/${this.cardId}/link_conversation`,
          { conversation_id: conversationId }
        );
        this.toastSuccess(this.$t('funnels.linker.link_success', { id: conversationId }));
        // POST retorna { id, conversation_id, is_primary }
        // Emite no formato que CardDetail espera: { id: conversation_id, is_primary }
        this.$emit('linked', {
          id:         data?.conversation_id ?? conversationId,
          is_primary: data?.is_primary      ?? false,
        });
      } catch {
        this.toastError(this.$t('funnels.linker.link_error'));
      } finally {
        this.linkingId = null;
      }
    },

    async unlink(conversationId) {
      if (this.unlinkingId) return;
      this.unlinkingId = conversationId;
      const accountId = this.$store.getters['getCurrentAccountId'];
      try {
        // DELETE usa query param (não body)
        await axios.delete(
          `/api/v1/accounts/${accountId}/funnels/${this.funnelId}/cards/${this.cardId}/link_conversation`,
          { params: { conversation_id: conversationId } }
        );
        this.toastSuccess(this.$t('funnels.linker.unlink_success'));
        this.$emit('unlinked', conversationId);
      } catch {
        this.toastError(this.$t('funnels.linker.unlink_error'));
      } finally {
        this.unlinkingId = null;
      }
    },

    // ── Helpers ───────────────────────────────────────────────────────────────

    isAlreadyLinked(convId) {
      return this.linkedConversations.some(c => c.id === convId);
    },

    channelIcon(conv) {
      const type = conv.channel || conv.inbox_id;
      if (conv.meta?.channel === 'Channel::Api') return 'i-lucide-zap';
      if (conv.meta?.channel?.includes('Whatsapp')) return 'i-lucide-message-circle';
      return 'i-lucide-message-square';
    },

    channelColor(conv) {
      if (conv.status === 'resolved') return 'bg-n-alpha-2 text-n-slate-9';
      return 'bg-woot-50 text-woot-600 dark:bg-woot-900/20 dark:text-woot-400';
    },

    statusClass(status) {
      if (status === 'resolved') return 'bg-n-alpha-2 text-n-slate-9';
      if (status === 'pending')  return 'bg-amber-100 text-amber-700';
      return 'bg-green-100 text-green-700';
    },
  },
};
</script>

<style scoped>
@keyframes fadeSlideUp {
  from { opacity: 0; transform: translateY(16px); }
  to   { opacity: 1; transform: translateY(0); }
}
</style>
