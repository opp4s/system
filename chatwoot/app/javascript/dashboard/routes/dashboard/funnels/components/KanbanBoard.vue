<template>
  <div
    ref="board"
    class="kanban-board flex flex-1 overflow-x-auto overflow-y-hidden gap-3 p-4"
    role="region"
    :aria-label="funnel.name"
    @dragover="onBoardDragOver"
  >
    <KanbanColumn
      v-for="stage in stages"
      :key="stage.id"
      :stage="stage"
      :cards="cardsByStage[stage.id] || []"
      :loading="loadingCards"
      @card-moved="$emit('card-moved', $event)"
      @card-click="$emit('card-click', $event)"
      @create-card="$emit('create-card', stage.id)"
      @cancel-move="$emit('cancel-move')"
    />
    <div
      v-if="stages.length === 0 && !loadingCards"
      class="flex-1 flex items-center justify-center text-n-slate-9 text-sm"
    >
      {{ $t('funnels.board.no_stages') }}
    </div>
  </div>
</template>

<script>
import KanbanColumn from './KanbanColumn.vue';

const EDGE_THRESHOLD = 80;
const SCROLL_SPEED   = 10;

export default {
  name: 'KanbanBoard',
  components: { KanbanColumn },

  props: {
    funnel:       { type: Object,  required: true },
    stages:       { type: Array,   default: () => [] },
    cardsByStage: { type: Object,  default: () => ({}) },
    loadingCards: { type: Boolean, default: false },
  },

  emits: ['card-moved', 'card-click', 'create-card', 'cancel-move'],

  data() {
    return {
      _scrollRaf: null,
      _scrollDir: 0,
    };
  },

  mounted() {
    document.addEventListener('dragend', this.stopAutoScroll);
  },

  beforeUnmount() {
    document.removeEventListener('dragend', this.stopAutoScroll);
    this.stopAutoScroll();
  },

  methods: {
    onBoardDragOver(evt) {
      const board = this.$refs.board;
      if (!board) return;
      const rect = board.getBoundingClientRect();
      const x    = evt.clientX;
      if (x - rect.left < EDGE_THRESHOLD)   this.startAutoScroll(-1);
      else if (rect.right - x < EDGE_THRESHOLD) this.startAutoScroll(1);
      else this.stopAutoScroll();
    },

    startAutoScroll(dir) {
      if (this._scrollDir === dir) return;
      this._scrollDir = dir;
      this.stopAutoScroll();
      const board = this.$refs.board;
      if (!board) return;
      const tick = () => {
        board.scrollLeft += dir * SCROLL_SPEED;
        this._scrollRaf = requestAnimationFrame(tick);
      };
      this._scrollRaf = requestAnimationFrame(tick);
    },

    stopAutoScroll() {
      if (this._scrollRaf) {
        cancelAnimationFrame(this._scrollRaf);
        this._scrollRaf = null;
      }
      this._scrollDir = 0;
    },
  },
};
</script>
