<template>
  <div
    class="fixed inset-0 z-50 flex justify-end"
    role="dialog"
    :aria-modal="true"
    :aria-label="card?.title"
    @click.self="close"
  >
    <div
      class="card-detail-panel w-[70vw] max-w-3xl h-full bg-n-solid-1 shadow-2xl flex flex-col overflow-hidden"
      :class="visible ? 'translate-x-0' : 'translate-x-full'"
      style="transition: transform 0.3s cubic-bezier(0.4,0,0.2,1)"
    >
      <!-- Header -->
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
            class="text-xs px-2 py-1 rounded-full border"
            :style="{ borderColor: currentStage?.color, color: currentStage?.color }"
          >
            {{ currentStage?.name }}
          </span>
          <span v-if="card.value > 0" class="text-xs font-semibold text-woot-600">
            {{ formatCurrency(card.value, card.currency) }}
          </span>
        </div>
      </div>

      <!-- Body -->
      <div v-if="card" class="flex flex-1 overflow-hidden">
        <!-- ── Painel lateral esquerdo (dados fixos) ────────────────────────── -->
        <aside class="w-64 flex-shrink-0 border-r border-n-weak overflow-y-auto p-5 flex flex-col gap-5">
          <!-- Etapa -->
          <div>
            <label class="block text-xs font-medium text-n-slate-9 uppercase tracking-wide mb-1">
              {{ $t('funnels.card_detail.stage_label') }}
            </label>
            <select
              class="w-full px-3 py-2 text-sm border border-n-weak rounded-lg bg-n-solid-1
                     text-n-slate-12 focus:outline-none focus:border-woot-400"
              :value="card.stage_id"
              @change="onStageChange($event.target.value)"
            >
              <option v-for="s in allStages" :key="s.id" :value="s.id">{{ s.name }}</option>
            </select>
          </div>

          <!-- Responsável -->
          <div>
            <label class="block text-xs font-medium text-n-slate-9 uppercase tracking-wide mb-1">
              {{ $t('funnels.card_detail.assignee_label') }}
            </label>
            <div class="flex items-center gap-2">
              <img
                v-if="card.assigned_agent?.avatar"
                :src="card.assigned_agent.avatar"
                :alt="card.assigned_agent.name"
                class="size-7 rounded-full"
              />
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
            <label class="block text-xs font-medium text-n-slate-9 uppercase tracking-wide mb-1">
              {{ $t('funnels.card_detail.conversations_label') }}
            </label>
            <div
              v-for="conv in card.conversations || []"
              :key="conv.id"
              class="flex items-center gap-2 text-sm text-woot-600 cursor-pointer hover:underline py-0.5"
              role="button"
              :aria-label="$t('funnels.card_detail.open_conversation_aria')"
              tabindex="0"
              @click="openConversation(conv.id)"
              @keyup.enter="openConversation(conv.id)"
            >
              <i class="i-lucide-message-square size-4" aria-hidden="true" />
              {{ $t('funnels.card_detail.conversation') }} #{{ conv.id }}
              <span v-if="conv.is_primary" class="text-xs text-n-slate-9">
                ({{ $t('funnels.card_detail.primary_badge') }})
              </span>
            </div>
            <p v-if="!card.conversations?.length" class="text-sm text-n-slate-9">
              {{ $t('funnels.card_detail.no_conversations') }}
            </p>
          </div>
        </aside>

        <!-- ── Timeline central (scrollável) ────────────────────────────────── -->
        <main class="flex-1 flex flex-col overflow-hidden">
          <div class="flex-1 overflow-y-auto p-4 flex flex-col gap-3">
            <!-- Skeleton de loading da timeline -->
            <template v-if="loadingTimeline">
              <div v-for="i in 4" :key="i" class="flex gap-3">
                <div class="size-7 rounded-full bg-n-alpha-2 animate-pulse flex-shrink-0" />
                <div class="flex-1">
                  <div class="h-2.5 bg-n-alpha-2 rounded animate-pulse mb-2 w-1/3" />
                  <div class="h-10 bg-n-alpha-1 rounded-lg animate-pulse" />
                </div>
              </div>
            </template>

            <template v-else>
              <div
                v-for="item in timeline"
                :key="`${item.type}-${item.id}`"
                class="flex gap-3"
              >
                <div class="flex-shrink-0 mt-0.5">
                  <div
                    class="size-7 rounded-full flex items-center justify-center"
                    :class="item.type === 'message'
                      ? 'bg-woot-50 text-woot-600'
                      : 'bg-n-alpha-1 text-n-slate-9'"
                  >
                    <i
                      :class="item.type === 'message' ? 'i-lucide-message-circle' : 'i-lucide-activity'"
                      class="size-3.5"
                      aria-hidden="true"
                    />
                  </div>
                </div>
                <div class="flex-1 min-w-0">
                  <div class="text-xs text-n-slate-9 mb-0.5">
                    {{ item.user || item.sender || $t('funnels.card_detail.system') }}
                    · {{ formatTime(item.created_at) }}
                  </div>
                  <div
                    v-if="item.type === 'message'"
                    class="text-sm text-n-slate-12 bg-n-alpha-1 rounded-lg px-3 py-2"
                  >
                    {{ item.content }}
                  </div>
                  <div v-else class="text-sm text-n-slate-11 italic">
                    {{ formatEventLabel(item.event_type, item.payload) }}
                  </div>
                </div>
              </div>

              <div
                v-if="timeline.length === 0"
                class="text-center text-sm text-n-slate-9 py-8"
              >
                {{ $t('funnels.card_detail.no_history') }}
              </div>
            </template>
          </div>
        </main>
      </div>

      <!-- Loading state inicial -->
      <div v-else class="flex-1 flex items-center justify-center">
        <div class="animate-spin i-lucide-loader-circle size-8 text-woot-500" aria-label="Carregando..." />
      </div>
    </div>

    <!-- Modal de motivo de perda (ao trocar etapa pelo select) -->
    <LostReasonModal
      v-if="showLostModal"
      @confirm="confirmStageMove"
      @cancel="cancelStageMove"
    />
  </div>
