<template>
  <div
    class="kanban-card bg-n-solid-1 rounded-lg border border-n-weak p-3 cursor-pointer
           hover:border-woot-400 hover:shadow-sm transition-all duration-150 select-none"
    :data-id="card.id"
    role="button"
    tabindex="0"
    @click.stop="$emit('click', card)"
    @keyup.enter="$emit('click', card)"
  >
    <!-- Título -->
    <p class="text-sm font-medium text-n-slate-12 leading-snug mb-1.5 line-clamp-2">
      {{ card.title }}
    </p>

    <!-- Contato vinculado -->
    <div v-if="card.contact_name" class="flex items-center gap-1 mb-1.5 min-w-0">
      <i class="i-lucide-user size-3 text-n-slate-9 flex-shrink-0" aria-hidden="true" />
      <span class="text-xs text-n-slate-10 truncate">{{ card.contact_name }}</span>
      <template v-if="card.contact_phone">
        <span class="text-xs text-n-slate-7" aria-hidden="true">·</span>
        <span class="text-xs text-n-slate-9 flex-shrink-0">{{ card.contact_phone }}</span>
      </template>
    </div>

    <!-- Valor -->
    <div v-if="card.value > 0" class="text-xs font-semibold text-woot-600 mb-1.5">
      {{ formatCurrency(card.value, card.currency) }}
    </div>

    <!-- Labels da conversa -->
    <div v-if="card.labels && card.labels.length > 0" class="flex flex-wrap gap-1 mb-2">
      <span
        v-for="label in card.labels.slice(0, 3)"
        :key="label"
        class="text-[10px] px-1.5 py-0.5 rounded-full bg-woot-50 text-woot-700 leading-tight"
      >
        {{ label }}
      </span>
      <span
        v-if="card.labels.length > 3"
        class="text-[10px] px-1.5 py-0.5 rounded-full bg-n-alpha-2 text-n-slate-9 leading-tight"
      >
        +{{ card.labels.length - 3 }}
      </span>
    </div>

    <!-- Footer: agente + conversa + dias na etapa -->
    <div class="flex items-center justify-between mt-1">
      <div class="flex items-center gap-1.5">
        <img
          v-if="card.assigned_agent?.avatar"
          :src="card.assigned_agent.avatar"
          :alt="card.assigned_agent.name"
          class="size-5 rounded-full object-cover"
          :title="card.assigned_agent.name"
        />
        <span
          v-else-if="card.assigned_agent"
          class="size-5 rounded-full bg-woot-100 flex items-center justify-center
                 text-woot-700 text-[10px] font-bold"
          :title="card.assigned_agent.name"
          aria-hidden="true"
        >
          {{ initials(card.assigned_agent.name) }}
        </span>
        <i
          v-if="card.primary_conversation_id"
          class="i-lucide-message-square size-3.5 text-n-slate-9"
          :aria-label="$t('funnels.card.linked_conversation_aria')"
        />
      </div>
      <span
        class="text-[11px] px-1.5 py-0.5 rounded-full flex-shrink-0"
        :class="daysClass"
        :title="$t('funnels.card.days_in_stage', { n: card.days_in_stage })"
        aria-hidden="true"
      >
        {{ card.days_in_stage }}d
      </span>
    </div>
  </div>
</template>

<script>
export default {
  name: 'KanbanCard',
  props: {
    card: { type: Object, required: true },
  },
  emits: ['click'],

  computed: {
    daysClass() {
      const d = this.card.days_in_stage || 0;
      if (d <= 3)  return 'bg-n-alpha-1 text-n-slate-9';
      if (d <= 7)  return 'bg-yellow-50 text-yellow-700';
      if (d <= 14) return 'bg-orange-50 text-orange-700';
      return 'bg-red-50 text-red-700';
    },
  },

  methods: {
    initials(name) {
      return (name || '?').split(' ').slice(0, 2).map(p => p[0]).join('').toUpperCase();
    },
    formatCurrency(value, currency = 'BRL') {
      return new Intl.NumberFormat('pt-BR', {
        style: 'currency', currency: currency || 'BRL',
        minimumFractionDigits: 0,
      }).format(value);
    },
  },
};
</script>
