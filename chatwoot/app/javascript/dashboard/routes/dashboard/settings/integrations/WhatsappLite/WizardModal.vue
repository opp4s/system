<script setup>
import { ref, computed, onUnmounted } from 'vue';

/* global axios */

const props = defineProps({
  accountId: { type: [String, Number], default: '' },
});

const emit = defineEmits(['close', 'connected']);

const step = ref('platform');
const platform = ref(null);
const phone = ref('');
const phoneError = ref('');
const instanceId = ref(null);
const qrCode = ref(null);
const pairingCode = ref(null);
const expiresAt = ref(null);
const usePairing = ref(false);
const loadingQr = ref(false);
const apiError = ref('');

let pollTimer = null;
let refreshTimer = null;
let abortController = null;

const stepIndex = computed(() => {
  const map = { platform: 0, phone: 1, qr: 2, success: 3 };
  return map[step.value] ?? 0;
});

function apiBase() {
  return `/api/v1/accounts/${props.accountId}/whatsapp_lite`;
}

function selectPlatform(p) {
  platform.value = p;
  step.value = 'phone';
}

function validatePhone() {
  const digits = phone.value.replace(/\D/g, '');
  if (digits.length < 10) {
    phoneError.value = 'Digite um número válido com DDD';
    return false;
  }
  phoneError.value = '';
  return true;
}

function scheduleQrRefresh(expiresAtIso) {
  clearTimeout(refreshTimer);
  const msUntilExpiry = new Date(expiresAtIso).getTime() - Date.now() - 5000;
  if (msUntilExpiry > 0) {
    refreshTimer = setTimeout(async () => {
      try {
        const res = await axios.post(`${apiBase()}/refresh`, {
          instance_id: instanceId.value,
        });
        qrCode.value = res.data.qr_code_base64;
        expiresAt.value = res.data.expires_at;
        scheduleQrRefresh(res.data.expires_at);
      } catch {
        // ignored — modal may have been closed
      }
    }, msUntilExpiry);
  }
}

function startPolling() {
  clearInterval(pollTimer);
  pollTimer = setInterval(async () => {
    if (!instanceId.value) return;
    try {
      const res = await axios.get(`${apiBase()}/status`, {
        params: { instance_id: instanceId.value },
      });
      const status = res.data.status;
      if (status === 'connected') {
        clearInterval(pollTimer);
        clearTimeout(refreshTimer);
        step.value = 'success';
        setTimeout(() => emit('connected', { instanceId: instanceId.value }), 1500);
      } else if (status === 'qr_expired') {
        clearInterval(pollTimer);
        apiError.value = 'QR expirado. Clique em "Atualizar QR" para gerar um novo.';
      }
    } catch {
      // silently retry
    }
  }, 3000);
}

async function requestConnection() {
  if (!validatePhone()) return;

  abortController = new AbortController();
  loadingQr.value = true;
  apiError.value = '';

  try {
    const res = await axios.post(
      `${apiBase()}/connect`,
      {
        phone_number: `+55${phone.value.replace(/\D/g, '')}`,
        method: usePairing.value ? 'pairing' : 'qr',
      },
      { signal: abortController.signal }
    );

    instanceId.value = res.data.instance_id;
    qrCode.value = res.data.qr_code_base64;
    pairingCode.value = res.data.pairing_code;
    expiresAt.value = res.data.expires_at;

    step.value = 'qr';
    if (expiresAt.value) scheduleQrRefresh(expiresAt.value);
    startPolling();
  } catch (e) {
    if (e.name === 'CanceledError' || e.name === 'AbortError') return;
    const msg = e.response?.data?.error || e.response?.data?.message || e.message;
    apiError.value = msg || 'Erro ao criar conexão. Tente novamente.';
  } finally {
    loadingQr.value = false;
  }
}

async function refreshQr() {
  loadingQr.value = true;
  apiError.value = '';
  try {
    const res = await axios.post(`${apiBase()}/refresh`, {
      instance_id: instanceId.value,
    });
    qrCode.value = res.data.qr_code_base64;
    expiresAt.value = res.data.expires_at;
    if (expiresAt.value) scheduleQrRefresh(expiresAt.value);
  } catch {
    apiError.value = 'Não foi possível atualizar o QR Code.';
  } finally {
    loadingQr.value = false;
  }
}

