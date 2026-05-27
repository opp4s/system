<template>
  <!-- Backdrop — clique fora fecha -->
  <div
    class="fixed inset-0 z-50 flex justify-end"
    role="dialog"
    :aria-modal="true"
    :aria-label="card?.title"
    @click.self="close"
  >
    <!-- Painel slide-in 70% viewport -->
    <div
      class="card-detail-panel w-[70vw] max-w-[960px] h-full bg-n-solid-1 shadow-2xl
             flex flex-col overflow-hidden"
      :class="visible ? 'translate-x-0' : 'translate-x-full'"
      style="transition: transform 0.3s cubic-bezier(0.4,0,0.2,1)"
    >

      <!-- ── Header ─────────────────────────────────────────────────────────── -->
      <div class="flex items-center justify-between px-6 py-4 border-b border-n-weak flex-shrink-0">
        <div class="flex items-center gap-3 min-w-0">
          <button
            class="text-n-slate-9 hover:text-n-slate-12 transition-colors flex-shrink-0"
            :aria-label="$t('funnels.card_detail.close_aria')"
            @click="close"
          >
            <i class="i-lucide-x size-5" aria-hidden="true" />
          </button>
          <h2 class="text-base font-semibold text-n-slate-12 truncate">
            {{ card?.title || '…' }}
          </h2>
        </div>

        <div v-if="card" class="flex items-center gap-2 flex-shrink-0">
          <span
            class="text-xs px-2.5 py-1 rounded-full border font-medium"
            :style="{ borderColor: currentStage?.color, color: currentStage?.color }"
          >
            {{ currentStage?.name }}
          </span>
          <span v-if="card.value > 0" class="text-xs font-semibold text-woot-600">
            {{ formatCurrency(card.value, card.currency) }}
          </span>
        </div>
      </div>

      <!-- ── Body ───────────────────────────────────────────────────────────── -->
      <div v-if="card" class="flex flex-1 overflow-hidden">

        <!-- ── Painel lateral esquerdo 320px ──────────────────────────────── -->
        <aside class="w-80 flex-shrink-0 border-r border-n-weak flex flex-col overflow-hidden">

          <!-- Tabs -->
          <div class="flex border-b border-n-weak flex-shrink-0">
            <button
              v-for="tab in tabs"
              :key="tab.key"
              class="flex-1 py-2.5 text-xs font-medium transition-colors"
              :class="activeTab === tab.key
                ? 'text-woot-600 border-b-2 border-woot-500 bg-woot-50/30'
                : 'text-n-slate-9 hover:text-n-slate-12 hover:bg-n-alpha-1'"
              @click="activeTab = tab.key"
            >
              {{ $t(tab.labelKey) }}
            </button>
          </div>

          <!-- Tab: Dados ─────────────────────────────────────────────────── -->
          <div v-if="activeTab === 'data'" class="flex-1 overflow-y-auto p-5 flex flex-col gap-5">

            <!-- StageFunnelSwitcher -->
            <StageFunnelSwitcher
              :card="card"
              :stages="allStages"
              :current-funnel-id="currentFunnelId"
              @move="onMove"
              @transfer="onTransfer"
            />

            <!-- Responsável -->
            <div>
              <label class="block text-xs font-medium text-n-slate-9 uppercase tracking-wide mb-1.5">
                {{ $t('funnels.card_detail.assignee_label') }}
              </label>
              <div class="flex items-center gap-2">
                <img
                  v-if="card.assigned_agent?.avatar"
                  :src="card.assigned_agent.avatar"
                  :alt="card.assigned_agent.name"
                  class="size-7 rounded-full object-cover"
                />
                <div
                  v-else-if="card.assigned_agent"
                  class="size-7 rounded-full bg-woot-100 flex items-center justify-center
                         text-woot-700 text-xs font-bold flex-shrink-0"
                  aria-hidden="true"
                >
                  {{ initials(card.assigned_agent.name) }}
                </div>
                <span class="text-sm text-n-slate-12">
                  {{ card.assigned_agent?.name || $t('funnels.card_detail.unassigned') }}
                </span>
              </div>
            </div>

            <!-- Valor -->
            <div>
              <label class="block text-xs font-medium text-n-slate-9 uppercase tracking-wide mb-1">
                {{ $t('funnels.card_detail.value_label') }}
              </label>
              <div class="text-sm font-semibold text-n-slate-12">
                {{ card.value > 0 ? formatCurrency(card.value, card.currency) : '—' }}
              </div>
            </div>

            <!-- Dias na etapa -->
            <div>
              <label class="block text-xs font-medium text-n-slate-9 uppercase tracking-wide mb-1">
                {{ $t('funnels.card_detail.days_in_stage_label') }}
              </label>
              <div class="text-sm text-n-slate-12">
                {{ $t('funnels.card_detail.days', { n: card.days_in_stage }) }}
              </div>
            </div>

            <!-- Conversas vinculadas -->
            <div>
              <div class="flex items-center justify-between mb-1.5">
                <label class="block text-xs font-medium text-n-slate-9 uppercase tracking-wide">
                  {{ $t('funnels.card_detail.conversations_label') }}
                </label>
                <button
                  class="flex items-center gap-1 text-xs text-woot-600 hover:text-woot-700
                         transition-colors font-medium"
                  @click="showLinker = true"
                >
                  <i class="i-lucide-link size-3" aria-hidden="true" />
                  {{ $t('funnels.card_detail.link_conversation_btn') }}
                </button>
              </div>
              <div
                v-for="conv in card.conversations || []"
                :key="conv.id"
                class="flex items-center gap-2 text-sm text-woot-600 cursor-pointer
                       hover:underline py-1 rounded transition-colors"
                role="button"
                :aria-label="`${$t('funnels.card_detail.open_conversation_aria')} #${conv.id}`"
                tabindex="0"
                @click="openConversation(conv.id)"
                @keyup.enter="openConversation(conv.id)"
              >
                <i class="i-lucide-message-square size-4 flex-shrink-0" aria-hidden="true" />
                <span>{{ $t('funnels.card_detail.conversation') }} #{{ conv.id }}</span>
                <span v-if="conv.is_primary" class="ml-auto text-xs text-n-slate-9 flex-shrink-0">
                  {{ $t('funnels.card_detail.primary_badge') }}
                </span>
              </div>
              <p v-if="!card.conversations?.length" class="text-sm text-n-slate-9 py-1">
                {{ $t('funnels.card_detail.no_conversations') }}
              </p>
            </div>
          </div>

          <!-- Tab: Campos (Custom Attributes) ────────────────────────────── -->
          <div v-else-if="activeTab === 'fields'" class="flex-1 overflow-y-auto p-5">
            <CustomAttributesTab
              :card-id="card.id"
              :funnel-id="currentFunnelId"
            />
          </div>
        </aside>

        <!-- ── Timeline central (scrollável) + Composer ───────────────────── -->
        <main class="flex-1 flex flex-col overflow-hidden">

          <!-- Timeline scrollável -->
          <div ref="timelineEl" class="flex-1 overflow-y-auto p-5 flex flex-col gap-3">

            <!-- Skeleton da timeline -->
            <template v-if="loadingTimeline">
              <div v-for="i in 5" :key="i" class="flex gap-3">
                <div class="size-7 rounded-full bg-n-alpha-2 animate-pulse flex-shrink-0 mt-0.5" />
                <div class="flex-1">
                  <div class="h-2.5 rounded bg-n-alpha-2 animate-pulse mb-2 w-1/3" />
                  <div class="h-10 rounded-lg bg-n-alpha-1 animate-pulse" />
                </div>
              </div>
            </template>

            <template v-else>

              <!-- Timeline items (com separadores de data) -->
              <template
                v-for="item in timelineWithSeparators"
                :key="item._key"
              >

                <!-- ── Separador de data ─────────────────────────────────── -->
                <div
                  v-if="item.type === 'date-separator'"
                  class="flex items-center gap-3 my-1"
                >
                  <div class="flex-1 h-px bg-n-weak" />
                  <span class="text-xs text-n-slate-8 flex-shrink-0 font-medium">
                    {{ item.label }}
                  </span>
                  <div class="flex-1 h-px bg-n-weak" />
                </div>

                <!-- ── Evento do sistema ─────────────────────────────────── -->
                <div
                  v-else-if="item.type === 'event'"
                  class="flex gap-3 items-start"
                >
                  <div
                    class="size-7 rounded-full flex items-center justify-center flex-shrink-0
                           bg-n-alpha-1 text-n-slate-9 mt-0.5"
                  >
                    <i class="i-lucide-activity size-3.5" aria-hidden="true" />
                  </div>
                  <div class="flex-1 min-w-0 pt-1">
                    <span class="text-xs text-n-slate-9 italic">
                      {{ formatEventLabel(item.event_type, item.payload) }}
                    </span>
                    <span class="text-n-slate-6 mx-1.5 text-xs">·</span>
                    <span class="text-xs text-n-slate-7">{{ formatTime(item.created_at) }}</span>
                  </div>
                </div>

                <!-- ── Nota interna (private message) ───────────────────── -->
                <div
                  v-else-if="item.type === 'message' && item.private"
                  class="flex gap-3 items-start"
                >
                  <div
                    class="size-7 rounded-full flex items-center justify-center flex-shrink-0
                           bg-amber-100 text-amber-600 mt-0.5"
                  >
                    <i class="i-lucide-sticky-note size-3.5" aria-hidden="true" />
                  </div>
                  <div class="flex-1 min-w-0">
                    <div class="text-xs text-n-slate-9 mb-1 flex items-center gap-1.5">
                      <span>{{ item.sender?.name || $t('funnels.card_detail.system') }}</span>
                      <span class="text-n-slate-6">·</span>
                      <span class="text-n-slate-7">{{ formatTime(item.created_at) }}</span>
                      <span
                        class="ml-auto text-xs px-1.5 py-0.5 rounded-full
                               bg-amber-100 text-amber-700 font-medium"
                      >
                        {{ $t('funnels.card_detail.msg_note') }}
                      </span>
                    </div>
                    <div
                      class="text-sm text-amber-800 bg-amber-50 border border-amber-200
                             rounded-xl px-3 py-2.5 leading-relaxed dark:bg-amber-900/10
                             dark:text-amber-300 dark:border-amber-800/30"
                    >
                      {{ item.content }}
                    </div>
                  </div>
                </div>

                <!-- ── Mensagem recebida (incoming) ──────────────────────── -->
                <div
                  v-else-if="item.type === 'message' && item.message_type === 0"
                  class="flex gap-3 items-start"
                >
                  <div
                    class="size-7 rounded-full flex items-center justify-center flex-shrink-0
                           bg-n-alpha-2 text-n-slate-9 mt-0.5 text-xs font-bold"
                  >
                    {{ initials(item.sender?.name || '?') }}
                  </div>
                  <div class="flex-1 min-w-0 max-w-[85%]">
                    <div class="text-xs text-n-slate-9 mb-1 flex items-center gap-1.5">
                      <span>{{ item.sender?.name || $t('funnels.card_detail.system') }}</span>
                      <span class="text-n-slate-6">·</span>
                      <span class="text-n-slate-7">{{ formatTime(item.created_at) }}</span>
                      <span class="ml-auto text-n-slate-7">
                        {{ $t('funnels.card_detail.msg_incoming') }}
                      </span>
                    </div>
                    <div
                      class="text-sm text-n-slate-12 bg-n-alpha-1 border border-n-weak
                             rounded-xl rounded-tl-sm px-3 py-2.5 leading-relaxed"
                    >
                      {{ item.content }}
                    </div>
                  </div>
                </div>

                <!-- ── Mensagem enviada (outgoing) ───────────────────────── -->
                <div
                  v-else-if="item.type === 'message'"
                  class="flex gap-3 items-start flex-row-reverse"
                >
                  <div
                    class="size-7 rounded-full flex items-center justify-center flex-shrink-0
                           bg-woot-100 text-woot-700 mt-0.5 text-xs font-bold"
                  >
                    {{ initials(item.sender?.name || '?') }}
                  </div>
                  <div class="flex-1 min-w-0 max-w-[85%] flex flex-col items-end">
                    <div class="text-xs text-n-slate-9 mb-1 flex items-center gap-1.5">
                      <span class="text-n-slate-7">
                        {{ $t('funnels.card_detail.msg_outgoing') }}
                      </span>
                      <span class="text-n-slate-6">·</span>
                      <span class="text-n-slate-7">{{ formatTime(item.created_at) }}</span>
                      <span class="text-n-slate-6">·</span>
                      <span>{{ item.sender?.name || $t('funnels.card_detail.system') }}</span>
                    </div>
                    <div
                      class="text-sm text-white bg-woot-500 rounded-xl rounded-tr-sm
                             px-3 py-2.5 leading-relaxed"
                    >
                      {{ item.content }}
                    </div>
                  </div>
                </div>

              </template>

              <!-- Empty state -->
              <div
                v-if="timeline.length === 0"
                class="flex flex-col items-center justify-center py-12 text-center"
              >
                <i class="i-lucide-clock size-8 text-n-slate-8 mb-2" aria-hidden="true" />
                <p class="text-sm text-n-slate-9">{{ $t('funnels.card_detail.no_history') }}</p>
              </div>
            </template>

          </div>

          <!-- ── Composer ─────────────────────────────────────────────────── -->
          <CardComposer
            :primary-conversation-id="primaryConversationId"
            @sent="onMessageSent"
          />

        </main>
      </div>

      <!-- Loading inicial do card -->
      <div v-else class="flex-1 flex items-center justify-center">
        <div class="flex flex-col items-center gap-3">
          <div class="animate-spin i-lucide-loader-circle size-8 text-woot-500" aria-hidden="true" />
        </div>
      </div>

    </div>

    <!-- Toast local para ações do card -->
    <FunnelToast />

    <!-- ConversationLinker modal -->
    <ConversationLinker
      v-if="showLinker && card"
      :card-id="card.id"
      :funnel-id="currentFunnelId"
      :linked-conversations="card.conversations || []"
      @close="showLinker = false"
      @linked="onConversationLinked"
      @unlinked="onConversationUnlinked"
    />
  </div>
