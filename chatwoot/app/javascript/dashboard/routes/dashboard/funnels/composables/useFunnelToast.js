import { ref } from 'vue';

// Shared singleton — todos os componentes de funis lêem o mesmo estado
const toasts = ref([]);
let _nextId = 1;

export function useFunnelToast() {
  function show(message, type = 'success', duration = 3500) {
    const id = _nextId++;
    toasts.value.push({ id, message, type });
    setTimeout(() => dismiss(id), duration);
  }

  function dismiss(id) {
    toasts.value = toasts.value.filter(t => t.id !== id);
  }

  const success = (msg) => show(msg, 'success');
  const error   = (msg) => show(msg, 'error');
  const info    = (msg) => show(msg, 'info');

  return { toasts, show, dismiss, success, error, info };
}
