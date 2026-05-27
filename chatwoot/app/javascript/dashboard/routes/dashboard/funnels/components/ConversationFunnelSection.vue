<template>
  <div class="funnels-conversation-section">

    <!-- ── Section header (accordion) ────────────────────────────────────── -->
    <div
      class="flex items-center justify-between py-2 cursor-pointer select-none"
      role="button"
      tabindex="0"
      :aria-expanded="expanded"
      @click="toggle"
      @keyup.enter="toggle"
    >
      <div class="flex items-center gap-1.5 text-sm font-medium text-n-slate-11">
        <i class="i-lucide-kanban size-4 text-woot-500" aria-hidden="true" />
        {{ $t('funnels.conversation_widget.section_title') }}
        <span
          v-if="linkedCards.length > 0"
          class="size-4 rounded-full bg-woot-100 text-woot-700 text-[10px] font-bold
                 flex items-center justify-center"
        >
          {{ linkedCards.length }}
        </span>
      </div>
      <i
        :class="expanded ? 'i-lucide-chevron-up' : 'i-lucide-chevron-down'"
        class="size-4 text-n-slate-8"
        aria-hidden="true"
      />
    </div>

    <Transition
      enter-active-class="transition-all duration-200 ease-out"
      enter-from-class="opacity-0 max-h-0"
      enter-to-class="opacity-100 max-h-[600px]"
      leave-active-class="transition-all duration-150 ease-in"
      leave-from-class="opacity-100 max-h-[600px]"
      leave-to-class="opacity-0 max-h-0"
    >
      <div v-if="expanded" class="overflow-hidden pb-3 flex flex-col gap-2">

        <!-- ── Loading ─────────────────────────────────────────────────────── -->
        <div
          v-if="loadingCards"
          class="flex items-center gap-1.5 text-xs text-n-slate-8 py-1"
        >
          <i class="i-lucide-loader-circle animate-spin size-3.5" aria-hidden="true" />
          {{ $t('funnels.conversation_widget.loading') }}
        </div>

        <!-- ── Linked cards list ───────────────────────────────────────────── -->
        <template v-else>
          <div
            v-for="card in linkedCards"
            :key="card.id"
            class="flex items-start gap-2 px-2 py-2 rounded-lg border border-n-weak
                   hover:bg-n-alpha-1 transition-colors cursor-pointer group"
            role="button"
            tabindex="0"
            :aria-label="`${$t('funnels.conversation_widget.open_board')} — ${card.title}`"
            @click="openCard(card)"
            @keyup.enter="openCard(card)"
          >
            <!-- Stage color dot -->
            <span
              class="mt-0.5 size-2 rounded-full flex-shrink-0"
              :style="{ backgroundColor: card.stage_color || '#6B7280' }"
              aria-hidden="true"
            />
            <div class="flex-1 min-w-0">
              <p class="text-xs font-medium text-n-slate-12 truncate">{{ card.title }}</p>
              <p class="text-[11px] text-n-slate-9 truncate">
                {{ card.funnel_name }} · {{ card.stage_name }}
              </p>
              <div class="flex items-center gap-2 mt-0.5">
                <span v-if="card.value > 0" class="text-[11px] font-semibold text-woot-600">
                  {{ formatCurrency(card.value) }}
                </span>
                <span class="text-[11px] text-n-slate-8">
                  {{ card.days_in_stage }}d
                </span>
              </div>
            </div>
            <i
              class="i-lucide-external-link size-3.5 text-n-slate-7
                     opacity-0 group-hover:opacity-100 transition-opacity flex-shrink-0 mt-0.5"
              aria-hidden="true"
            />
          </div>

          <!-- ── No cards empty state ──────────────────────────────────────── -->
          <p
            v-if="linkedCards.length === 0 && !showForm"
            class="text-xs text-n-slate-8 py-1"
          >
            {{ $t('funnels.conversation_widget.no_cards') }}
          </p>
        </template>

        <!-- ── Create card form ────────────────────────────────────────────── -->
        <div v-if="!showForm">
          <button
            class="w-full flex items-center justify-center gap-1.5 px-3 py-1.5 text-xs
                   font-medium text-woot-600 border border-woot-200 rounded-lg
                   hover:bg-woot-50 hover:border-woot-400 transition-colors
                   dark:border-woot-800/30 dark:hover:bg-woot-900/10"
            @click="openForm"
          >
            <i class="i-lucide-plus size-3.5" aria-hidden="true" />
            {{ $t('funnels.conversation_widget.create_btn') }}
          </button>
        </div>

        <div
          v-else
          class="border border-n-weak rounded-xl p-3 bg-n-alpha-1/50 flex flex-col gap-3"
        >
          <!-- Funnel selector -->
          <div>
            <label class="block text-xs font-medium text-n-slate-9 mb-1">
              {{ $t('funnels.conversation_widget.funnel_label') }}
            </label>
            <select
              v-model="form.funnelId"
              class="w-full text-sm border border-n-weak rounded-lg px-2 py-1.5
                     bg-n-solid-1 text-n-slate-12 focus:outline-none focus:border-woot-400"
              :disabled="loadingFunnels"
              @change="onFunnelChange"
            >
              <option value="">{{ $t('funnels.conversation_widget.funnel_placeholder') }}</option>
              <option v-for="f in funnels" :key="f.id" :value="f.id">{{ f.name }}</option>
            </select>
          </div>

          <!-- Stage selector -->
          <div v-if="form.funnelId">
            <label class="block text-xs font-medium text-n-slate-9 mb-1">
              {{ $t('funnels.conversation_widget.stage_label') }}
            </label>
            <div v-if="loadingStages" class="text-xs text-n-slate-8 flex items-center gap-1 py-1">
              <i class="i-lucide-loader-circle animate-spin size-3" aria-hidden="true" />
              {{ $t('funnels.conversation_widget.loading') }}
            </div>
            <select
              v-else
              v-model="form.stageId"
              class="w-full text-sm border border-n-weak rounded-lg px-2 py-1.5
                     bg-n-solid-1 text-n-slate-12 focus:outline-none focus:border-woot-400"
            >
              <option value="">{{ $t('funnels.conversation_widget.stage_placeholder') }}</option>
              <option v-for="s in availableStages" :key="s.id" :value="s.id">
                {{ s.name }}
              </option>
            </select>
          </div>

          <!-- Title -->
          <div>
            <label class="block text-xs font-medium text-n-slate-9 mb-1">
              {{ $t('funnels.conversation_widget.title_label') }}
            </label>
            <input
              ref="titleInput"
              v-model="form.title"
              type="text"
              class="w-full text-sm border border-n-weak rounded-lg px-2 py-1.5
                     bg-n-solid-1 text-n-slate-12 focus:outline-none focus:border-woot-400
                     placeholder:text-n-slate-7"
              :placeholder="$t('funnels.conversation_widget.title_placeholder',
                { contact: contactName })"
              @keydown.enter.prevent="createCard"
              @keydown.esc="showForm = false"
            />
          </div>

          <!-- Actions -->
          <div class="flex gap-2">
            <button
              class="flex-1 py-1.5 text-xs border border-n-weak rounded-lg
                     text-n-slate-11 hover:bg-n-alpha-1 transition-colors"
              :disabled="creating"
              @click="showForm = false"
            >
              {{ $t('funnels.cancel') }}
            </button>
            <button
              :disabled="!canCreate || creating"
              class="flex-1 py-1.5 text-xs font-medium text-white bg-woot-500
                     hover:bg-woot-600 rounded-lg transition-colors disabled:opacity-40
                     flex items-center justify-center gap-1"
              @click="createCard"
            >
              <i
                v-if="creating"
                class="i-lucide-loader-circle animate-spin size-3"
                aria-hidden="true"
              />
              {{ creating
                ? $t('funnels.conversation_widget.creating')
                : $t('funnels.conversation_widget.create_btn')
              }}
            </button>
          </div>
        </div>

      </div>
    </Transition>
  </div>
