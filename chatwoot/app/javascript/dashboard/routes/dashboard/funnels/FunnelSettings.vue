<template>
  <div class="flex h-full overflow-hidden bg-n-background">

    <!-- ══ Sidebar: lista de funis ══════════════════════════════════════════ -->
    <aside class="w-72 flex-shrink-0 border-r border-n-weak bg-n-solid-1 flex flex-col">

      <!-- Header -->
      <div class="px-4 py-3 border-b border-n-weak flex items-center gap-2">
        <button
          class="text-n-slate-9 hover:text-n-slate-12 transition-colors flex-shrink-0"
          :aria-label="$t('funnels.settings.back_to_board')"
          @click="$router.push({ name: 'funnels_index' })"
        >
          <i class="i-lucide-arrow-left size-4" aria-hidden="true" />
        </button>
        <h2 class="flex-1 text-sm font-semibold text-n-slate-12 truncate">
          {{ $t('funnels.settings.page_title') }}
        </h2>
        <button
          class="text-n-slate-8 hover:text-woot-600 hover:bg-woot-50 rounded-md p-1
                 transition-colors flex-shrink-0"
          :aria-label="$t('funnels.new_funnel')"
          @click="showCreateModal = true"
        >
          <i class="i-lucide-plus size-4" aria-hidden="true" />
        </button>
      </div>

      <!-- Skeleton loading -->
      <div v-if="isLoading" class="flex-1 py-2">
        <div v-for="i in 4" :key="i" class="flex items-center gap-2 px-4 py-2.5">
          <div class="size-2.5 rounded-full bg-n-alpha-3 animate-pulse flex-shrink-0" />
          <div
            class="h-3 rounded bg-n-alpha-3 animate-pulse"
            :style="{ width: [70, 90, 60, 80][i % 4] + 'px' }"
          />
        </div>
      </div>

      <!-- Draggable funnel list -->
      <draggable
        v-else
        v-model="localFunnels"
        item-key="id"
        handle=".drag-handle"
        animation="150"
        class="flex-1 overflow-y-auto py-1"
        @end="onReorderFunnels"
      >
        <template #item="{ element: f }">
          <div
            class="flex items-center gap-2 px-3 py-2.5 cursor-pointer transition-colors group"
            :class="selectedFunnelId === f.id
              ? 'bg-woot-50/50 text-n-slate-12 dark:bg-woot-900/10'
              : 'text-n-slate-11 hover:bg-n-alpha-1'"
            @click="selectFunnel(f.id)"
          >
            <i
              class="drag-handle i-lucide-grip-vertical size-3.5 text-n-slate-6
                     cursor-grab active:cursor-grabbing flex-shrink-0
                     opacity-0 group-hover:opacity-100 transition-opacity"
              aria-hidden="true"
            />
            <span
              class="size-2.5 rounded-full flex-shrink-0 ring-1 ring-white/50"
              :style="{ backgroundColor: f.color || '#6B7280' }"
              aria-hidden="true"
            />
            <span class="flex-1 text-sm truncate">{{ f.name }}</span>
            <span v-if="f.is_default" class="size-1.5 rounded-full bg-woot-500 flex-shrink-0" aria-label="padrão" />
          </div>
        </template>
      </draggable>

    </aside>

    <!-- ══ Editor principal ══════════════════════════════════════════════════ -->
    <main class="flex-1 overflow-y-auto">

      <!-- Empty state: nenhum funil selecionado -->
      <div
        v-if="!selectedFunnel"
        class="flex flex-col items-center justify-center h-full gap-3 text-center"
      >
        <i class="i-lucide-settings size-10 text-n-slate-8" aria-hidden="true" />
        <p class="text-sm text-n-slate-9">{{ $t('funnels.settings.select_hint') }}</p>
      </div>

      <!-- Form de edição -->
      <div v-else class="max-w-2xl mx-auto p-6 flex flex-col gap-6">

        <!-- Tabs -->
        <div class="flex border-b border-n-weak gap-1">
          <button
            v-for="tab in editorTabs"
            :key="tab.key"
            class="px-4 py-2.5 text-sm font-medium transition-colors border-b-2 -mb-px"
            :class="activeTab === tab.key
              ? 'border-woot-500 text-woot-600'
              : 'border-transparent text-n-slate-9 hover:text-n-slate-12'"
            @click="activeTab = tab.key"
          >
            {{ $t(tab.label) }}
          </button>
        </div>

        <!-- ── Tab: Funil ─────────────────────────────────────────────────── -->
        <template v-if="activeTab === 'funnel'">

          <!-- Nome -->
          <div>
            <label class="block text-xs font-medium text-n-slate-9 uppercase tracking-wide mb-1.5">
              {{ $t('funnels.settings.funnel_form.name_label') }}
            </label>
            <input
              v-model="form.name"
              type="text"
              class="w-full px-3 py-2 text-sm border border-n-weak rounded-lg bg-n-solid-1
                     text-n-slate-12 focus:outline-none focus:border-woot-400 transition-colors"
              :placeholder="$t('funnels.settings.funnel_form.name_placeholder')"
            />
          </div>

          <!-- Descrição -->
          <div>
            <label class="block text-xs font-medium text-n-slate-9 uppercase tracking-wide mb-1.5">
              {{ $t('funnels.settings.funnel_form.description_label') }}
            </label>
            <textarea
              v-model="form.description"
              rows="3"
              class="w-full px-3 py-2 text-sm border border-n-weak rounded-lg bg-n-solid-1
                     text-n-slate-12 focus:outline-none focus:border-woot-400 resize-y
                     transition-colors placeholder:text-n-slate-7"
              :placeholder="$t('funnels.settings.funnel_form.description_placeholder')"
            />
          </div>

          <!-- Cor -->
          <div>
            <label class="block text-xs font-medium text-n-slate-9 uppercase tracking-wide mb-2">
              {{ $t('funnels.settings.funnel_form.color_label') }}
            </label>
            <div class="flex flex-wrap gap-2 items-center">
              <button
                v-for="color in PRESET_COLORS"
                :key="color"
                class="size-6 rounded-full border-2 transition-transform hover:scale-110"
                :style="{ backgroundColor: color }"
                :class="form.color === color
                  ? 'border-n-slate-12 scale-110 shadow-sm'
                  : 'border-transparent'"
                :aria-label="color"
                @click="form.color = color"
              />
              <!-- Current color preview + hex input -->
              <div class="flex items-center gap-2 ml-2">
                <span
                  class="size-6 rounded-full border-2 border-n-weak shadow-sm"
                  :style="{ backgroundColor: form.color }"
                />
                <input
                  v-model="form.color"
                  type="text"
                  class="w-24 px-2 py-1 text-xs border border-n-weak rounded-md bg-n-solid-1
                         text-n-slate-12 focus:outline-none focus:border-woot-400"
                  placeholder="#6B7280"
                />
              </div>
            </div>
          </div>

          <!-- Funil padrão -->
          <div class="flex items-start gap-3">
            <div
              class="relative inline-flex mt-0.5"
              @click="form.is_default = !form.is_default"
            >
              <input
                v-model="form.is_default"
                type="checkbox"
                class="sr-only peer"
              />
              <div
                class="w-9 h-5 rounded-full transition-colors cursor-pointer border border-n-weak"
                :class="form.is_default ? 'bg-woot-500 border-woot-500' : 'bg-n-alpha-2'"
              >
                <div
                  class="size-3.5 rounded-full bg-white shadow-sm transition-transform m-[3px]"
                  :class="form.is_default ? 'translate-x-4' : 'translate-x-0'"
                />
              </div>
            </div>
            <div>
              <p class="text-sm text-n-slate-12 font-medium leading-tight">
                {{ $t('funnels.settings.funnel_form.default_label') }}
              </p>
              <p class="text-xs text-n-slate-8 mt-0.5">
                {{ $t('funnels.settings.funnel_form.default_hint') }}
              </p>
            </div>
          </div>

          <!-- Actions -->
          <div class="flex items-center justify-between pt-2 border-t border-n-weak">
            <button
              class="px-4 py-2 text-sm font-medium text-red-500 hover:text-red-700
                     hover:bg-red-50 rounded-lg transition-colors"
              :disabled="deletingFunnel"
              @click="deleteFunnel"
            >
              <i
                v-if="deletingFunnel"
                class="i-lucide-loader-circle animate-spin size-4 inline mr-1.5"
                aria-hidden="true"
              />
              {{ $t('funnels.settings.funnel_form.delete_btn') }}
            </button>

            <button
              :disabled="!form.name.trim() || savingFunnel"
              class="px-5 py-2 text-sm font-medium text-white bg-woot-500
                     hover:bg-woot-600 rounded-lg disabled:opacity-50 transition-colors
                     flex items-center gap-2"
              @click="saveFunnel"
            >
              <i
                v-if="savingFunnel"
                class="i-lucide-loader-circle animate-spin size-4"
                aria-hidden="true"
              />
              {{ savingFunnel
                ? $t('funnels.settings.funnel_form.saving')
                : $t('funnels.settings.funnel_form.save_btn')
              }}
            </button>
          </div>

        </template>

        <!-- ── Tab: Etapas ────────────────────────────────────────────────── -->
        <template v-if="activeTab === 'stages'">
          <StageEditor
            :funnel="selectedFunnel"
            :funnel-id="selectedFunnel.id"
            @updated="onStagesUpdated"
          />
        </template>

      </div>
    </main>

    <!-- ── Modal criar funil (reutilizado do Index.vue) ───────────────────── -->
    <div
      v-if="showCreateModal"
      class="fixed inset-0 z-50 flex items-center justify-center bg-black/40"
      role="dialog"
      :aria-modal="true"
      :aria-label="$t('funnels.create_funnel_modal.title')"
      @click.self="showCreateModal = false"
    >
      <div class="bg-n-solid-1 rounded-xl shadow-xl w-full max-w-sm mx-4 p-6">
        <h2 class="text-base font-semibold text-n-slate-12 mb-4">
          {{ $t('funnels.create_funnel_modal.title') }}
        </h2>
        <input
          ref="newFunnelInput"
          v-model="newFunnelName"
          type="text"
          class="w-full px-3 py-2 text-sm border border-n-weak rounded-lg bg-n-solid-1
                 text-n-slate-12 placeholder:text-n-slate-9 focus:outline-none
                 focus:border-woot-400 mb-4"
          :placeholder="$t('funnels.create_funnel_modal.name_placeholder')"
          @keyup.enter="submitCreate"
          @keyup.esc="showCreateModal = false"
        />
        <div class="flex gap-3">
          <button
            class="flex-1 px-4 py-2 text-sm border border-n-weak rounded-lg
                   text-n-slate-11 hover:bg-n-alpha-1 transition-colors"
            @click="showCreateModal = false"
          >
            {{ $t('funnels.cancel') }}
          </button>
          <button
            :disabled="!newFunnelName.trim() || creatingFunnel"
            class="flex-1 px-4 py-2 text-sm font-medium text-white bg-woot-500
                   rounded-lg hover:bg-woot-600 disabled:opacity-50 transition-colors
                   flex items-center justify-center gap-2"
            @click="submitCreate"
          >
            <i v-if="creatingFunnel" class="i-lucide-loader-circle animate-spin size-4" aria-hidden="true" />
            {{ creatingFunnel ? $t('funnels.creating') : $t('funnels.create') }}
          </button>
        </div>
      </div>
    </div>

    <FunnelToast />
  </div>