</template>

<script>
import axios              from 'axios';
import { mapGetters }     from 'vuex';
import { useFunnelToast } from '../composables/useFunnelToast';
import LostReasonModal    from './LostReasonModal.vue';

export default {
  name: 'CardDetail',
  components: { LostReasonModal },

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
      showLostModal:   false,
      pendingStageId:  null,
      _cardSub:        null,
    };
  },

  computed: {
    ...mapGetters('funnels', ['stages']),
    allStages()    { return this.stages; },
    currentStage() { return this.stages.find(s => s.id === this.card?.stage_id); },
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
    onKeyUp(e) {
      if (e.key === 'Escape') this.close();
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
      this._cardSub = window.actionCable.subscriptions.create(
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
        this.timeline = data.timeline || [];
      } finally {
        this.loadingTimeline = false;
      }
    },

    // Troca de etapa pelo select do painel lateral
    onStageChange(stageId) {
      const stage = this.stages.find(s => s.id === Number(stageId));
      if (stage?.stage_type === 'lost') {
        this.pendingStageId = Number(stageId);
        this.showLostModal  = true;
      } else {
        this.executeStageMove(Number(stageId), null);
      }
    },

    confirmStageMove(reason) {
      this.showLostModal = false;
      this.executeStageMove(this.pendingStageId, reason);
      this.pendingStageId = null;
    },

    cancelStageMove() {
      this.showLostModal  = false;
      this.pendingStageId = null;
      // Restaura o select para o valor atual (força re-render)
      if (this.card) this.card = { ...this.card };
    },

    async executeStageMove(stageId, lostReason) {
      const { funnelId, cardId } = this.$route.params;
      const accountId = this.$store.getters['getCurrentAccountId'];
      const fromStageId = this.card.stage_id;

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
        // Reverte o select visualmente
        this.card = { ...this.card };
        this.toastError(this.$t('funnels.move_error'));
      }
    },

    close() {
      this.visible = false;
      setTimeout(() => this.$router.back(), 300);
    },

    openConversation(convId) {
      const accountId = this.$store.getters['getCurrentAccountId'];
      this.$router.push(`/app/accounts/${accountId}/conversations/${convId}`);
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

    formatEventLabel(type, payload = {}) {
      const key = `funnels.events.${type}`;
      if (this.$te && this.$te(key)) {
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