</template>

<script>
import axios          from 'axios';
import { mapGetters } from 'vuex';
import { useFunnelToast } from '../composables/useFunnelToast';

export default {
  name: 'ConversationFunnelSection',

  setup() {
    const { success, error } = useFunnelToast();
    return { toastSuccess: success, toastError: error };
  },

  props: {
    conversationId: { type: [Number, String], required: true },
  },

  data() {
    return {
      expanded:        false,
      showForm:        false,
      loadingCards:    false,
      loadingFunnels:  false,
      loadingStages:   false,
      creating:        false,
      linkedCards:     [],
      availableStages: [],
      form: {
        funnelId: '',
        stageId:  '',
        title:    '',
      },
    };
  },

  computed: {
    ...mapGetters('funnels', ['allFunnels']),
    ...mapGetters({ currentConversation: 'getSelectedChat' }),

    funnels()    { return this.allFunnels; },
    canCreate()  { return !!this.form.funnelId && !!this.form.stageId && !!this.form.title.trim(); },
    contactName() {
      return this.currentConversation?.meta?.sender?.name || '';
    },
  },

  methods: {
    async toggle() {
      this.expanded = !this.expanded;
      if (this.expanded) await this.fetchLinkedCards();
    },

    // ── Linked cards ──────────────────────────────────────────────────────────

    async fetchLinkedCards() {
      this.loadingCards = true;
      try {
        const accountId = this.$store.getters['getCurrentAccountId'];
        const { data }  = await axios.get(
          `/api/v1/accounts/${accountId}/funnels/cards_by_conversation`,
          { params: { conversation_id: this.conversationId } }
        );
        this.linkedCards = data || [];
      } catch {
        this.linkedCards = [];
      } finally {
        this.loadingCards = false;
      }
    },

    openCard(card) {
      const accountId = this.$store.getters['getCurrentAccountId'];
      this.$router.push(
        `/app/accounts/${accountId}/funnels/${card.funnel_id}/cards/${card.id}`
      );
    },

    // ── Create card ───────────────────────────────────────────────────────────

    async loadFunnels() {
      if (this.funnels.length) return;
      this.loadingFunnels = true;
      try {
        await this.$store.dispatch('funnels/fetchFunnels');
      } finally {
        this.loadingFunnels = false;
      }
    },

    async openForm() {
      this.showForm = true;
      this.form     = { funnelId: '', stageId: '', title: '' };
      await this.loadFunnels();
      if (this.contactName) this.form.title = this.contactName;
      if (this.funnels.length === 1) {
        this.form.funnelId = this.funnels[0].id;
        await this.onFunnelChange();
      }
      this.$nextTick(() => this.$refs.titleInput?.focus());
    },

    async onFunnelChange() {
      this.form.stageId   = '';
      this.availableStages = [];
      if (!this.form.funnelId) return;

      this.loadingStages = true;
      try {
        const accountId = this.$store.getters['getCurrentAccountId'];
        const { data }  = await axios.get(
          `/api/v1/accounts/${accountId}/funnels/${this.form.funnelId}`
        );
        this.availableStages = (data.stages || []).filter(s => s.stage_type === 'intermediate');
        if (this.availableStages.length > 0) {
          this.form.stageId = this.availableStages[0].id;
        }
      } catch {
        this.availableStages = [];
      } finally {
        this.loadingStages = false;
      }
    },

    async createCard() {
      if (!this.canCreate || this.creating) return;
      this.creating = true;
      const accountId = this.$store.getters['getCurrentAccountId'];

      try {
        // 1. Criar card
        const { data: card } = await axios.post(
          `/api/v1/accounts/${accountId}/funnels/${this.form.funnelId}/cards`,
          { card: { title: this.form.title.trim(), stage_id: Number(this.form.stageId) } }
        );

        // 2. Vincular conversa
        try {
          await axios.post(
            `/api/v1/accounts/${accountId}/funnels/${this.form.funnelId}/cards/${card.id}/link_conversation`,
            { conversation_id: Number(this.conversationId) }
          );
          this.toastSuccess(this.$t('funnels.conversation_widget.create_success'));
        } catch {
          this.toastError(this.$t('funnels.conversation_widget.link_error'));
        }

        this.showForm = false;
        // Re-fetch para mostrar o novo card na lista
        await this.fetchLinkedCards();
        this.$store.dispatch('funnels/fetchFunnels');

      } catch {
        this.toastError(this.$t('funnels.conversation_widget.create_error'));
      } finally {
        this.creating = false;
      }
    },

    // ── Formatters ────────────────────────────────────────────────────────────

    formatCurrency(value, currency = 'BRL') {
      return new Intl.NumberFormat('pt-BR', {
        style: 'currency', currency, minimumFractionDigits: 0,
      }).format(value);
    },
  },
};
</script>
