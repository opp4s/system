<script setup>
import { ref } from 'vue';

/* global axios */

const props = defineProps({
  accountId: { type: [String, Number], default: '' },
  currentUrl: { type: String, default: '' },
});

const emit = defineEmits(['saved']);

const form = ref({
  evolution_api_url:       props.currentUrl || '',
  evolution_api_key:       '',
  evolution_webhook_token: '',
});

const saving = ref(false);
const error = ref('');
const success = ref(false);

async function save() {
  error.value = '';
  saving.value = true;
  try {
    await axios.post(
      `/api/v1/accounts/${props.accountId}/whatsapp_lite/settings`,
      form.value
    );
    success.value = true;
    setTimeout(() => emit('saved'), 800);
  } catch (e) {
    error.value = e.response?.data?.error || 'Erro ao salvar. Verifique os campos.';
  } finally {
    saving.value = false;
  }
}
</script>

<template>
  <div class="max-w-lg mx-auto py-10 px-4">
    <div class="flex items-center gap-3 mb-6">
      <div class="w-10 h-10 rounded-lg bg-[#25D366]/10 flex items-center justify-center flex-shrink-0">
        <svg viewBox="0 0 24 24" class="w-6 h-6 fill-[#25D366]">
          <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347z"/>
          <path d="M12 0C5.373 0 0 5.373 0 12c0 2.124.554 4.118 1.524 5.845L.057 23.07a.75.75 0 00.932.932l5.226-1.467A11.944 11.944 0 0012 24c6.627 0 12-5.373 12-12S18.627 0 12 0zm0 22c-1.89 0-3.663-.497-5.193-1.367l-.372-.214-3.852 1.081 1.081-3.852-.214-.372A9.944 9.944 0 012 12C2 6.477 6.477 2 12 2s10 4.477 10 10-4.477 10-10 10z"/>
        </svg>
      </div>
      <div>
        <h2 class="text-heading-2 text-n-slate-12">WhatsApp Lite — Configuração inicial</h2>
        <p class="text-body-sm text-n-slate-11">
          Configure a Evolution API que esta conta utilizará.
        </p>
      </div>
    </div>

    <div class="space-y-4">
      <div>
        <label class="block text-xs font-medium text-n-slate-11 mb-1.5">
          URL da Evolution API <span class="text-ruby-500">*</span>
        </label>
        <input
          v-model="form.evolution_api_url"
          type="url"
          placeholder="https://evolution.exemplo.com"
          class="w-full px-3 py-2.5 rounded-lg border border-n-weak bg-n-alpha-1 text-sm text-n-slate-12 outline-none focus:border-woot-500 transition-colors"
        />
      </div>

      <div>
        <label class="block text-xs font-medium text-n-slate-11 mb-1.5">
          Chave da API (apikey) <span class="text-ruby-500">*</span>
        </label>
        <input
          v-model="form.evolution_api_key"
          type="password"
          placeholder="Chave de autenticação da Evolution"
          class="w-full px-3 py-2.5 rounded-lg border border-n-weak bg-n-alpha-1 text-sm text-n-slate-12 outline-none focus:border-woot-500 transition-colors"
          autocomplete="new-password"
        />
      </div>

      <div>
        <label class="block text-xs font-medium text-n-slate-11 mb-1.5">
          Token de webhook <span class="text-ruby-500">*</span>
        </label>
        <input
          v-model="form.evolution_webhook_token"
          type="text"
          placeholder="Qualquer valor secreto (ex: minha-senha-secreta-123)"
          class="w-full px-3 py-2.5 rounded-lg border border-n-weak bg-n-alpha-1 text-sm text-n-slate-12 outline-none focus:border-woot-500 transition-colors"
        />
        <p class="text-xs text-n-slate-9 mt-1">
          Usado para autenticar callbacks da Evolution. Gere um valor aleatório e seguro.
        </p>
      </div>
    </div>

    <p v-if="error" class="mt-4 text-sm text-ruby-500">{{ error }}</p>

    <div v-if="success" class="mt-4 flex items-center gap-2 text-sm text-green-600">
      <span class="i-woot-checkmark" />
      Configurações salvas! Redirecionando...
    </div>

    <button
      v-else
      class="mt-6 flex items-center gap-2 px-5 py-2.5 bg-woot-500 text-white rounded-lg text-sm font-medium hover:bg-woot-600 transition-colors disabled:opacity-50"
      :disabled="saving"
      @click="save"
    >
      <span v-if="saving" class="i-woot-spinner animate-spin" />
      {{ saving ? 'Verificando conexão...' : 'Salvar e continuar' }}
    </button>
  </div>
</template>