function close() {
  abortController?.abort();
  clearInterval(pollTimer);
  clearTimeout(refreshTimer);
  emit('close');
}

onUnmounted(() => {
  clearInterval(pollTimer);
  clearTimeout(refreshTimer);
});
</script>

<template>
  <div class="fixed inset-0 z-50 flex items-center justify-center">
    <!-- Backdrop -->
    <div class="absolute inset-0 bg-n-slate-12/40 backdrop-blur-sm" @click="close" />

    <!-- Modal -->
    <div class="relative bg-n-solid-1 rounded-2xl shadow-xl w-full max-w-2xl mx-4 overflow-hidden">

      <!-- Header -->
      <div class="flex items-center justify-between px-6 py-4 border-b border-n-weak">
        <div class="flex items-center gap-3">
          <div class="w-8 h-8 rounded-lg bg-[#25D366]/10 flex items-center justify-center">
            <svg viewBox="0 0 24 24" class="w-5 h-5 fill-[#25D366]">
              <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347z"/>
              <path d="M12 0C5.373 0 0 5.373 0 12c0 2.124.554 4.118 1.524 5.845L.057 23.07a.75.75 0 00.932.932l5.226-1.467A11.944 11.944 0 0012 24c6.627 0 12-5.373 12-12S18.627 0 12 0zm0 22c-1.89 0-3.663-.497-5.193-1.367l-.372-.214-3.852 1.081 1.081-3.852-.214-.372A9.944 9.944 0 012 12C2 6.477 6.477 2 12 2s10 4.477 10 10-4.477 10-10 10z"/>
            </svg>
          </div>
          <span class="text-heading-3 text-n-slate-12">Conectar WhatsApp</span>
        </div>
        <button class="text-n-slate-9 hover:text-n-slate-12 transition-colors" @click="close">
          <span class="i-woot-close text-xl" />
        </button>
      </div>

      <!-- Step indicator -->
      <div class="flex items-center gap-0 px-6 pt-4 pb-2">
        <template v-for="(label, i) in ['Plataforma', 'Número', 'Conectar', 'Pronto']" :key="i">
          <div class="flex items-center gap-1.5">
            <div
              class="w-6 h-6 rounded-full flex items-center justify-center text-xs font-semibold transition-colors"
              :class="i <= stepIndex
                ? 'bg-woot-500 text-white'
                : 'bg-n-alpha-2 text-n-slate-9'"
            >
              <span v-if="i < stepIndex" class="i-woot-checkmark text-xs" />
              <span v-else>{{ i + 1 }}</span>
            </div>
            <span
              class="text-xs hidden sm:block"
              :class="i <= stepIndex ? 'text-n-slate-12 font-medium' : 'text-n-slate-9'"
            >{{ label }}</span>
          </div>
          <div v-if="i < 3" class="flex-1 h-px mx-2 bg-n-weak min-w-4" />
        </template>
      </div>

      <!-- Body -->
      <div class="px-6 py-6 min-h-[340px]">

        <!-- STEP: Platform selection -->
        <div v-if="step === 'platform'" class="flex flex-col items-center text-center">
          <div class="w-16 h-16 rounded-2xl bg-[#25D366]/10 flex items-center justify-center mb-4">
            <svg viewBox="0 0 24 24" class="w-8 h-8 fill-[#25D366]">
              <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347z"/>
              <path d="M12 0C5.373 0 0 5.373 0 12c0 2.124.554 4.118 1.524 5.845L.057 23.07a.75.75 0 00.932.932l5.226-1.467A11.944 11.944 0 0012 24c6.627 0 12-5.373 12-12S18.627 0 12 0zm0 22c-1.89 0-3.663-.497-5.193-1.367l-.372-.214-3.852 1.081 1.081-3.852-.214-.372A9.944 9.944 0 012 12C2 6.477 6.477 2 12 2s10 4.477 10 10-4.477 10-10 10z"/>
            </svg>
          </div>
          <h3 class="text-heading-2 text-n-slate-12 mb-1">Todas as conversas. Um inbox.</h3>
          <p class="text-body-sm text-n-slate-10 mb-8 max-w-sm">
            Pronto para centralizar seu WhatsApp no Chatwoot? Vamos começar selecionando o tipo de dispositivo.
          </p>
          <div class="flex gap-4 w-full max-w-xs">
            <button
              class="flex-1 flex flex-col items-center gap-2 p-4 rounded-xl border-2 border-n-weak hover:border-woot-500 hover:bg-woot-25 transition-all group"
              @click="selectPlatform('android')"
            >
              <span class="text-3xl">🤖</span>
              <span class="text-sm font-medium text-n-slate-12 group-hover:text-woot-600">Android</span>
            </button>
            <button
              class="flex-1 flex flex-col items-center gap-2 p-4 rounded-xl border-2 border-n-weak hover:border-woot-500 hover:bg-woot-25 transition-all group"
              @click="selectPlatform('iphone')"
            >
              <span class="text-3xl">🍎</span>
              <span class="text-sm font-medium text-n-slate-12 group-hover:text-woot-600">iPhone</span>
            </button>
          </div>
        </div>

        <!-- STEP: Phone number -->
        <div v-else-if="step === 'phone'" class="flex flex-col max-w-sm mx-auto">
          <h3 class="text-heading-3 text-n-slate-12 mb-1">Qual o número do WhatsApp?</h3>
          <p class="text-body-sm text-n-slate-10 mb-6">
            Digite o número com DDD (Brasil). Ex: 41 99999-0000
          </p>

          <label class="text-xs font-medium text-n-slate-11 mb-1.5 block">Número de telefone</label>
          <input
            v-model="phone"
            type="tel"
            placeholder="41 99999-0000"
            class="w-full px-3 py-2.5 rounded-lg border text-sm text-n-slate-12 bg-n-alpha-1 outline-none transition-colors"
            :class="phoneError
              ? 'border-ruby-500 focus:border-ruby-500'
              : 'border-n-weak focus:border-woot-500'"
            @keyup.enter="requestConnection"
          />
          <p v-if="phoneError" class="text-xs text-ruby-500 mt-1">{{ phoneError }}</p>

          <label class="flex items-center gap-2 mt-4 cursor-pointer">
            <input v-model="usePairing" type="checkbox" class="rounded" />
            <span class="text-sm text-n-slate-11">Usar código de pareamento <span class="text-n-slate-9">(sem QR Code)</span></span>
          </label>

          <p v-if="apiError" class="text-xs text-ruby-500 mt-3">{{ apiError }}</p>

          <div class="flex gap-3 mt-6">
            <button
              class="flex-1 px-4 py-2.5 rounded-lg border border-n-weak text-sm font-medium text-n-slate-11 hover:bg-n-alpha-2 transition-colors"
              @click="step = 'platform'"
            >
              Voltar
            </button>
            <button
              class="flex-1 px-4 py-2.5 rounded-lg bg-woot-500 text-white text-sm font-medium hover:bg-woot-600 transition-colors disabled:opacity-50"
              :disabled="loadingQr"
              @click="requestConnection"
            >
              <span v-if="loadingQr" class="i-woot-spinner animate-spin mr-1.5" />
              {{ loadingQr ? 'Aguarde...' : 'Continuar' }}
            </button>
          </div>
        </div>

        <!-- STEP: QR / Pairing code -->
        <div v-else-if="step === 'qr'" class="flex gap-8">
          <!-- Left: Instructions -->
          <div class="flex-1 flex flex-col">
            <h3 class="text-heading-3 text-n-slate-12 mb-4">
              {{ usePairing ? 'Insira o código no WhatsApp' : 'Aponte a câmera para o QR Code' }}
            </h3>

            <template v-if="!usePairing">
              <ol class="space-y-3 text-sm text-n-slate-11">
                <li class="flex gap-3">
                  <span class="w-5 h-5 rounded-full bg-woot-100 text-woot-700 text-xs flex items-center justify-center flex-shrink-0 font-semibold mt-0.5">1</span>
                  <span>Abra o WhatsApp no seu celular</span>
                </li>
                <li class="flex gap-3">
                  <span class="w-5 h-5 rounded-full bg-woot-100 text-woot-700 text-xs flex items-center justify-center flex-shrink-0 font-semibold mt-0.5">2</span>
                  <span>
                    <template v-if="platform === 'iphone'">
                      Toque em <strong>Configurações</strong> → <strong>Dispositivos conectados</strong>
                    </template>
                    <template v-else>
                      Toque no <strong>Menu</strong> → <strong>Dispositivos conectados</strong>
                    </template>
                  </span>
                </li>
                <li class="flex gap-3">
                  <span class="w-5 h-5 rounded-full bg-woot-100 text-woot-700 text-xs flex items-center justify-center flex-shrink-0 font-semibold mt-0.5">3</span>
                  <span>Toque em <strong>Conectar um aparelho</strong></span>
                </li>
                <li class="flex gap-3">
                  <span class="w-5 h-5 rounded-full bg-woot-100 text-woot-700 text-xs flex items-center justify-center flex-shrink-0 font-semibold mt-0.5">4</span>
                  <span>Aponte a câmera para o QR Code ao lado</span>
                </li>
              </ol>
            </template>

            <template v-else>
              <ol class="space-y-3 text-sm text-n-slate-11">
                <li class="flex gap-3">
                  <span class="w-5 h-5 rounded-full bg-woot-100 text-woot-700 text-xs flex items-center justify-center flex-shrink-0 font-semibold mt-0.5">1</span>
                  <span>Abra o WhatsApp no celular</span>
                </li>
                <li class="flex gap-3">
                  <span class="w-5 h-5 rounded-full bg-woot-100 text-woot-700 text-xs flex items-center justify-center flex-shrink-0 font-semibold mt-0.5">2</span>
                  <span>Vá em <strong>Dispositivos conectados</strong> → <strong>Conectar com número de telefone</strong></span>
                </li>
                <li class="flex gap-3">
                  <span class="w-5 h-5 rounded-full bg-woot-100 text-woot-700 text-xs flex items-center justify-center flex-shrink-0 font-semibold mt-0.5">3</span>
                  <span>Digite o código abaixo quando solicitado</span>
                </li>
              </ol>
            </template>

            <div class="mt-auto pt-4">
              <p v-if="apiError" class="text-xs text-ruby-500 mb-2">{{ apiError }}</p>
              <p v-else class="text-xs text-n-slate-9 flex items-center gap-1.5">
                <span class="i-woot-spinner animate-spin" />
                Aguardando conexão...
              </p>
            </div>
          </div>

          <!-- Right: QR or Pairing Code -->
          <div class="flex flex-col items-center justify-center flex-shrink-0">
            <template v-if="usePairing">
              <div class="bg-n-alpha-2 rounded-xl px-6 py-4 text-center">
                <p class="text-xs text-n-slate-9 mb-2 font-medium uppercase tracking-wide">Código de Pareamento</p>
                <div
                  v-if="pairingCode"
                  class="text-3xl font-mono font-bold text-n-slate-12 tracking-[0.15em]"
                >
                  {{ pairingCode }}
                </div>
                <div v-else class="flex items-center justify-center h-12">
                  <span class="i-woot-spinner animate-spin text-xl text-n-slate-9" />
                </div>
              </div>
            </template>

            <template v-else>
              <div class="relative">
                <div v-if="loadingQr" class="w-48 h-48 bg-n-alpha-2 rounded-xl flex items-center justify-center">
                  <span class="i-woot-spinner animate-spin text-2xl text-n-slate-9" />
                </div>
                <img
                  v-else-if="qrCode"
                  :src="`data:image/png;base64,${qrCode}`"
                  alt="QR Code"
                  class="w-48 h-48 rounded-xl border border-n-weak"
                />
              </div>
              <button
                class="mt-3 text-xs text-woot-500 hover:text-woot-600 flex items-center gap-1"
                @click="refreshQr"
              >
                <span class="i-woot-refresh" />
                Atualizar QR
              </button>
            </template>
          </div>
        </div>

        <!-- STEP: Success -->
        <div v-else-if="step === 'success'" class="flex flex-col items-center justify-center text-center py-8">
          <div class="w-16 h-16 rounded-full bg-green-100 flex items-center justify-center mb-4">
            <span class="i-woot-checkmark text-3xl text-green-600" />
          </div>
          <h3 class="text-heading-2 text-n-slate-12 mb-2">WhatsApp conectado!</h3>
          <p class="text-body-sm text-n-slate-10">
            O número foi conectado e o inbox foi criado no Chatwoot.
          </p>
        </div>

      </div>
    </div>
  </div>
</template>
