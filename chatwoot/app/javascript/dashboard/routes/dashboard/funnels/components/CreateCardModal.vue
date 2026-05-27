<template>
  <div
    class="fixed inset-0 z-50 flex items-center justify-center bg-black/40"
    role="dialog"
    :aria-modal="true"
    :aria-label="$t('funnels.create_card_modal.title')"
    @click.self="$emit('close')"
  >
    <div class="bg-n-solid-1 rounded-xl shadow-xl w-full max-w-md mx-4 p-6">
      <div class="flex items-center justify-between mb-5">
        <h2 class="text-base font-semibold text-n-slate-12">
          {{ $t('funnels.create_card_modal.title') }}
        </h2>
        <button
          class="text-n-slate-9 hover:text-n-slate-12 transition-colors"
          :aria-label="$t('funnels.close')"
          @click="$emit('close')"
        >
          <i class="i-lucide-x size-5" aria-hidden="true" />
        </button>
      </div>

      <form @submit.prevent="submit" @keyup.esc="$emit('close')">
        <div class="flex flex-col gap-4">
          <div>
            <label class="block text-sm text-n-slate-11 mb-1">
              {{ $t('funnels.create_card_modal.title_required') }}
            </label>
            <input
              ref="titleInput"
              v-model="form.title"
              type="text"
              required
              autofocus
              :placeholder="$t('funnels.create_card_modal.title_placeholder')"
              class="w-full px-3 py-2 text-sm border border-n-weak rounded-lg bg-n-solid-1
                     text-n-slate-12 placeholder-n-slate-9 focus:outline-none focus:border-woot-400"
            />
          </div>

          <div>
            <label class="block text-sm text-n-slate-11 mb-1">
              {{ $t('funnels.create_card_modal.stage_label') }}
            </label>
            <select
              v-model="form.stage_id"
              class="w-full px-3 py-2 text-sm border border-n-weak rounded-lg bg-n-solid-1
                     text-n-slate-12 focus:outline-none focus:border-woot-400"
            >
              <option v-for="s in intermediateStages" :key="s.id" :value="s.id">
                {{ s.name }}
              </option>
            </select>
          </div>

          <div>
            <label class="block text-sm text-n-slate-11 mb-1">
              {{ $t('funnels.create_card_modal.value_label') }}
            </label>
            <input
              v-model="form.value"
              type="number"
              min="0"
              step="0.01"
              placeholder="0"
              class="w-full px-3 py-2 text-sm border border-n-weak rounded-lg bg-n-solid-1
                     text-n-slate-12 placeholder-n-slate-9 focus:outline-none focus:border-woot-400"
            />
          </div>
        </div>

        <div class="flex gap-3 mt-6">
          <button
            type="button"
            class="flex-1 px-4 py-2 text-sm border border-n-weak rounded-lg
                   text-n-slate-11 hover:bg-n-alpha-1 transition-colors"
            @click="$emit('close')"
          >
            {{ $t('funnels.cancel') }}
          </button>
          <button
            type="submit"
            :disabled="submitting || !form.title.trim()"
            class="flex-1 px-4 py-2 text-sm font-medium text-white bg-woot-500
                   rounded-lg hover:bg-woot-600 disabled:opacity-50 transition-colors
                   flex items-center justify-center gap-2"
          >
            <i v-if="submitting" class="i-lucide-loader-circle animate-spin size-4" aria-hidden="true" />
            {{ submitting
                ? $t('funnels.create_card_modal.submitting')
                : $t('funnels.create_card_modal.submit') }}
          </button>
        </div>
      </form>
    </div>
  </div>
</template>

<script>
import axios             from 'axios';
import { mapActions }    from 'vuex';
import { useFunnelToast } from '../composables/useFunnelToast';

export default {
  name: 'CreateCardModal',
  props: {
    funnel:           { type: Object,           required: true },
    stages:           { type: Array,            default: () => [] },
    initialStageId:   { type: Number,           default: null },
    /** Quando passado, a conversa é vinculada ao card automaticamente após criação */
    conversationId:   { type: [Number, String], default: null },
  },
  emits: ['close', 'created'],

  setup() {
    const { success, error } = useFunnelToast();
    return { toastSuccess: success, toastError: error };
  },

  data() {
    return {
      submitting: false,
      form: {
        title:    '',
        stage_id: this.initialStageId,
        value:    '',
      },
    };
  },

  computed: {
    intermediateStages() {
      return this.stages.filter(s => s.stage_type === 'intermediate');
    },
  },

  mounted() {
    if (!this.form.stage_id && this.intermediateStages.length > 0) {
      this.form.stage_id = this.intermediateStages[0].id;
    }
    this.$nextTick(() => this.$refs.titleInput?.focus());
  },

  methods: {
    ...mapActions('funnels', ['createCard']),

    async submit() {
      if (!this.form.title.trim()) return;
      this.submitting = true;
      try {
        const card = await this.createCard({
          funnelId: this.funnel.id,
          cardData: {
            title:    this.form.title.trim(),
            stage_id: this.form.stage_id,
            value:    this.form.value || 0,
          },
        });

        // Auto-vincula conversa quando chamado do contexto de uma conversa
        if (this.conversationId && card?.id) {
          const accountId = this.$store.getters['getCurrentAccountId'];
          try {
            await axios.post(
              `/api/v1/accounts/${accountId}/funnels/${this.funnel.id}/cards/${card.id}/link_conversation`,
              { conversation_id: Number(this.conversationId) }
            );
          } catch {
            // Card criado com sucesso; falha no link é secundária
          }
        }

        this.toastSuccess(this.$t('funnels.create_card_modal.success'));
        this.$emit('created');
      } catch (e) {
        this.toastError(this.$t('funnels.create_card_modal.error'));
      } finally {
        this.submitting = false;
      }
    },
  },
};
</script>
