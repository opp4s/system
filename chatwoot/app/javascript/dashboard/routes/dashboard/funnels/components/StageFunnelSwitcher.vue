<template>
  <div class="flex flex-col gap-4">

    <!-- ── Seletor de etapa ────────────────────────────────────────────────── -->
    <div>
      <label class="block text-xs font-medium text-n-slate-9 uppercase tracking-wide mb-1.5">
        {{ $t('funnels.stage_switcher.stage_label') }}
      </label>

      <div class="relative">
        <select
          :value="card.stage_id"
          class="w-full appearance-none px-3 py-2 pr-8 text-sm border border-n-weak rounded-lg
                 bg-n-solid-1 text-n-slate-12 focus:outline-none focus:border-woot-400
                 transition-colors cursor-pointer"
          :aria-label="$t('funnels.stage_switcher.stage_label')"
          @change="onStageSelect($event.target.value)"
        >
          <option v-for="s in stages" :key="s.id" :value="s.id">
            {{ s.name }}
          </option>
        </select>
        <!-- Indicador colorido da etapa atual -->
        <span
          class="absolute right-8 top-1/2 -translate-y-1/2 size-2 rounded-full pointer-events-none"
          :style="{ backgroundColor: currentStageColor }"
          aria-hidden="true"
        />
        <i
          class="i-lucide-chevrons-up-down absolute right-2.5 top-1/2 -translate-y-1/2
                 size-3.5 text-n-slate-9 pointer-events-none"
          aria-hidden="true"
        />
      </div>
    </div>

    <!-- ── Transferência para outro funil ─────────────────────────────────── -->
    <div class="border border-n-weak rounded-lg overflow-hidden">
      <button
        class="w-full flex items-center justify-between px-3 py-2 text-xs text-n-slate-11
               hover:bg-n-alpha-1 transition-colors"
        :class="showTransfer ? 'bg-n-alpha-1 text-n-slate-12' : ''"
        @click="toggleTransfer"
      >
        <span class="flex items-center gap-1.5">
          <i class="i-lucide-arrow-right-left size-3.5" aria-hidden="true" />
          {{ $t('funnels.stage_switcher.transfer_toggle') }}
        </span>
        <i
          :class="showTransfer ? 'i-lucide-chevron-up' : 'i-lucide-chevron-down'"
          class="size-3.5"
          aria-hidden="true"
        />
      </button>

      <Transition
        enter-active-class="transition-all duration-200 ease-out"
        enter-from-class="opacity-0 max-h-0"
        enter-to-class="opacity-100 max-h-96"
        leave-active-class="transition-all duration-150 ease-in"
        leave-from-class="opacity-100 max-h-96"
        leave-to-class="opacity-0 max-h-0"
      >
        <div v-if="showTransfer" class="px-3 pb-3 pt-2 border-t border-n-weak flex flex-col gap-3">

          <!-- Funil destino -->
          <div v-if="otherFunnels.length === 0" class="text-xs text-n-slate-9 text-center py-1">
            {{ $t('funnels.stage_switcher.no_other_funnels') }}
          </div>
          <template v-else>
            <div>
              <label class="block text-xs text-n-slate-9 mb-1">
                {{ $t('funnels.stage_switcher.target_funnel') }}
              </label>
              <select
                v-model="transferFunnelId"
                class="w-full px-3 py-2 text-sm border border-n-weak rounded-lg bg-n-solid-1
                       text-n-slate-12 focus:outline-none focus:border-woot-400"
                @change="onTransferFunnelChange"
              >
                <option value="">{{ $t('funnels.stage_switcher.target_funnel_placeholder') }}</option>
                <option v-for="f in otherFunnels" :key="f.id" :value="f.id">
                  {{ f.name }}
                </option>
              </select>
            </div>

            <!-- Etapa destino -->
            <div v-if="transferFunnelId">
              <label class="block text-xs text-n-slate-9 mb-1">
                {{ $t('funnels.stage_switcher.target_stage') }}
              </label>
              <div v-if="loadingTargetStages" class="flex items-center gap-1.5 text-xs text-n-slate-9 py-2">
                <i class="i-lucide-loader-circle animate-spin size-3" aria-hidden="true" />
                {{ $t('funnels.stage_switcher.loading_stages') }}
              </div>
              <select
                v-else
                v-model="transferStageId"
                class="w-full px-3 py-2 text-sm border border-n-weak rounded-lg bg-n-solid-1
                       text-n-slate-12 focus:outline-none focus:border-woot-400"
              >
                <option value="">{{ $t('funnels.stage_switcher.target_stage_placeholder') }}</option>
                <option v-for="s in targetStages" :key="s.id" :value="s.id">
                  {{ s.name }}
                </option>
              </select>
            </div>

            <!-- Ações -->
            <div class="flex gap-2">
              <button
                class="flex-1 px-3 py-1.5 text-xs border border-n-weak rounded-lg
                       text-n-slate-11 hover:bg-n-alpha-1 transition-colors"
                @click="showTransfer = false"
              >
                {{ $t('funnels.stage_switcher.cancel_transfer') }}
              </button>
              <button
                :disabled="!canTransfer"
                class="flex-1 px-3 py-1.5 text-xs font-medium text-white bg-woot-500
                       rounded-lg hover:bg-woot-600 disabled:opacity-40 transition-colors
                       flex items-center justify-center gap-1"
                @click="$emit('transfer', { funnelId: Number(transferFunnelId), stageId: Number(transferStageId) })"
              >
                <i class="i-lucide-send size-3" aria-hidden="true" />
                {{ $t('funnels.stage_switcher.confirm_transfer') }}
              </button>
            </div>
          </template>
        </div>
      </Transition>
    </div>

    <!-- LostReasonModal ao selecionar etapa "lost" -->
    <LostReasonModal
      v-if="showLostModal"
      @confirm="confirmLostMove"
      @cancel="cancelLostMove"
    />
  </div>
