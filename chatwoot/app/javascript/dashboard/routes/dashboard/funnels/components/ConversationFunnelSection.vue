<template>
  <div class="funnels-conversation-section">

    <!-- ── Section header (accordion) ────────────────────────────────────── -->
    <div
      class="flex items-center justify-between py-2 cursor-pointer select-none"
      role="button"
      tabindex="0"
      :aria-expanded="expanded"
      @click="expanded = !expanded"
      @keyup.enter="expanded = !expanded"
    >
      <div class="flex items-center gap-1.5 text-sm font-medium text-n-slate-11">
        <i class="i-lucide-kanban size-4 text-woot-500" aria-hidden="true" />
        {{ $t('funnels.conversation_widget.section_title') }}
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
      <div v-if="expanded" class="overflow-hidden pb-3">

        <!-- Linked cards placeholder (pending backend endpoint) -->
        <div class="text-xs text-n-slate-8 italic mb-2 flex items-center gap-1">
          <i class="i-lucide-info size-3" aria-hidden="true" />
          {{ $t('funnels.conversation_widget.linked_cards_pending') }}
        </div>

        <!-- Create card form (hidden until button clicked) -->
        <div v-if="!showForm">
          <button
            class="w-full flex items-center justify-center gap-1.5 px-3 py-2 text-xs
                   font-medium text-woot-600 border border-woot-200 rounded-lg
                   hover:bg-woot-50 hover:border-woot-400 transition-colors
                   dark:border-woot-800/30 dark:hover:bg-woot-900/10"
            @click="openForm"
          >
            <i class="i-lucide-plus size-3.5" aria-hidden="true" />
            {{ $t('funnels.conversation_widget.create_btn') }}
          </button>
        </div>

        <!-- Inline create card form -->
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
              <option
                v-for="s in availableStages"
                :key="s.id"
                :value="s.id"
              >
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
      expanded:      false,
      showForm:      false,
      loadingFunnels: false,
      loadingStages:  false,
      creating:       false,
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
    ...mapGetters({
      currentConversation: 'getSelectedChat',
    }),

    funnels()     { return this.allFunnels; },
    canCreate()   { return !!this.form.funnelId && !!this.form.stageId && !!this.form.title.trim(); },
    contactName() {
      return this.currentConversation?.meta?.sender?.name || '';
    },
  },

  watch: {
    expanded(val) {
      if (val && !this.funnels.length) this.loadFunnels();
    },
  },

  methods: {
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
      this.showForm  = true;
      this.form      = { funnelId: '', stageId: '', title: '' };
      await this.loadFunnels();
      // Pre-fill title with contact name
      if (this.contactName) {
        this.form.title = this.contactName;
      }
      // Auto-select first funnel
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
        this.availableStages = (data.stages || [])
          .filter(s => s.stage_type === 'intermediate');
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
          {
            card: {
              title:    this.form.title.trim(),
              stage_id: Number(this.form.stageId),
            },
          }
        );

        // 2. Vincular conversa ao card
        try {
          await axios.post(
            `/api/v1/accounts/${accountId}/funnels/${this.form.funnelId}/cards/${card.id}/link_conversation`,
            { conversation_id: Number(this.conversationId) }
          );
          this.toastSuccess(this.$t('funnels.conversation_widget.create_success'));
        } catch {
          // Card created, link failed
          this.toastError(this.$t('funnels.conversation_widget.link_error'));
        }

        // 3. Refresh funnels store (updates cards_count)
        this.$store.dispatch('funnels/fetchFunnels');
        this.showForm = false;

      } catch {
        this.toastError(this.$t('funnels.conversation_widget.create_error'));
      } finally {
        this.creating = false;
      }
    },
  },
};
</script>
