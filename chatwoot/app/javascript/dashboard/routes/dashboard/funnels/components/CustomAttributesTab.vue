<template>
  <div class="flex flex-col gap-4">

    <!-- Skeleton de carregamento -->
    <template v-if="loading">
      <div v-for="i in 3" :key="i" class="flex flex-col gap-1.5">
        <div class="h-2.5 rounded bg-n-alpha-2 animate-pulse" style="width: 40%" />
        <div class="h-9 rounded-lg bg-n-alpha-1 animate-pulse" />
      </div>
    </template>

    <!-- Sem campos configurados -->
    <div v-else-if="fields.length === 0" class="py-6 text-center">
      <i class="i-lucide-list-plus size-8 text-n-slate-8 mb-2 mx-auto block" aria-hidden="true" />
      <p class="text-sm text-n-slate-9">{{ $t('funnels.custom_fields.no_fields') }}</p>
      <p class="text-xs text-n-slate-8 mt-1">{{ $t('funnels.custom_fields.empty_hint') }}</p>
    </div>

    <!-- Lista de campos -->
    <template v-else>
      <div
        v-for="field in fields"
        :key="field.attribute_id"
        class="flex flex-col gap-1"
      >
        <label
          :for="`cf-${field.attribute_id}`"
          class="text-xs font-medium text-n-slate-9 uppercase tracking-wide"
        >
          {{ field.attribute_name }}
        </label>

        <!-- checkbox -->
        <label
          v-if="field.attribute_type === 'checkbox'"
          class="flex items-center gap-2 cursor-pointer"
        >
          <input
            :id="`cf-${field.attribute_id}`"
            v-model="values[field.attribute_id]"
            type="checkbox"
            class="size-4 rounded border-n-weak text-woot-500 focus:ring-woot-400"
            @change="scheduleSave"
          />
          <span class="text-sm text-n-slate-11">{{ field.attribute_name }}</span>
        </label>

        <!-- date -->
        <input
          v-else-if="field.attribute_type === 'date'"
          :id="`cf-${field.attribute_id}`"
          v-model="values[field.attribute_id]"
          type="date"
          class="w-full px-3 py-2 text-sm border border-n-weak rounded-lg bg-n-solid-1
                 text-n-slate-12 focus:outline-none focus:border-woot-400"
          @change="scheduleSave"
        />

        <!-- list -->
        <select
          v-else-if="field.attribute_type === 'list'"
          :id="`cf-${field.attribute_id}`"
          v-model="values[field.attribute_id]"
          class="w-full px-3 py-2 text-sm border border-n-weak rounded-lg bg-n-solid-1
                 text-n-slate-12 focus:outline-none focus:border-woot-400"
          @change="scheduleSave"
        >
          <option value="">—</option>
          <option
            v-for="opt in (field.values || [])"
            :key="opt"
            :value="opt"
          >{{ opt }}</option>
        </select>

        <!-- number -->
        <input
          v-else-if="field.attribute_type === 'number'"
          :id="`cf-${field.attribute_id}`"
          v-model.number="values[field.attribute_id]"
          type="number"
          class="w-full px-3 py-2 text-sm border border-n-weak rounded-lg bg-n-solid-1
                 text-n-slate-12 focus:outline-none focus:border-woot-400"
          @input="scheduleSave"
        />

        <!-- text (default) -->
        <input
          v-else
          :id="`cf-${field.attribute_id}`"
          v-model="values[field.attribute_id]"
          type="text"
          class="w-full px-3 py-2 text-sm border border-n-weak rounded-lg bg-n-solid-1
                 text-n-slate-12 focus:outline-none focus:border-woot-400"
          @input="scheduleSave"
        />
      </div>

      <!-- Indicador de estado do save (inline, não intrusivo) -->
      <Transition
        enter-active-class="transition-opacity duration-200"
        leave-active-class="transition-opacity duration-200"
        enter-from-class="opacity-0"
        leave-to-class="opacity-0"
      >
        <div
          v-if="saveState !== 'idle'"
          class="flex items-center gap-1.5 text-xs py-1"
        >
          <i
            :class="{
              'i-lucide-loader-circle animate-spin text-n-slate-9': saveState === 'saving',
              'i-lucide-check-circle text-green-600':                saveState === 'saved',
              'i-lucide-alert-circle text-red-500':                  saveState === 'error',
            }"
            class="size-3.5"
            aria-hidden="true"
          />
          <span
            :class="{
              'text-n-slate-9':  saveState === 'saving',
              'text-green-600':  saveState === 'saved',
              'text-red-500':    saveState === 'error',
            }"
          >
            {{ $t(`funnels.custom_fields.${saveState}`) }}
          </span>
        </div>
      </Transition>
    </template>
  </div>
</template>

<script>
import axios from 'axios';

export default {
  name: 'CustomAttributesTab',

  props: {
    cardId:   { type: [Number, String], required: true },
    funnelId: { type: [Number, String], required: true },
  },

  data() {
    return {
      fields:    [],
      values:    {},
      loading:   true,
      saveState: 'idle',   // idle | saving | saved | error
      _timer:    null,
    };
  },

  mounted() {
    this.loadFields();
  },

  beforeUnmount() {
    clearTimeout(this._timer);
  },

  methods: {
    async loadFields() {
      this.loading = true;
      try {
        const accountId = this.$store.getters['getCurrentAccountId'];
        const { data }  = await axios.get(
          `/api/v1/accounts/${accountId}/funnels/${this.funnelId}/cards/${this.cardId}/custom_fields`
        );
        this.fields = data;
        const init  = {};
        data.forEach(f => { init[f.attribute_id] = f.value ?? ''; });
        this.values = init;
      } catch {
        this.fields = [];
      } finally {
        this.loading = false;
      }
    },

    scheduleSave() {
      clearTimeout(this._timer);
      this.saveState = 'idle';
      this._timer    = setTimeout(() => this.save(), 700);
    },

    async save() {
      this.saveState = 'saving';
      try {
        const accountId = this.$store.getters['getCurrentAccountId'];
        const fields    = Object.entries(this.values).map(([id, value]) => ({
          attribute_id: Number(id),
          value,
        }));
        await axios.patch(
          `/api/v1/accounts/${accountId}/funnels/${this.funnelId}/cards/${this.cardId}/custom_fields`,
          { fields }
        );
        this.saveState = 'saved';
        setTimeout(() => { this.saveState = 'idle'; }, 2500);
      } catch {
        this.saveState = 'error';
        setTimeout(() => { this.saveState = 'idle'; }, 3500);
      }
    },
  },
};
</script>
