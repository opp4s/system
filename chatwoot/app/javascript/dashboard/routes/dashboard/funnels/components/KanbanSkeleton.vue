<template>
  <div class="flex flex-1 overflow-x-auto gap-3 p-4">
    <div
      v-for="col in columns"
      :key="col"
      class="flex flex-col w-80 flex-shrink-0 rounded-xl bg-n-alpha-1 border border-n-weak"
    >
      <!-- Column header skeleton -->
      <div class="flex items-center gap-2 px-3 py-2.5 border-b border-n-weak">
        <div class="size-2.5 rounded-full bg-n-alpha-3 animate-pulse" />
        <div class="h-3 rounded bg-n-alpha-3 animate-pulse" :style="{ width: col % 2 === 0 ? '80px' : '64px' }" />
        <div class="ml-auto h-4 w-6 rounded-full bg-n-alpha-2 animate-pulse" />
      </div>

      <!-- Card skeletons -->
      <div class="p-2 flex flex-col gap-2">
        <div
          v-for="card in cardsFor(col)"
          :key="card"
          class="bg-n-solid-1 rounded-lg border border-n-weak p-3"
        >
          <!-- Title -->
          <div class="h-3 rounded bg-n-alpha-3 animate-pulse mb-1.5" :style="{ width: titleWidth(col, card) }" />
          <div v-if="card % 3 !== 0" class="h-3 rounded bg-n-alpha-2 animate-pulse mb-2.5" style="width: 55%" />
          <!-- Contact line (some cards) -->
          <div v-if="card % 2 === 0" class="h-2.5 rounded bg-n-alpha-2 animate-pulse mb-2" style="width: 70%" />
          <!-- Value (some cards) -->
          <div v-if="col % 2 !== 0" class="h-3 rounded bg-n-alpha-2 animate-pulse mb-2" style="width: 40%" />
          <!-- Footer -->
          <div class="flex items-center justify-between mt-1">
            <div class="size-5 rounded-full bg-n-alpha-2 animate-pulse" />
            <div class="h-4 w-7 rounded-full bg-n-alpha-2 animate-pulse" />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'KanbanSkeleton',
  props: {
    columns: { type: Number, default: 4 },
  },
  methods: {
    cardsFor(col) {
      // Vary card count per column for a realistic look
      return [2, 3, 4, 2, 3][col % 5] || 3;
    },
    titleWidth(col, card) {
      const widths = ['85%', '70%', '90%', '75%', '80%'];
      return widths[(col + card) % widths.length];
    },
  },
};
</script>
