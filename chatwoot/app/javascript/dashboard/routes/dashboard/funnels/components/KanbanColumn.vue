<template>
  <div
    class="kanban-column flex flex-col w-80 flex-shrink-0 rounded-xl bg-n-alpha-1 border border-n-weak"
    :data-stage-id="stage.id"
    :data-stage-type="stage.stage_type"
  >
    <!-- Header da coluna -->
    <div class="flex items-center justify-between px-3 py-2.5 border-b border-n-weak flex-shrink-0">
      <div class="flex items-center gap-2 min-w-0">
        <span
          class="size-2.5 rounded-full flex-shrink-0"
          :style="{ backgroundColor: stage.color }"
        />
        <h3 class="text-sm font-medium text-n-slate-12 truncate">{{ stage.name }}</h3>
        <span class="text-xs text-n-slate-9 bg-n-alpha-2 px-1.5 py-0.5 rounded-full flex-shrink-0">
          {{ localCards.length }}
        </span>
      </div>
      <div class="flex items-center gap-1 flex-shrink-0">
        <span v-if="totalValue > 0" class="text-xs text-n-slate-10">
          R$ {{ formatValue(totalValue) }}
        </span>
        <button
          class="size-6 flex items-center justify-center rounded hover:bg-n-alpha-2 text-n-slate-9 hover:text-n-slate-12 transition-colors"
          :aria-label="$t('funnels.column.add_card_aria', { stage: stage.name })"
          @click="$emit('create-card')"
        >
          <i class="i-lucide-plus size-3.5" aria-hidden="true" />
        </button>
      </div>
    </div>

    <!--
      Lista com drag-and-drop.
      Virtual scroll real (DynamicScroller) é incompatível com SortableJS —
      colunas com 50+ cards usam overflow-y: auto + SortableJS scroll nativo,
      que faz auto-scroll dentro da coluna ao arrastar perto das bordas.
    -->
    <draggable
      v-model="localCards"
      class="flex-1 overflow-y-auto p-2 flex flex-col gap-2 min-h-[4rem]"
      :group="{ name: 'cards' }"
      item-key="id"
      ghost-class="opacity-40"
      chosen-class="scale-[1.02] shadow-lg ring-1 ring-woot-400"
      drag-class="rotate-1 opacity-90"
      :animation="150"
      :scroll="true"
      :scroll-sensitivity="60"
      :scroll-speed="12"
      :move="onDragMove"
      @end="onDragEnd"
    >
      <template #item="{ element: card }">
        <KanbanCard
          :card="card"
          @click="$emit('card-click', card)"
        />
      </template>
    </draggable>

    <!-- Modal de motivo de perda -->
    <LostReasonModal
      v-if="showLostModal"
      @confirm="confirmLostMove"
      @cancel="cancelLostMove"
    />
  </div>
</template>

<script>
import { VueDraggableNext as draggable } from 'vue-draggable-next';
import KanbanCard      from './KanbanCard.vue';
import LostReasonModal from './LostReasonModal.vue';

export default {
  name: 'KanbanColumn',
  components: { draggable, KanbanCard, LostReasonModal },

  props: {
    stage:   { type: Object,  required: true },
    cards:   { type: Array,   default: () => [] },
    loading: { type: Boolean, default: false },
  },

  emits: ['card-moved', 'card-click', 'create-card', 'cancel-move'],

  data() {
    return {
      localCards:      [...this.cards],
      showLostModal:   false,
      pendingLostMove: null,
    };
  },

  computed: {
    totalValue() {
      return this.cards.reduce((sum, c) => sum + (c.value || 0), 0);
    },
  },

  watch: {
    cards(newCards) {
      this.localCards = [...newCards];
    },
  },

  methods: {
    // ── Drag-and-drop ─────────────────────────────────────────────────────────

    // SortableJS :move hook — retorna false para bloquear drops em 'lost'
    onDragMove(evt) {
      const toEl = evt.to?.closest('[data-stage-id]');
      if (!toEl) return true;

      if (toEl.dataset.stageType === 'lost') {
        // Abre modal UMA vez por sequência de drag, bloqueia o drop
        if (!this.showLostModal && !this.pendingLostMove) {
          const fromEl = evt.from?.closest('[data-stage-id]');
          this.pendingLostMove = {
            cardId:      evt.draggedContext?.element?.id,
            fromStageId: Number(fromEl?.dataset?.stageId),
            toStageId:   Number(toEl.dataset.stageId),
          };
          this.showLostModal = true;
        }
        return false; // card volta para a posição original
      }

      return true;
    },

    onDragEnd(evt) {
      if (this.showLostModal || this.pendingLostMove) return;
      if (evt.from === evt.to) return;

      const cardId      = evt.item?.dataset?.id
        ? Number(evt.item.dataset.id)
        : this.localCards[evt.newIndex]?.id;
      const toEl        = evt.to?.closest('[data-stage-id]');
      const fromEl      = evt.from?.closest('[data-stage-id]');
      if (!toEl || !fromEl) return;

      const toStageId   = Number(toEl.dataset.stageId);
      const fromStageId = Number(fromEl.dataset.stageId);
      if (toStageId === fromStageId) return;

      this.$emit('card-moved', { cardId, fromStageId, toStageId });
    },

    // ── Modal de perda ────────────────────────────────────────────────────────

    confirmLostMove(reason) {
      if (!this.pendingLostMove) return;
      const { cardId, fromStageId, toStageId } = this.pendingLostMove;
      this.$emit('card-moved', { cardId, fromStageId, toStageId, lostReason: reason });
      this.pendingLostMove = null;
      this.showLostModal   = false;
    },

    cancelLostMove() {
      this.pendingLostMove = null;
      this.showLostModal   = false;
      this.$emit('cancel-move');
    },

    // ── Helpers ───────────────────────────────────────────────────────────────

    formatValue(val) {
      return new Intl.NumberFormat('pt-BR', { minimumFractionDigits: 0 }).format(val);
    },
  },
};
</script>
