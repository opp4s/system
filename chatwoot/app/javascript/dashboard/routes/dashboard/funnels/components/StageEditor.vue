<template>
  <div class="flex flex-col gap-3">

    <!-- ── Lista de etapas (drag-to-reorder) ─────────────────────────────── -->
    <p class="text-xs text-n-slate-8 flex items-center gap-1">
      <i class="i-lucide-grip-vertical size-3.5" aria-hidden="true" />
      {{ $t('funnels.settings.stages.drag_hint') }}
    </p>

    <draggable
      v-model="localStages"
      item-key="id"
      handle=".drag-handle"
      animation="150"
      @end="onReorder"
    >
      <template #item="{ element: stage }">
        <div
          class="border border-n-weak rounded-xl mb-2 bg-n-solid-1 overflow-hidden
                 transition-shadow hover:shadow-sm"
        >
          <!-- Stage row -->
          <div class="flex items-center gap-2 px-3 py-2.5">
            <!-- Drag handle -->
            <i
              class="drag-handle i-lucide-grip-vertical size-4 text-n-slate-7
                     cursor-grab active:cursor-grabbing flex-shrink-0"
              aria-hidden="true"
            />

            <!-- Color dot / picker trigger -->
            <button
              class="size-4 rounded-full border-2 border-white shadow-sm flex-shrink-0
                     ring-1 ring-n-weak hover:ring-woot-400 transition-all"
              :style="{ backgroundColor: stage.color || '#6B7280' }"
              :aria-label="`Cor da etapa ${stage.name}`"
              @click="toggleColorPicker(stage.id)"
            />

            <!-- Name (inline edit) -->
            <input
              v-model="stage._editName"
              class="flex-1 text-sm bg-transparent outline-none text-n-slate-12
                     placeholder:text-n-slate-7 min-w-0"
              :placeholder="$t('funnels.settings.stages.name_placeholder')"
              @blur="saveStage(stage)"
              @keyup.enter="$event.target.blur()"
            />

            <!-- Type select -->
            <select
              v-model="stage.stage_type"
              class="text-xs border border-n-weak rounded-md px-1.5 py-1 bg-n-solid-1
                     text-n-slate-11 focus:outline-none focus:border-woot-400
                     transition-colors flex-shrink-0"
              @change="saveStage(stage)"
            >
              <option value="intermediate">{{ $t('funnels.settings.stages.type_intermediate') }}</option>
              <option value="won">{{ $t('funnels.settings.stages.type_won') }}</option>
              <option value="lost">{{ $t('funnels.settings.stages.type_lost') }}</option>
            </select>

            <!-- Expand loss reasons (lost type only) -->
            <button
              v-if="stage.stage_type === 'lost'"
              class="text-n-slate-8 hover:text-amber-600 transition-colors flex-shrink-0"
              :aria-label="`Motivos de perda de ${stage.name}`"
              @click="toggleExpand(stage.id)"
            >
              <i
                :class="expandedId === stage.id ? 'i-lucide-chevron-up' : 'i-lucide-chevron-down'"
                class="size-4"
                aria-hidden="true"
              />
            </button>

            <!-- Save indicator -->
            <i
              v-if="savingId === stage.id"
              class="i-lucide-loader-circle animate-spin size-3.5 text-n-slate-8 flex-shrink-0"
              aria-hidden="true"
            />
            <i
              v-else-if="savedId === stage.id"
              class="i-lucide-check size-3.5 text-green-500 flex-shrink-0"
              aria-hidden="true"
            />

            <!-- Delete -->
            <button
              class="text-n-slate-7 hover:text-red-500 transition-colors flex-shrink-0"
              :aria-label="`${$t('funnels.settings.stages.delete_btn')} ${stage.name}`"
              :disabled="deletingId === stage.id"
              @click="deleteStage(stage)"
            >
              <i
                v-if="deletingId === stage.id"
                class="i-lucide-loader-circle animate-spin size-4"
                aria-hidden="true"
              />
              <i v-else class="i-lucide-trash-2 size-4" aria-hidden="true" />
            </button>
          </div>

          <!-- Color picker panel -->
          <div
            v-if="colorPickerId === stage.id"
            class="px-3 pb-3 border-t border-n-weak pt-2 bg-n-alpha-1/50"
          >
            <div class="flex flex-wrap gap-1.5">
              <button
                v-for="color in PRESET_COLORS"
                :key="color"
                class="size-5 rounded-full transition-transform hover:scale-110 border-2"
                :style="{ backgroundColor: color }"
                :class="stage.color === color
                  ? 'border-n-slate-12 scale-110'
                  : 'border-transparent'"
                :aria-label="color"
                @click="setStageColor(stage, color)"
              />
            </div>
          </div>

          <!-- Loss reasons panel (lost stages only) -->
          <Transition
            enter-active-class="transition-all duration-200 ease-out"
            enter-from-class="opacity-0 max-h-0"
            enter-to-class="opacity-100 max-h-72"
            leave-active-class="transition-all duration-150 ease-in"
            leave-from-class="opacity-100 max-h-72"
            leave-to-class="opacity-0 max-h-0"
          >
            <div
              v-if="stage.stage_type === 'lost' && expandedId === stage.id"
              class="px-3 pb-3 border-t border-n-weak pt-3"
            >
              <label class="block text-xs font-medium text-n-slate-9 mb-1">
                {{ $t('funnels.settings.stages.loss_reasons_title') }}
              </label>
              <p class="text-xs text-n-slate-8 mb-2">
                {{ $t('funnels.settings.stages.loss_reasons_hint') }}
              </p>
              <textarea
                v-model="stage._lossReasonsText"
                rows="5"
                class="w-full text-sm border border-n-weak rounded-lg px-3 py-2
                       bg-n-solid-1 text-n-slate-12 focus:outline-none focus:border-woot-400
                       resize-y placeholder:text-n-slate-7"
                :placeholder="$t('funnels.settings.stages.loss_reasons_placeholder')"
              />
              <button
                class="mt-2 px-3 py-1.5 text-xs font-medium bg-woot-500 hover:bg-woot-600
                       text-white rounded-lg transition-colors flex items-center gap-1.5
                       disabled:opacity-50"
                :disabled="savingLossId === stage.id"
                @click="saveLossReasons(stage)"
              >
                <i
                  v-if="savingLossId === stage.id"
                  class="i-lucide-loader-circle animate-spin size-3"
                  aria-hidden="true"
                />
                {{ $t('funnels.settings.stages.loss_reasons_save') }}
              </button>
            </div>
          </Transition>
        </div>
      </template>
    </draggable>

    <!-- ── Adicionar etapa ────────────────────────────────────────────────── -->
    <div class="border-2 border-dashed border-n-weak rounded-xl overflow-hidden
                hover:border-woot-300 transition-colors">
      <div class="p-3 flex items-center gap-2">
        <i class="i-lucide-plus size-4 text-n-slate-8 flex-shrink-0" aria-hidden="true" />

        <!-- Color pick for new stage -->
        <button
          class="size-4 rounded-full border-2 border-white shadow-sm flex-shrink-0
                 ring-1 ring-n-weak hover:ring-woot-400 transition-all"
          :style="{ backgroundColor: newStageColor }"
          aria-label="Cor da nova etapa"
          @click="colorPickerId = colorPickerId === '__new__' ? null : '__new__'"
        />

        <input
          v-model="newStageName"
          type="text"
          class="flex-1 text-sm bg-transparent outline-none text-n-slate-12
                 placeholder:text-n-slate-7"
          :placeholder="$t('funnels.settings.stages.name_placeholder')"
          @keyup.enter="addStage"
        />
        <select
          v-model="newStageType"
          class="text-xs border border-n-weak rounded-md px-1.5 py-1 bg-n-solid-1
                 text-n-slate-11 focus:outline-none flex-shrink-0"
        >
          <option value="intermediate">{{ $t('funnels.settings.stages.type_intermediate') }}</option>
          <option value="won">{{ $t('funnels.settings.stages.type_won') }}</option>
          <option value="lost">{{ $t('funnels.settings.stages.type_lost') }}</option>
        </select>
        <button
          :disabled="!newStageName.trim() || addingStage"
          class="px-3 py-1.5 text-xs font-medium bg-woot-500 hover:bg-woot-600 text-white
                 rounded-lg transition-colors disabled:opacity-40 flex items-center gap-1 flex-shrink-0"
          @click="addStage"
        >
          <i
            v-if="addingStage"
            class="i-lucide-loader-circle animate-spin size-3"
            aria-hidden="true"
          />
          <span>{{ addingStage
            ? $t('funnels.settings.stages.adding')
            : $t('funnels.settings.stages.add_btn')
          }}</span>
        </button>
      </div>

      <!-- Color picker for new stage -->
      <div v-if="colorPickerId === '__new__'" class="px-3 pb-3 border-t border-n-weak pt-2 bg-n-alpha-1/50">
        <div class="flex flex-wrap gap-1.5">
          <button
            v-for="color in PRESET_COLORS"
            :key="color"
            class="size-5 rounded-full transition-transform hover:scale-110 border-2"
            :style="{ backgroundColor: color }"
            :class="newStageColor === color ? 'border-n-slate-12 scale-110' : 'border-transparent'"
            :aria-label="color"
            @click="newStageColor = color; colorPickerId = null"
          />
        </div>
      </div>
    </div>

  </div>