</template>

<script>
import axios                from 'axios';
import { mapGetters }       from 'vuex';
import { useFunnelToast }   from '../composables/useFunnelToast';
import StageFunnelSwitcher  from './StageFunnelSwitcher.vue';
import CustomAttributesTab  from './CustomAttributesTab.vue';
import CardComposer         from './CardComposer.vue';
import ConversationLinker   from './ConversationLinker.vue';
import FunnelToast          from './FunnelToast.vue';

export default {
  name: 'CardDetail',
  components: {
    StageFunnelSwitcher,
    CustomAttributesTab,
    CardComposer,
    ConversationLinker,
    FunnelToast,
  },

  setup() {
    const { success, error } = useFunnelToast();
    return { toastSuccess: success, toastError: error };
  },

  data() {
    return {
      card:            null,
      timeline:        [],
      loadingTimeline: false,
      visible:         false,
      activeTab:       'data',
      showLinker:      false,
      tabs: [
        { key: 'data',   labelKey: 'funnels.card_detail.tab_data'   },
        { key: 'fields', labelKey: 'funnels.card_detail.tab_fields' },
      ],
      _cardSub: null,
    };
  },

  computed: {
    ...mapGetters('funnels', ['stages', 'allFunnels']),

    allStages()       { return this.stages; },
    currentStage()    { return this.stages.find(s => s.id === this.card?.stage_id); },
    currentFunnelId() { return Number(this.$route.params.funnelId); },

    primaryConversationId() {
      if (!this.card?.conversations?.length) return null;
      const primary = this.card.conversations.find(c => c.is_primary);
      return primary?.id || this.card.conversations[0]?.id || null;
    },

    /** Timeline items intercalados com separadores de data */
    timelineWithSeparators() {
      if (!this.timeline.length) return [];

      const items  = [];
      let lastDate = null;

      this.timeline.forEach((item, idx) => {
        const dateStr = this.dateKey(item.created_at);

        if (dateStr && dateStr !== lastDate) {
          items.push({
            type:  'date-separator',
            label: this.formatDate(item.created_at),
            _key:  `sep-${dateStr}`,
          });
          lastDate = dateStr;
        }

        items.push({ ...item, _key: `${item.type}-${item.id || idx}` });
      });

      return items;
    },
  },

  mounted() {
    this.loadCard();
    this.$nextTick(() => { this.visible = true; });
    document.addEventListener('keyup', this.onKeyUp);
  },

  beforeUnmount() {
    this._cardSub?.unsubscribe();
    document.removeEventListener('keyup', this.onKeyUp);
  },

  methods: {
    // ── Lifecycle ─────────────────────────────────────────────────────────────

    onKeyUp(e) {
      if (e.key === 'Escape' && !this.showLinker) {
        this.close();
      }
    },

    async loadCard() {
      const { funnelId, cardId } = this.$route.params;
      const accountId = this.$store.getters['getCurrentAccountId'];
      try {
        const { data } = await axios.get(
          `/api/v1/accounts/${accountId}/funnels/${funnelId}/cards/${cardId}`
        );
        this.card = data;
        this.loadTimeline(funnelId, cardId, accountId);
        this.subscribeCardChannel(cardId);
      } catch {
        this.close();
      }
    },

    subscribeCardChannel(cardId) {
      if (!window.actionCable) return;
      const store    = this.$store;
      const authUser = store.getters['auth/getCurrentUser'];
      this._cardSub  = window.actionCable.subscriptions.create(
        {
          channel:      'Funnels::FunnelCardChannel',
          card_id:      Number(cardId),
          account_id:   store.getters['getCurrentAccountId'],
          pubsub_token: authUser?.pubsub_token,
          user_id:      authUser?.id,
        },
        {
          received: ({ event, card }) => {
            if (event === 'card_deleted' || event === 'card_archived') {
              this.close();
            } else if (card) {
              this.card = { ...this.card, ...card };
            }
          },
        }
      );
    },

    async loadTimeline(funnelId, cardId, accountId) {
      this.loadingTimeline = true;
      try {
        const { data } = await axios.get(
          `/api/v1/accounts/${accountId}/funnels/${funnelId}/cards/${cardId}/timeline`
        );
        // Backend returns ordered asc (oldest first)
        this.timeline = data.timeline || [];
        this.$nextTick(() => this.scrollTimelineToBottom());
      } finally {
        this.loadingTimeline = false;
      }
    },

    scrollTimelineToBottom() {
      const el = this.$refs.timelineEl;
      if (el) el.scrollTop = el.scrollHeight;
    },

    close() {
      this.visible = false;
      setTimeout(() => this.$router.back(), 300);
    },

    // ── Stage / Transfer ─────────────────────────────────────────────────────

    async onMove({ stageId, lostReason }) {
      const { funnelId, cardId } = this.$route.params;
      const accountId  = this.$store.getters['getCurrentAccountId'];

      try {
        const { data } = await axios.post(
          `/api/v1/accounts/${accountId}/funnels/${funnelId}/cards/${cardId}/move`,
          { stage_id: stageId, lost_reason: lostReason }
        );
        this.card = { ...this.card, ...data };
        this.$store.commit('funnels/MOVE_CARD_TO_STAGE', data);

        const stageName = this.stages.find(s => s.id === stageId)?.name || '';
        this.toastSuccess(this.$t('funnels.move_success', { stage: stageName }));
      } catch {
        this.toastError(this.$t('funnels.move_error'));
      }
    },

    async onTransfer({ funnelId: targetFunnelId, stageId: targetStageId }) {
      const { funnelId, cardId } = this.$route.params;
      const accountId  = this.$store.getters['getCurrentAccountId'];

      try {
        await axios.post(
          `/api/v1/accounts/${accountId}/funnels/${funnelId}/cards/${cardId}/transfer`,
          { funnel_id: targetFunnelId, stage_id: targetStageId }
        );
        this.$store.commit('funnels/REMOVE_CARD', Number(cardId));

        const targetFunnel = this.allFunnels.find(f => f.id === targetFunnelId);
        this.toastSuccess(
          this.$t('funnels.stage_switcher.transfer_success', { funnel: targetFunnel?.name || '' })
        );
        this.close();
      } catch {
        this.toastError(this.$t('funnels.stage_switcher.transfer_error'));
      }
    },

    // ── Composer ─────────────────────────────────────────────────────────────

    async onMessageSent() {
      // Recarrega timeline para incluir a nova mensagem
      const { funnelId, cardId } = this.$route.params;
      const accountId = this.$store.getters['getCurrentAccountId'];
      await this.loadTimeline(funnelId, cardId, accountId);
    },

    // ── Conversation Linker ───────────────────────────────────────────────────

    onConversationLinked(conv) {
      if (!this.card.conversations) this.card.conversations = [];
      const exists = this.card.conversations.some(c => c.id === conv.id);
      if (!exists) {
        this.card = {
          ...this.card,
          conversations: [...this.card.conversations, conv],
        };
      }
    },

    onConversationUnlinked(convId) {
      if (!this.card.conversations) return;
      this.card = {
        ...this.card,
        conversations: this.card.conversations.filter(c => c.id !== convId),
      };
    },

    // ── Navigation ────────────────────────────────────────────────────────────

    openConversation(convId) {
      const accountId = this.$store.getters['getCurrentAccountId'];
      this.$router.push(`/app/accounts/${accountId}/conversations/${convId}`);
    },

    // ── Formatters ────────────────────────────────────────────────────────────

    initials(name) {
      return (name || '?').split(' ').slice(0, 2).map(p => p[0]).join('').toUpperCase();
    },

    formatCurrency(v, currency = 'BRL') {
      return new Intl.NumberFormat('pt-BR', {
        style: 'currency', currency: currency || 'BRL', minimumFractionDigits: 0,
      }).format(v);
    },

    formatTime(ts) {
      if (!ts) return '';
      return new Intl.DateTimeFormat('pt-BR', {
        day: '2-digit', month: '2-digit', hour: '2-digit', minute: '2-digit',
      }).format(new Date(ts));
    },

    formatDate(ts) {
      if (!ts) return '';
      const d = new Date(ts);
      const today     = new Date();
      const yesterday = new Date(today);
      yesterday.setDate(today.getDate() - 1);

      const sameDay = (a, b) =>
        a.getDate()    === b.getDate()    &&
        a.getMonth()   === b.getMonth()   &&
        a.getFullYear() === b.getFullYear();

      if (sameDay(d, today))     return 'Hoje';
      if (sameDay(d, yesterday)) return 'Ontem';

      return new Intl.DateTimeFormat('pt-BR', {
        day: '2-digit', month: 'long', year: 'numeric',
      }).format(d);
    },

    dateKey(ts) {
      if (!ts) return null;
      const d = new Date(ts);
      return `${d.getFullYear()}-${d.getMonth()}-${d.getDate()}`;
    },

    formatEventLabel(type, payload = {}) {
      const key = `funnels.events.${type}`;
      if (this.$te?.(key)) {
        return this.$t(key, {
          from: payload.from_stage_name || '?',
          to:   payload.to_stage_name   || '?',
        });
      }
      return type;
    },
  },
};
</script>