</template>

<script>
import axios          from 'axios';
import draggable      from 'vuedraggable';
import { mapGetters } from 'vuex';
import StageEditor    from './components/StageEditor.vue';
import FunnelToast    from './components/FunnelToast.vue';
import { useFunnelToast } from './composables/useFunnelToast';

const PRESET_COLORS = [
  '#6B7280', '#EF4444', '#F97316', '#EAB308', '#22C55E',
  '#14B8A6', '#3B82F6', '#8B5CF6', '#EC4899', '#F43F5E',
  '#0EA5E9', '#10B981', '#F59E0B', '#6366F1', '#D946EF',
];

export default {
  name: 'FunnelSettings',
  components: { draggable, StageEditor, FunnelToast },

  setup() {
    const { success, error } = useFunnelToast();
    return { toastSuccess: success, toastError: error };
  },

  data() {
    return {
      PRESET_COLORS,
      localFunnels:    [],
      selectedFunnelId: null,
      activeTab:       'funnel',
      editorTabs: [
        { key: 'funnel', label: 'funnels.settings.tab_funnel' },
        { key: 'stages', label: 'funnels.settings.tab_stages' },
      ],
      form: {
        name:        '',
        description: '',
        color:       '#6B7280',
        is_default:  false,
      },
      savingFunnel:    false,
      deletingFunnel:  false,
      showCreateModal: false,
      newFunnelName:   '',
      creatingFunnel:  false,
    };
  },

  computed: {
    ...mapGetters('funnels', ['allFunnels', 'isLoading']),

    selectedFunnel() {
      return this.localFunnels.find(f => f.id === this.selectedFunnelId) || null;
    },
  },

  watch: {
    allFunnels: {
      immediate: true,
      handler(list) {
        this.localFunnels = [...list];
        // Auto-select from route query or first funnel
        const qId = Number(this.$route.query.funnel);
        if (qId && list.find(f => f.id === qId)) {
          this.selectFunnel(qId);
        } else if (!this.selectedFunnelId && list.length) {
          this.selectFunnel(list[0].id);
        }
      },
    },

    selectedFunnel(f) {
      if (!f) return;
      this.form = {
        name:        f.name        || '',
        description: f.description || '',
        color:       f.color       || '#6B7280',
        is_default:  f.is_default  || false,
      };
    },
  },

  created() {
    if (!this.allFunnels.length) {
      this.$store.dispatch('funnels/fetchFunnels');
    }
  },

  methods: {
    selectFunnel(id) {
      this.selectedFunnelId = id;
      this.activeTab = 'funnel';
    },

    // ── Reorder funnels ───────────────────────────────────────────────────────

    async onReorderFunnels() {
      const accountId  = this.$store.getters['getCurrentAccountId'];
      const positions  = this.localFunnels.map((f, i) => ({ id: f.id, position: i + 1 }));
      try {
        await axios.post(
          `/api/v1/accounts/${accountId}/funnels/reorder`,
          { funnels: positions }
        );
        await this.$store.dispatch('funnels/fetchFunnels');
      } catch {
        // Silently revert — re-sync from store
        this.localFunnels = [...this.allFunnels];
      }
    },

    // ── Save funnel ───────────────────────────────────────────────────────────

    async saveFunnel() {
      if (!this.form.name.trim() || this.savingFunnel) return;
      this.savingFunnel = true;
      const accountId  = this.$store.getters['getCurrentAccountId'];
      try {
        await axios.patch(
          `/api/v1/accounts/${accountId}/funnels/${this.selectedFunnelId}`,
          { funnel: this.form }
        );
        await this.$store.dispatch('funnels/fetchFunnels');
        this.toastSuccess(this.$t('funnels.settings.funnel_form.save_success'));
      } catch {
        this.toastError(this.$t('funnels.settings.funnel_form.save_error'));
      } finally {
        this.savingFunnel = false;
      }
    },

    // ── Delete funnel ─────────────────────────────────────────────────────────

    async deleteFunnel() {
      const confirmed = window.confirm(this.$t('funnels.settings.funnel_form.delete_confirm'));
      if (!confirmed) return;

      this.deletingFunnel = true;
      const accountId = this.$store.getters['getCurrentAccountId'];
      try {
        await axios.delete(`/api/v1/accounts/${accountId}/funnels/${this.selectedFunnelId}`);
        await this.$store.dispatch('funnels/fetchFunnels');
        this.selectedFunnelId = null;
        this.toastSuccess(this.$t('funnels.settings.funnel_form.delete_success'));
      } catch {
        this.toastError(this.$t('funnels.settings.funnel_form.delete_error'));
      } finally {
        this.deletingFunnel = false;
      }
    },

    // ── Create funnel ─────────────────────────────────────────────────────────

    async submitCreate() {
      const name = this.newFunnelName.trim();
      if (!name || this.creatingFunnel) return;
      this.creatingFunnel = true;
      const accountId = this.$store.getters['getCurrentAccountId'];
      try {
        const { data } = await axios.post(
          `/api/v1/accounts/${accountId}/funnels`,
          { funnel: { name } }
        );
        await this.$store.dispatch('funnels/fetchFunnels');
        this.showCreateModal = false;
        this.newFunnelName   = '';
        this.toastSuccess(this.$t('funnels.create_funnel_modal.success'));
        this.selectFunnel(data.id);
      } catch {
        this.toastError(this.$t('funnels.create_funnel_modal.error'));
      } finally {
        this.creatingFunnel = false;
      }
    },

    // ── Stages updated callback ───────────────────────────────────────────────

    async onStagesUpdated() {
      // Re-fetch so selectedFunnel gets fresh stages data for StageEditor watch
      await this.$store.dispatch('funnels/fetchFunnels');
    },
  },
};
</script>