</template>

<script>
import axios           from 'axios';
import { mapGetters }  from 'vuex';
import LostReasonModal from './LostReasonModal.vue';

export default {
  name: 'StageFunnelSwitcher',
  components: { LostReasonModal },

  props: {
    card:            { type: Object, required: true },
    stages:          { type: Array,  default: () => [] },
    currentFunnelId: { type: Number, required: true },
  },

  emits: ['move', 'transfer'],

  data() {
    return {
      showTransfer:        false,
      transferFunnelId:    '',
      transferStageId:     '',
      targetStages:        [],
      loadingTargetStages: false,
      showLostModal:       false,
      pendingStageId:      null,
    };
  },

  computed: {
    ...mapGetters('funnels', ['allFunnels']),

    otherFunnels() {
      return this.allFunnels.filter(f => f.id !== this.currentFunnelId);
    },

    currentStageColor() {
      return this.stages.find(s => s.id === this.card.stage_id)?.color || 'transparent';
    },

    canTransfer() {
      return !!this.transferFunnelId && !!this.transferStageId && !this.loadingTargetStages;
    },
  },

  methods: {
    // ── Stage change ──────────────────────────────────────────────────────────

    onStageSelect(rawId) {
      const stageId = Number(rawId);
      const stage   = this.stages.find(s => s.id === stageId);

      if (stage?.stage_type === 'lost') {
        this.pendingStageId = stageId;
        this.showLostModal  = true;
      } else {
        this.$emit('move', { stageId, lostReason: null });
      }
    },

    confirmLostMove(reason) {
      this.$emit('move', { stageId: this.pendingStageId, lostReason: reason });
      this.pendingStageId = null;
      this.showLostModal  = false;
    },

    cancelLostMove() {
      this.pendingStageId = null;
      this.showLostModal  = false;
      // Força re-render do select para reverter visualmente
      this.$forceUpdate();
    },

    // ── Transfer ─────────────────────────────────────────────────────────────

    toggleTransfer() {
      this.showTransfer = !this.showTransfer;
      if (!this.showTransfer) {
        this.transferFunnelId = '';
        this.transferStageId  = '';
        this.targetStages     = [];
      }
    },

    async onTransferFunnelChange() {
      this.transferStageId = '';
      this.targetStages    = [];
      if (!this.transferFunnelId) return;

      this.loadingTargetStages = true;
      try {
        const accountId = this.$store.getters['getCurrentAccountId'];
        const { data }  = await axios.get(
          `/api/v1/accounts/${accountId}/funnels/${this.transferFunnelId}`
        );
        // Apenas etapas intermediárias como destino válido
        this.targetStages = (data.stages || []).filter(s => s.stage_type === 'intermediate');
        if (this.targetStages.length > 0) {
          this.transferStageId = this.targetStages[0].id;
        }
      } catch {
        this.targetStages = [];
      } finally {
        this.loadingTargetStages = false;
      }
    },
  },
};
</script>
