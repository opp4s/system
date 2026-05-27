<template>
  <Transition
    enter-active-class="transition-all duration-200 ease-out"
    enter-from-class="opacity-0 -translate-y-2"
    enter-to-class="opacity-100 translate-y-0"
    leave-active-class="transition-all duration-150 ease-in"
    leave-from-class="opacity-100 translate-y-0"
    leave-to-class="opacity-0 -translate-y-2"
  >
    <div
      v-if="show"
      class="flex-shrink-0 bg-n-solid-1 border-b border-n-weak px-6 py-4"
    >
      <div class="flex flex-wrap items-end gap-4">

        <!-- ── Responsável ────────────────────────────────────────────────── -->
        <div class="flex flex-col gap-1 min-w-[160px]">
          <label class="text-xs font-medium text-n-slate-9 uppercase tracking-wide">
            {{ $t('funnels.filters.assignee_label') }}
          </label>
          <select
            v-model="draft.assigneeId"
            class="text-sm border border-n-weak rounded-lg px-3 py-1.5 bg-n-solid-1
                   text-n-slate-12 focus:outline-none focus:border-woot-400 transition-colors"
          >
            <option value="">{{ $t('funnels.filters.assignee_all') }}</option>
            <option
              v-for="agent in agents"
              :key="agent.id"
              :value="agent.id"
            >
              {{ agent.name }}
            </option>
          </select>
        </div>

        <!-- ── Tipo de etapa ──────────────────────────────────────────────── -->
        <div class="flex flex-col gap-1 min-w-[140px]">
          <label class="text-xs font-medium text-n-slate-9 uppercase tracking-wide">
            {{ $t('funnels.filters.stage_type_label') }}
          </label>
          <select
            v-model="draft.stageType"
            class="text-sm border border-n-weak rounded-lg px-3 py-1.5 bg-n-solid-1
                   text-n-slate-12 focus:outline-none focus:border-woot-400 transition-colors"
          >
            <option value="">{{ $t('funnels.filters.stage_type_all') }}</option>
            <option value="intermediate">{{ $t('funnels.filters.stage_type_intermediate') }}</option>
            <option value="won">{{ $t('funnels.filters.stage_type_won') }}</option>
            <option value="lost">{{ $t('funnels.filters.stage_type_lost') }}</option>
          </select>
        </div>

        <!-- ── Valor ──────────────────────────────────────────────────────── -->
        <div class="flex flex-col gap-1">
          <label class="text-xs font-medium text-n-slate-9 uppercase tracking-wide">
            {{ $t('funnels.filters.value_label') }}
          </label>
          <div class="flex items-center gap-1.5">
            <input
              v-model.number="draft.valueMin"
              type="number"
              min="0"
              class="w-24 text-sm border border-n-weak rounded-lg px-2 py-1.5 bg-n-solid-1
                     text-n-slate-12 focus:outline-none focus:border-woot-400 transition-colors"
              :placeholder="$t('funnels.filters.value_min')"
            />
            <span class="text-n-slate-7 text-xs">–</span>
            <input
              v-model.number="draft.valueMax"
              type="number"
              min="0"
              class="w-24 text-sm border border-n-weak rounded-lg px-2 py-1.5 bg-n-solid-1
                     text-n-slate-12 focus:outline-none focus:border-woot-400 transition-colors"
              :placeholder="$t('funnels.filters.value_max')"
            />
          </div>
        </div>

        <!-- ── Dias na etapa ──────────────────────────────────────────────── -->
        <div class="flex flex-col gap-1">
          <label class="text-xs font-medium text-n-slate-9 uppercase tracking-wide">
            {{ $t('funnels.filters.days_label') }}
          </label>
          <div class="flex items-center gap-1.5">
            <input
              v-model.number="draft.daysMin"
              type="number"
              min="0"
              class="w-20 text-sm border border-n-weak rounded-lg px-2 py-1.5 bg-n-solid-1
                     text-n-slate-12 focus:outline-none focus:border-woot-400 transition-colors"
              :placeholder="$t('funnels.filters.days_min')"
            />
            <span class="text-n-slate-7 text-xs">–</span>
            <input
              v-model.number="draft.daysMax"
              type="number"
              min="0"
              class="w-20 text-sm border border-n-weak rounded-lg px-2 py-1.5 bg-n-solid-1
                     text-n-slate-12 focus:outline-none focus:border-woot-400 transition-colors"
              :placeholder="$t('funnels.filters.days_max')"
            />
          </div>
        </div>

        <!-- ── Com conversa ───────────────────────────────────────────────── -->
        <div class="flex items-center gap-2 pb-1.5">
          <div
            class="relative inline-flex cursor-pointer"
            @click="draft.hasConversation = !draft.hasConversation"
          >
            <div
              class="w-9 h-5 rounded-full transition-colors border border-n-weak"
              :class="draft.hasConversation ? 'bg-woot-500 border-woot-500' : 'bg-n-alpha-2'"
            >
              <div
                class="size-3.5 rounded-full bg-white shadow-sm transition-transform m-[3px]"
                :class="draft.hasConversation ? 'translate-x-4' : 'translate-x-0'"
              />
            </div>
          </div>
          <label
            class="text-sm text-n-slate-11 cursor-pointer select-none"
            @click="draft.hasConversation = !draft.hasConversation"
          >
            {{ $t('funnels.filters.has_conversation') }}
          </label>
        </div>

        <!-- ── Botões ─────────────────────────────────────────────────────── -->
        <div class="flex items-center gap-2 pb-1.5 ml-auto">
          <button
            class="px-3 py-1.5 text-xs text-n-slate-9 hover:text-n-slate-12
                   hover:bg-n-alpha-1 rounded-lg transition-colors border border-n-weak"
            @click="clearFilters"
          >
            {{ $t('funnels.filters.clear') }}
          </button>
          <button
            class="px-4 py-1.5 text-xs font-medium text-white bg-woot-500
                   hover:bg-woot-600 rounded-lg transition-colors"
            @click="applyFilters"
          >
            {{ activeCount > 0
              ? $t(activeCount === 1
                  ? 'funnels.filters.active_one'
                  : 'funnels.filters.active_many',
                  { n: activeCount })
              : $t('funnels.filters.title')
            }}
          </button>
        </div>

      </div>
    </div>
  </Transition>
</template>

<script>
import { mapGetters } from 'vuex';

const EMPTY_DRAFT = () => ({
  assigneeId:      '',
  stageType:       '',
  valueMin:        null,
  valueMax:        null,
  daysMin:         null,
  daysMax:         null,
  hasConversation: false,
});

export default {
  name: 'KanbanFilters',

  props: {
    show: { type: Boolean, default: false },
  },

  emits: ['apply'],

  data() {
    return {
      draft: EMPTY_DRAFT(),
    };
  },

  computed: {
    ...mapGetters({
      agents: 'agents/getAgents',
    }),

    activeCount() {
      const d = this.draft;
      return [
        !!d.assigneeId,
        !!d.stageType,
        d.valueMin !== null && d.valueMin !== '',
        d.valueMax !== null && d.valueMax !== '',
        d.daysMin  !== null && d.daysMin  !== '',
        d.daysMax  !== null && d.daysMax  !== '',
        d.hasConversation,
      ].filter(Boolean).length;
    },
  },

  methods: {
    applyFilters() {
      this.$emit('apply', { ...this.draft });
    },

    clearFilters() {
      this.draft = EMPTY_DRAFT();
      this.$emit('apply', EMPTY_DRAFT());
    },
  },
};
</script>
