<template>
  <div class="funnels-container flex h-full overflow-hidden bg-n-background">

    <!-- ── Sidebar interna de funis ──────────────────────────────────────────── -->
    <aside class="funnels-sidebar flex flex-col w-56 flex-shrink-0 border-r border-n-weak bg-n-solid-1">
      <div class="px-4 py-3 border-b border-n-weak">
        <h2 class="text-sm font-semibold text-n-slate-12">
          {{ $t('funnels.sidebar_title') }}
        </h2>
      </div>

      <!-- Skeleton enquanto carrega pela primeira vez -->
      <div v-if="isLoading && funnels.length === 0" class="flex-1 py-2">
        <div v-for="i in 4" :key="i" class="flex items-center gap-2 px-4 py-2">
          <div class="size-2 rounded-full bg-n-alpha-3 animate-pulse flex-shrink-0" />
          <div
            class="h-3 rounded bg-n-alpha-3 animate-pulse"
            :style="{ width: [70, 90, 60, 80][i % 4] + 'px' }"
          />
        </div>
      </div>

      <!-- Lista de funis -->
      <nav v-else class="flex-1 overflow-y-auto py-2">
        <button
          v-for="funnel in funnels"
          :key="funnel.id"
          class="w-full flex items-center gap-2 px-4 py-2 text-sm text-left hover:bg-n-alpha-1 transition-colors"
          :class="currentFunnel?.id === funnel.id
            ? 'bg-n-alpha-2 text-n-slate-12 font-medium'
            : 'text-n-slate-11'"
          @click="navigateToFunnel(funnel.id)"
        >
          <span
            class="size-2 rounded-full flex-shrink-0"
            :style="{ backgroundColor: funnel.color }"
            aria-hidden="true"
          />
          <span class="truncate">{{ funnel.name }}</span>
          <span class="ml-auto text-xs text-n-slate-9" aria-hidden="true">
            {{ funnel.cards_count }}
          </span>
        </button>

        <p v-if="!isLoading && funnels.length === 0" class="px-4 py-3 text-xs text-n-slate-9">
          {{ $t('funnels.no_funnels_yet') }}
        </p>
      </nav>

      <!-- Rodapé da sidebar -->
      <div class="px-3 py-2 border-t border-n-weak flex items-center gap-1">
        <button
          class="flex-1 flex items-center gap-2 px-3 py-1.5 text-sm text-n-slate-11
                 hover:text-n-slate-12 hover:bg-n-alpha-1 rounded-md transition-colors"
          @click="openCreateFunnelModal"
        >
          <i class="i-lucide-plus size-4" aria-hidden="true" />
          <span>{{ $t('funnels.new_funnel') }}</span>
        </button>
        <button
          class="flex items-center justify-center p-1.5 text-n-slate-8
                 hover:text-n-slate-12 hover:bg-n-alpha-1 rounded-md transition-colors"
          :aria-label="$t('funnels.settings.page_title')"
          @click="$router.push({ name: 'funnels_settings' })"
        >
          <i class="i-lucide-settings size-4" aria-hidden="true" />
        </button>
      </div>
    </aside>

    <!-- ── Área principal ─────────────────────────────────────────────────────── -->
    <div class="flex-1 flex flex-col overflow-hidden">

      <!-- Header do Kanban -->
      <header
        v-if="currentFunnel"
        class="flex items-center justify-between px-6 py-3 border-b border-n-weak bg-n-solid-1 flex-shrink-0"
      >
        <div class="flex items-center gap-3">
          <h1 class="text-base font-semibold text-n-slate-12">{{ currentFunnel.name }}</h1>
          <span class="text-xs text-n-slate-9 bg-n-alpha-1 px-2 py-0.5 rounded-full">
            {{ $t('funnels.board.cards_count', { n: totalActiveCards }) }}
          </span>
        </div>
        <div class="flex items-center gap-2">
          <!-- Filtros toggle -->
          <button
            class="flex items-center gap-1.5 px-3 py-1.5 text-sm border rounded-md
                   transition-colors"
            :class="showFilters || activeFilterCount > 0
              ? 'border-woot-400 text-woot-600 bg-woot-50/50 dark:bg-woot-900/10'
              : 'border-n-weak text-n-slate-11 hover:bg-n-alpha-1'"
            @click="showFilters = !showFilters"
          >
            <i class="i-lucide-sliders-horizontal size-4" aria-hidden="true" />
            <span>{{ $t('funnels.filters.title') }}</span>
            <span
              v-if="activeFilterCount > 0"
              class="size-4 rounded-full bg-woot-500 text-white text-[10px] font-bold
                     flex items-center justify-center"
            >
              {{ activeFilterCount }}
            </span>
          </button>

          <button
            class="flex items-center gap-1.5 px-3 py-1.5 text-sm text-n-slate-11
                   border border-n-weak rounded-md hover:bg-n-alpha-1 transition-colors"
            @click="showFinalStages = !showFinalStages"
          >
            <i
              :class="showFinalStages ? 'i-lucide-eye-off' : 'i-lucide-eye'"
              class="size-4"
              aria-hidden="true"
            />
            {{ showFinalStages
                ? $t('funnels.board.hide_final')
                : $t('funnels.board.show_final') }}
          </button>
          <button
            class="flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium text-white
                   bg-woot-500 rounded-md hover:bg-woot-600 transition-colors"
            @click="openCreateCard"
          >
            <i class="i-lucide-plus size-4" aria-hidden="true" />
            {{ $t('funnels.board.new_card') }}
          </button>
        </div>
      </header>

      <!-- Painel de filtros -->
      <KanbanFilters
        :show="showFilters"
        @apply="onApplyFilters"
      />

      <!-- Skeleton do Kanban durante carregamento de funil -->
      <KanbanSkeleton
        v-if="isLoading && currentFunnel"
        :columns="visibleStages.length || 4"
      />

      <!-- Kanban Board -->
      <KanbanBoard
        v-else-if="currentFunnel"
        :funnel="currentFunnel"
        :stages="visibleStages"
        :cards-by-stage="filteredCardsByStage"
        :loading-cards="isLoadingCards"
        @card-moved="onCardMoved"
        @card-click="onCardClick"
        @create-card="openCreateCardInStage"
        @cancel-move="onCancelMove"
      />

      <!-- Estado vazio -->
      <FunnelEmptyState
        v-else-if="!currentFunnel && !isLoading"
        :has-funnels="funnels.length > 0"
        @create="openCreateFunnelModal"
      />
    </div>

    <!-- Rota filha: painel de detalhe do card -->
    <router-view />

    <!-- Modal criar card -->
    <CreateCardModal
      v-if="showCreateModal"
      :funnel="currentFunnel"
      :stages="stages"
      :initial-stage-id="createModalStageId"
      @close="showCreateModal = false"
      @created="onCardCreated"
    />

    <!-- Modal criar funil -->
    <div
      v-if="showCreateFunnelModal"
      class="fixed inset-0 z-50 flex items-center justify-center bg-black/40"
      role="dialog"
      :aria-modal="true"
      :aria-label="$t('funnels.create_funnel_modal.title')"
      @click.self="showCreateFunnelModal = false"
    >
      <div class="bg-n-solid-1 rounded-xl shadow-xl w-full max-w-sm mx-4 p-6">
        <h2 class="text-base font-semibold text-n-slate-12 mb-4">
          {{ $t('funnels.create_funnel_modal.title') }}
        </h2>
        <input
          ref="funnelNameInput"
          v-model="newFunnelName"
          type="text"
          :placeholder="$t('funnels.create_funnel_modal.name_placeholder')"
          class="w-full px-3 py-2 text-sm border border-n-weak rounded-lg bg-n-solid-1
                 text-n-slate-12 placeholder-n-slate-9 focus:outline-none focus:border-woot-400 mb-4"
          @keyup.enter="submitCreateFunnel"
          @keyup.esc="showCreateFunnelModal = false"
        />
        <div class="flex gap-3">
          <button
            class="flex-1 px-4 py-2 text-sm border border-n-weak rounded-lg
                   text-n-slate-11 hover:bg-n-alpha-1 transition-colors"
            @click="showCreateFunnelModal = false"
          >
            {{ $t('funnels.cancel') }}
          </button>
          <button
            :disabled="!newFunnelName.trim() || creatingFunnel"
            class="flex-1 px-4 py-2 text-sm font-medium text-white bg-woot-500
                   rounded-lg hover:bg-woot-600 disabled:opacity-50 transition-colors
                   flex items-center justify-center gap-2"
            @click="submitCreateFunnel"
          >
            <i v-if="creatingFunnel" class="i-lucide-loader-circle animate-spin size-4" aria-hidden="true" />
            {{ creatingFunnel ? $t('funnels.creating') : $t('funnels.create') }}
          </button>
        </div>
      </div>
    </div>

    <!-- Sistema de toasts -->
    <FunnelToast />
  </div>