</template>

<script>
import axios     from 'axios';
import draggable from 'vuedraggable';
import { useFunnelToast } from '../composables/useFunnelToast';

const PRESET_COLORS = [
  '#6B7280', '#EF4444', '#F97316', '#EAB308', '#22C55E',
  '#14B8A6', '#3B82F6', '#8B5CF6', '#EC4899', '#F43F5E',
  '#0EA5E9', '#10B981', '#F59E0B', '#6366F1', '#D946EF',
];

function lossReasonsToText(reasons) {
  if (!Array.isArray(reasons)) return '';
  return reasons.join('\n');
}

function textToLossReasons(text) {
  return (text || '').split('\n').map(s => s.trim()).filter(Boolean);
}

export default {
  name: 'StageEditor',
  components: { draggable },

  setup() {
    const { success, error } = useFunnelToast();
    return { toastSuccess: success, toastError: error };
  },

  props: {
    funnel:   { type: Object, required: true },
    funnelId: { type: [Number, String], required: true },
  },

  emits: ['updated'],

  data() {
    return {
      PRESET_COLORS,
      localStages:    [],
      newStageName:   '',
      newStageType:   'intermediate',
      newStageColor:  '#6B7280',
      addingStage:    false,
      savingId:       null,
      savedId:        null,
      deletingId:     null,
      colorPickerId:  null,
      expandedId:     null,
      savingLossId:   null,
      _savedTimer:    null,
    };
  },

  watch: {
    funnel: {
      immediate: true,
      handler(f) {
        this.localStages = (f.stages || []).map(s => ({
          ...s,
          _editName:        s.name,
          _lossReasonsText: lossReasonsToText(s.loss_reasons),
        }));
      },
    },
  },

  beforeUnmount() {
    clearTimeout(this._savedTimer);
  },

  methods: {
    // ── Reorder ───────────────────────────────────────────────────────────────

    async onReorder() {
      const accountId = this.$store.getters['getCurrentAccountId'];
      const stage_ids = this.localStages.map(s => s.id);
      try {
        await axios.post(
          `/api/v1/accounts/${accountId}/funnels/${this.funnelId}/stages/reorder`,
          { stage_ids }
        );
        this.$emit('updated');
      } catch {
        this.toastError(this.$t('funnels.settings.stages.reorder_error'));
      }
    },

    // ── Save stage ────────────────────────────────────────────────────────────

    async saveStage(stage) {
      if (stage._editName === stage.name && !this._typeChanged) return;

      this.savingId = stage.id;
      clearTimeout(this._savedTimer);
      const accountId = this.$store.getters['getCurrentAccountId'];
      try {
        const { data } = await axios.patch(
          `/api/v1/accounts/${accountId}/funnels/${this.funnelId}/stages/${stage.id}`,
          {
            stage: {
              name:       stage._editName,
              stage_type: stage.stage_type,
              color:      stage.color,
            },
          }
        );
        // Update local record
        const idx = this.localStages.findIndex(s => s.id === stage.id);
        if (idx !== -1) {
          this.localStages[idx] = {
            ...this.localStages[idx],
            ...data,
            _editName:        data.name,
            _lossReasonsText: lossReasonsToText(data.loss_reasons),
          };
        }
        this.savedId = stage.id;
        this._savedTimer = setTimeout(() => { this.savedId = null; }, 2000);
        this.$emit('updated');
      } catch {
        this.toastError(this.$t('funnels.settings.stages.save_error'));
      } finally {
        this.savingId = null;
      }
    },

    // ── Color ─────────────────────────────────────────────────────────────────

    toggleColorPicker(id) {
      this.colorPickerId = this.colorPickerId === id ? null : id;
    },

    async setStageColor(stage, color) {
      stage.color     = color;
      this.colorPickerId = null;
      await this.saveStage(stage);
    },

    // ── Delete ────────────────────────────────────────────────────────────────

    async deleteStage(stage) {
      const confirmed = window.confirm(
        this.$t('funnels.settings.stages.delete_confirm', { name: stage._editName || stage.name })
      );
      if (!confirmed) return;

      this.deletingId = stage.id;
      const accountId = this.$store.getters['getCurrentAccountId'];
      try {
        await axios.delete(
          `/api/v1/accounts/${accountId}/funnels/${this.funnelId}/stages/${stage.id}`
        );
        this.localStages = this.localStages.filter(s => s.id !== stage.id);
        this.toastSuccess(this.$t('funnels.settings.stages.delete_success'));
        this.$emit('updated');
      } catch {
        this.toastError(this.$t('funnels.settings.stages.delete_error'));
      } finally {
        this.deletingId = null;
      }
    },

    // ── Add ───────────────────────────────────────────────────────────────────

    async addStage() {
      const name = this.newStageName.trim();
      if (!name || this.addingStage) return;

      this.addingStage = true;
      const accountId = this.$store.getters['getCurrentAccountId'];
      try {
        const { data } = await axios.post(
          `/api/v1/accounts/${accountId}/funnels/${this.funnelId}/stages`,
          {
            stage: {
              name,
              color:      this.newStageColor,
              stage_type: this.newStageType,
            },
          }
        );
        this.localStages.push({
          ...data,
          _editName:        data.name,
          _lossReasonsText: lossReasonsToText(data.loss_reasons),
        });
        this.newStageName  = '';
        this.newStageType  = 'intermediate';
        this.newStageColor = '#6B7280';
        this.toastSuccess(this.$t('funnels.settings.stages.save_success'));
        this.$emit('updated');
      } catch {
        this.toastError(this.$t('funnels.settings.stages.save_error'));
      } finally {
        this.addingStage = false;
      }
    },

    // ── Loss reasons ──────────────────────────────────────────────────────────

    toggleExpand(id) {
      this.expandedId = this.expandedId === id ? null : id;
    },

    async saveLossReasons(stage) {
      this.savingLossId = stage.id;
      const reasons    = textToLossReasons(stage._lossReasonsText);
      const accountId  = this.$store.getters['getCurrentAccountId'];
      try {
        await axios.patch(
          `/api/v1/accounts/${accountId}/funnels/${this.funnelId}/stages/${stage.id}`,
          { stage: { loss_reasons: reasons } }
        );
        // sync local
        const idx = this.localStages.findIndex(s => s.id === stage.id);
        if (idx !== -1) this.localStages[idx].loss_reasons = reasons;
        this.toastSuccess(this.$t('funnels.settings.stages.loss_reasons_success'));
        this.$emit('updated');
      } catch {
        this.toastError(this.$t('funnels.settings.stages.loss_reasons_error'));
      } finally {
        this.savingLossId = null;
      }
    },
  },
};
</script>