</template>

<script>
import { mapGetters, mapActions } from 'vuex';
import KanbanBoard      from './components/KanbanBoard.vue';
import KanbanSkeleton   from './components/KanbanSkeleton.vue';
import KanbanFilters    from './components/KanbanFilters.vue';
import CreateCardModal  from './components/CreateCardModal.vue';
import FunnelEmptyState from './components/FunnelEmptyState.vue';
import FunnelToast      from './components/FunnelToast.vue';
import { useFunnelToast } from './composables/useFunnelToast';

export default {
  name: 'FunnelsIndex',
  components: {
    KanbanBoard, KanbanSkeleton, KanbanFilters, CreateCardModal, FunnelEmptyState, FunnelToast,
  },

  setup() {
    const { success, error } = useFunnelToast();
    return { toastSuccess: success, toastError: error };
  },

  data() {
    return {
      showFinalStages:       false,
      showCreateModal:       false,
      createModalStageId:    null,
      showCreateFunnelModal: false,
      newFunnelName:         '',
      creatingFunnel:        false,
      showFilters:           false,
      activeFilters:         null,   // null = no filters applied
    };
  },

  computed: {
    ...mapGetters('funnels', [
      'allFunnels', 'currentFunnel', 'stages',
      'isLoading', 'isLoadingCards', 'funnelsLoaded',
    ]),

    funnels() { return this.allFunnels; },

    visibleStages() {
      return this.showFinalStages
        ? this.stages
        : this.stages.filter(s => s.stage_type === 'intermediate');
    },

    cardsByStage() {
      const result = {};
      this.stages.forEach(s => {
        result[s.id] = this.$store.getters['funnels/cardsByStage'](s.id);
      });
      return result;
    },

    /** cardsByStage com filtros aplicados */
    filteredCardsByStage() {
      const f = this.activeFilters;
      if (!f) return this.cardsByStage;

      const result = {};
      const stageMap = Object.fromEntries(this.stages.map(s => [s.id, s]));

      Object.entries(this.cardsByStage).forEach(([stageId, cards]) => {
        const stage = stageMap[stageId];
        // Stage type filter
        if (f.stageType && stage?.stage_type !== f.stageType) {
          result[stageId] = [];
          return;
        }
        result[stageId] = cards.filter(card => {
          if (f.assigneeId && card.assigned_agent?.id !== f.assigneeId) return false;
          if (f.valueMin !== null && f.valueMin !== '' && (card.value || 0) < Number(f.valueMin)) return false;
          if (f.valueMax !== null && f.valueMax !== '' && (card.value || 0) > Number(f.valueMax)) return false;
          if (f.daysMin  !== null && f.daysMin  !== '' && (card.days_in_stage || 0) < Number(f.daysMin)) return false;
          if (f.daysMax  !== null && f.daysMax  !== '' && (card.days_in_stage || 0) > Number(f.daysMax)) return false;
          if (f.hasConversation && !card.conversations?.length) return false;
          return true;
        });
      });
      return result;
    },

    activeFilterCount() {
      const f = this.activeFilters;
      if (!f) return 0;
      return [
        !!f.assigneeId,
        !!f.stageType,
        f.valueMin !== null && f.valueMin !== '',
        f.valueMax !== null && f.valueMax !== '',
        f.daysMin  !== null && f.daysMin  !== '',
        f.daysMax  !== null && f.daysMax  !== '',
        f.hasConversation,
      ].filter(Boolean).length;
    },

    totalActiveCards() {
      return this.visibleStages.reduce(
        (sum, s) => sum + (this.filteredCardsByStage[s.id]?.length || 0), 0
      );
    },
  },

  watch: {
    '$route.query.funnel': {
      immediate: true,
      handler(funnelId) {
        if (!funnelId) return;
        const id = Number(funnelId);
        if (this.currentFunnel?.id !== id) {
          this.$store.dispatch('funnels/selectFunnel', id);
        }
      },
    },

    currentFunnel(newF, oldF) {
      if (newF?.id !== oldF?.id) {
        this.showFinalStages = false;
        if (newF) this.subscribeToFunnelChannel(newF.id);
      }
    },

    funnelsLoaded(loaded) {
      if (loaded && !this.$route.query.funnel && !this.currentFunnel) {
        this.selectDefaultFunnel();
      }
    },
  },

  created() {
    this.$store.dispatch('funnels/fetchFunnels').then(() => {
      if (this.$route.query.funnel) {
        this.$store.dispatch('funnels/selectFunnel', Number(this.$route.query.funnel));
      } else if (!this.currentFunnel) {
        this.selectDefaultFunnel();
      }
    });
  },

  beforeUnmount() {
    this.unsubscribeFunnelChannel();
  },

  methods: {
    ...mapActions('funnels', ['fetchFunnels', 'moveCard', 'applyRealtimeEvent']),

    selectDefaultFunnel() {
      if (this.funnels.length === 0) return;
      const def = this.funnels.find(f => f.is_default) || this.funnels[0];
      this.$store.dispatch('funnels/selectFunnel', def.id);
      this.$router.replace({ name: 'funnels_index', query: { funnel: def.id } }).catch(() => {});
    },

    navigateToFunnel(funnelId) {
      if (this.currentFunnel?.id === funnelId) return;
      this.$router.push({ name: 'funnels_index', query: { funnel: funnelId } });
    },

    openCreateCard() {
      this.createModalStageId = this.stages.find(s => s.stage_type === 'intermediate')?.id || null;
      this.showCreateModal = true;
    },

    openCreateCardInStage(stageId) {
      this.createModalStageId = stageId;
      this.showCreateModal = true;
    },

    onCardClick(card) {
      this.$router.push({
        name: 'funnels_card_detail',
        params: { funnelId: this.currentFunnel.id, cardId: card.id },
      });
    },

    onCardMoved({ cardId, fromStageId, toStageId, lostReason }) {
      this.moveCard({
        funnelId: this.currentFunnel.id,
        cardId,
        stageId: toStageId,
        fromStageId,
        lostReason,
      });
    },

    onCancelMove() {
      if (this.currentFunnel) {
        this.$store.dispatch('funnels/fetchAllCards', { funnelId: this.currentFunnel.id });
      }
    },

    onApplyFilters(filters) {
      const isEmpty = !filters.assigneeId && !filters.stageType
        && (filters.valueMin === null || filters.valueMin === '')
        && (filters.valueMax === null || filters.valueMax === '')
        && (filters.daysMin  === null || filters.daysMin  === '')
        && (filters.daysMax  === null || filters.daysMax  === '')
        && !filters.hasConversation;
      this.activeFilters = isEmpty ? null : filters;
    },

    onCardCreated() {
      this.showCreateModal = false;
      this.$store.dispatch('funnels/fetchFunnels');
    },

    openCreateFunnelModal() {
      this.newFunnelName = '';
      this.showCreateFunnelModal = true;
      this.$nextTick(() => this.$refs.funnelNameInput?.focus());
    },

    async submitCreateFunnel() {
      const name = this.newFunnelName.trim();
      if (!name) return;
      this.creatingFunnel = true;
      try {
        const accountId = this.$store.getters['getCurrentAccountId'];
        const axios = (await import('axios')).default;
        const { data } = await axios.post(`/api/v1/accounts/${accountId}/funnels`, {
          funnel: { name },
        });
        await this.$store.dispatch('funnels/fetchFunnels');
        this.showCreateFunnelModal = false;
        this.toastSuccess(this.$t('funnels.create_funnel_modal.success'));
        this.navigateToFunnel(data.id);
      } catch {
        this.toastError(this.$t('funnels.create_funnel_modal.error'));
      } finally {
        this.creatingFunnel = false;
      }
    },

    // ── ActionCable ────────────────────────────────────────────────────────────

    subscribeToFunnelChannel(funnelId) {
      this.unsubscribeFunnelChannel();
      if (!window.actionCable) return;
      const authUser = this.$store.getters['auth/getCurrentUser'];
      this._funnelSubscription = window.actionCable.subscriptions.create(
        {
          channel:      'Funnels::FunnelChannel',
          funnel_id:    funnelId,
          account_id:   this.$store.getters['getCurrentAccountId'],
          pubsub_token: authUser?.pubsub_token,
          user_id:      authUser?.id,
        },
        {
          received: (payload) => {
            const { event, card, stage_id } = payload;
            if (event === 'stage_updated' && stage_id) {
              this.$store.dispatch('funnels/refreshStageCount', stage_id);
            } else if (event && card) {
              this.applyRealtimeEvent({ event, card });
            }
          },
        }
      );
    },

    unsubscribeFunnelChannel() {
      if (this._funnelSubscription) {
        this._funnelSubscription.unsubscribe();
        this._funnelSubscription = null;
      }
    },
  },
};
</script>
