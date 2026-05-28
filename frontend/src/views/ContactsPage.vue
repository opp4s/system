<template>
  <div class="flex-1 flex flex-col h-full overflow-hidden bg-slate-50/30">
    <!-- Header Principal -->
    <header class="h-16 px-6 border-b border-gray-100 flex items-center justify-between shrink-0 bg-white">
      <div class="flex items-center space-x-3">
        <div class="p-2 bg-zavy-50 text-zavy-600 rounded-xl">
          <component :is="Users" class="h-5 w-5" />
        </div>
        <div>
          <h1 class="text-base font-extrabold text-gray-900 tracking-tight">Lista de Contatos</h1>
          <p class="text-xs text-gray-400">Gerencie os clientes e leads do seu workspace.</p>
        </div>
      </div>

      <!-- Ações rápidas do Header -->
      <div>
        <button
          @click="openCreateContact"
          type="button"
          class="px-4 py-2 bg-slate-900 hover:bg-slate-800 text-white rounded-xl text-xs font-bold shadow transition-all flex items-center space-x-1.5"
        >
          <component :is="Plus" class="h-3.5 w-3.5" />
          <span>Novo Contato</span>
        </button>
      </div>
    </header>

    <!-- Área de Controle de Filtros e Busca -->
    <div class="p-6 border-b border-gray-100 bg-white/60 shrink-0">
      <div class="max-w-md relative">
        <div class="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-gray-400">
          <component :is="Search" class="h-4 w-4" />
        </div>
        <input
          v-model="searchQuery"
          type="text"
          placeholder="Buscar por nome, e-mail ou telefone..."
          class="block w-full pl-10 pr-4 py-2.5 rounded-xl border border-gray-200 focus:outline-none focus:border-slate-800 focus:ring-1 focus:ring-slate-800 bg-white text-xs transition-all placeholder:text-gray-400"
        />
        <span 
          v-if="searchQuery" 
          @click="searchQuery = ''"
          class="absolute inset-y-0 right-0 pr-3.5 flex items-center cursor-pointer text-gray-400 hover:text-gray-600"
        >
          <component :is="X" class="h-4 w-4" />
        </span>
      </div>
    </div>

    <!-- Tabela de Contatos -->
    <div class="flex-1 overflow-y-auto p-6">
      <div v-if="contactStore.loading.list" class="space-y-4">
        <div v-for="i in 5" :key="i" class="h-16 bg-white border border-gray-150 rounded-2xl animate-pulse"></div>
      </div>

      <div 
        v-else-if="contactStore.contacts.length === 0" 
        class="h-full flex flex-col items-center justify-center text-center text-sm text-gray-400 py-16 bg-white rounded-3xl border border-dashed border-gray-200"
      >
        <component :is="Users" class="h-12 w-12 text-gray-300 mb-3" />
        <span class="font-semibold text-gray-700">Nenhum contato cadastrado</span>
        <span class="text-xs text-gray-400 mt-1 max-w-xs">Adicione contatos ou integre uma conta do WhatsApp para sincronizar novos clientes.</span>
      </div>

      <div v-else class="bg-white rounded-2xl border border-gray-150 shadow-sm overflow-hidden">
        <table class="min-w-full divide-y divide-gray-150">
          <thead class="bg-gray-50/50">
            <tr>
              <th scope="col" class="px-6 py-4 text-left text-[10px] font-extrabold text-gray-400 uppercase tracking-wider">Contato</th>
              <th scope="col" class="px-6 py-4 text-left text-[10px] font-extrabold text-gray-400 uppercase tracking-wider">Telefone</th>
              <th scope="col" class="px-6 py-4 text-left text-[10px] font-extrabold text-gray-400 uppercase tracking-wider">E-mail</th>
              <th scope="col" class="px-6 py-4 class text-left text-[10px] font-extrabold text-gray-400 uppercase tracking-wider">Último Contato</th>
              <th scope="col" class="relative px-6 py-4">
                <span class="sr-only">Ações</span>
              </th>
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-gray-100">
            <tr 
              v-for="contact in contactStore.contacts" 
              :key="contact.id"
              @click="selectContact(contact.id)"
              class="hover:bg-slate-50/50 cursor-pointer transition-colors group"
            >
              <td class="px-6 py-4 whitespace-nowrap">
                <div class="flex items-center space-x-3">
                  <!-- Avatar -->
                  <div class="h-9 w-9 rounded-full shrink-0 flex items-center justify-center text-xs font-bold text-white shadow-sm transition-transform duration-200 group-hover:scale-105" :class="getAvatarBg(contact.name)">
                    {{ getInitials(contact.name) }}
                  </div>
                  <div>
                    <div class="text-xs font-bold text-gray-900 group-hover:text-zavy-600 transition-colors">{{ contact.name }}</div>
                    <div class="text-[10px] text-gray-400">ID: #{{ contact.id }}</div>
                  </div>
                </div>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-xs text-gray-600 font-semibold">
                {{ contact.phone || '—' }}
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-xs text-gray-500 font-medium">
                {{ contact.email || '—' }}
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-xs text-gray-400">
                {{ contact.last_contact || 'Sem registros' }}
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-right text-xs font-medium">
                <button 
                  class="p-1.5 text-gray-400 hover:text-slate-900 hover:bg-gray-100 rounded-xl transition-all"
                  @click.stop="selectContact(contact.id)"
                >
                  <component :is="ChevronRight" class="h-4 w-4" />
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Drawer de Detalhes do Contato (Slide-in) -->
    <transition name="slide-panel">
      <div v-if="contactStore.selectedContact" class="fixed inset-0 z-40 flex justify-end">
        <!-- Backdrop -->
        <div 
          @click="closeDetail"
          class="absolute inset-0 bg-slate-900/40 backdrop-blur-sm transition-opacity duration-300"
        ></div>

        <!-- Painel lateral -->
        <div class="relative w-full max-w-md h-full bg-white shadow-2xl flex flex-col z-10 animate-slide-in-right">
          <!-- Header do Painel -->
          <header class="h-16 px-6 border-b border-gray-100 flex items-center justify-between shrink-0 bg-gray-50/50">
            <span class="text-xs font-bold text-gray-400 uppercase tracking-wider">Detalhes do Contato</span>
            <button 
              @click="closeDetail"
              class="p-2 text-gray-400 hover:text-gray-650 hover:bg-gray-150 rounded-xl transition-all"
            >
              <component :is="X" class="h-4 w-4" />
            </button>
          </header>

          <!-- Corpo do Detalhe -->
          <div class="flex-1 overflow-y-auto p-6 space-y-6">
            <!-- Informações Gerais do Contato -->
            <div class="flex flex-col items-center text-center pb-4 border-b border-gray-100">
              <div class="h-16 w-16 rounded-full flex items-center justify-center text-xl font-extrabold text-white shadow-md mb-3" :class="getAvatarBg(contactStore.selectedContact.name)">
                {{ getInitials(contactStore.selectedContact.name) }}
              </div>
              <h2 class="text-base font-bold text-gray-900">{{ contactStore.selectedContact.name }}</h2>
              <p class="text-[10px] text-gray-400 mt-0.5">Último contato: {{ contactStore.selectedContact.last_contact || 'Sem registros' }}</p>

              <!-- Ações rápidas de contato -->
              <div class="flex items-center space-x-3 mt-4 w-full">
                <!-- Botão Criar Card -->
                <button
                  @click="triggerCreateCard"
                  type="button"
                  class="flex-1 px-4 py-2.5 bg-slate-900 hover:bg-slate-800 text-white rounded-xl text-xs font-bold shadow flex items-center justify-center space-x-1.5 transition-all"
                >
                  <component :is="Briefcase" class="h-3.5 w-3.5" />
                  <span>Criar Negócio</span>
                </button>
              </div>
            </div>

            <!-- Dados Básicos -->
            <div class="space-y-3 bg-gray-50/50 p-4 rounded-2xl border border-gray-150/50">
              <h3 class="text-[10px] font-bold text-gray-400 uppercase tracking-wider">Dados Básicos</h3>
              
              <div class="flex items-center space-x-3 text-xs">
                <component :is="Phone" class="h-4 w-4 text-gray-400 shrink-0" />
                <div>
                  <span class="text-[9px] text-gray-400 block font-bold">TELEFONE</span>
                  <span class="font-semibold text-gray-800">{{ contactStore.selectedContact.phone || 'Não cadastrado' }}</span>
                </div>
              </div>

              <div class="flex items-center space-x-3 text-xs">
                <component :is="Mail" class="h-4 w-4 text-gray-400 shrink-0" />
                <div class="min-w-0 flex-1">
                  <span class="text-[9px] text-gray-400 block font-bold">E-MAIL</span>
                  <span class="font-semibold text-gray-800 break-all">{{ contactStore.selectedContact.email || 'Não cadastrado' }}</span>
                </div>
              </div>
            </div>

            <!-- Negócios Vinculados (Cards) -->
            <div class="space-y-3">
              <h3 class="text-[10px] font-bold text-gray-400 uppercase tracking-wider">Negócios no Funil</h3>
              
              <div v-if="!contactStore.selectedContact.cards?.length" class="text-xs text-gray-400 italic bg-gray-50/20 p-4 rounded-2xl border border-gray-150/40 text-center">
                Nenhum negócio associado a este contato.
              </div>
              
              <div v-else class="space-y-2">
                <div 
                  v-for="card in contactStore.selectedContact.cards" 
                  :key="card.id"
                  @click="goToCard(card)"
                  class="p-3 bg-white border border-gray-150 rounded-xl shadow-sm hover:border-gray-300 hover:shadow transition-all cursor-pointer flex items-center justify-between group/card"
                >
                  <div class="space-y-1">
                    <div class="text-xs font-bold text-gray-900 group-hover/card:text-zavy-600 transition-colors">{{ card.title }}</div>
                    <div class="flex items-center space-x-2 text-[10px] text-gray-400">
                      <span class="font-semibold text-gray-700">{{ formatCurrency(card.value, card.currency) }}</span>
                      <span>•</span>
                      <span>Etapa: {{ getStageName(card.stage_id) }}</span>
                    </div>
                  </div>
                  <component :is="ExternalLink" class="h-3.5 w-3.5 text-gray-400 group-hover/card:text-slate-900 transition-colors" />
                </div>
              </div>
            </div>

            <!-- Conversas Ativas (Chatwoot) -->
            <div class="space-y-3">
              <h3 class="text-[10px] font-bold text-gray-400 uppercase tracking-wider">Conversas no WhatsApp</h3>
              
              <div v-if="!contactStore.selectedContact.conversations?.length" class="text-xs text-gray-400 italic bg-gray-50/20 p-4 rounded-2xl border border-gray-150/40 text-center">
                Nenhuma conversa no WhatsApp vinculada.
              </div>
              
              <div v-else class="space-y-2">
                <div 
                  v-for="conv in contactStore.selectedContact.conversations" 
                  :key="conv.id"
                  class="p-3 bg-white border border-gray-150 rounded-xl shadow-sm space-y-2"
                >
                  <div class="flex items-center justify-between text-[9px] font-bold">
                    <span class="uppercase tracking-wider text-emerald-600 flex items-center space-x-1">
                      <span class="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse"></span>
                      <span>Conversa #{{ conv.id }}</span>
                    </span>
                    <span class="text-gray-450">{{ formatFriendlyTime(conv.updated_at) }}</span>
                  </div>
                  <p class="text-xs text-gray-600 italic bg-gray-50 p-2 rounded-lg leading-relaxed whitespace-pre-wrap">
                    "{{ conv.last_message }}"
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </transition>

    <!-- Modal Novo Contato (Cadastro Rápido Local) -->
    <div v-if="showCreateContactModal" class="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div @click="showCreateContactModal = false" class="absolute inset-0 bg-slate-900/60 backdrop-blur-sm"></div>
      <div class="relative bg-white rounded-3xl shadow-2xl max-w-md w-full p-6 z-10 animate-scale-up border border-gray-100 space-y-4">
        <header class="flex items-center justify-between pb-3 border-b border-gray-100">
          <div>
            <h3 class="text-base font-bold text-gray-900">Novo Contato</h3>
            <p class="text-[10px] text-gray-400 mt-0.5">Adicione um novo contato ao banco de dados.</p>
          </div>
          <button @click="showCreateContactModal = false" class="p-1.5 text-gray-400 hover:text-gray-600 rounded-lg hover:bg-gray-50">
            <component :is="X" class="h-4.5 w-4.5" />
          </button>
        </header>

        <form @submit.prevent="saveNewContact" class="space-y-3.5">
          <div>
            <label class="block text-[10px] font-bold text-gray-600 uppercase mb-1">Nome Completo *</label>
            <input 
              v-model="newContactForm.name" 
              type="text" 
              required 
              placeholder="Ex: Carlos Souza"
              class="block w-full px-3.5 py-2.5 rounded-xl border border-gray-200 focus:outline-none focus:border-slate-800 focus:ring-1 focus:ring-slate-800 text-xs bg-gray-50/20"
            />
          </div>

          <div>
            <label class="block text-[10px] font-bold text-gray-600 uppercase mb-1">Telefone / WhatsApp</label>
            <input 
              v-model="newContactForm.phone" 
              type="text" 
              placeholder="Ex: +55 11 99999-9999"
              class="block w-full px-3.5 py-2.5 rounded-xl border border-gray-200 focus:outline-none focus:border-slate-800 focus:ring-1 focus:ring-slate-800 text-xs bg-gray-50/20"
            />
          </div>

          <div>
            <label class="block text-[10px] font-bold text-gray-600 uppercase mb-1">E-mail</label>
            <input 
              v-model="newContactForm.email" 
              type="email" 
              placeholder="Ex: carlos@empresa.com"
              class="block w-full px-3.5 py-2.5 rounded-xl border border-gray-200 focus:outline-none focus:border-slate-800 focus:ring-1 focus:ring-slate-800 text-xs bg-gray-50/20"
            />
          </div>

          <div class="pt-3 border-t border-gray-100 flex items-center justify-end space-x-2">
            <button 
              type="button" 
              @click="showCreateContactModal = false"
              class="px-3.5 py-2 border border-gray-200 text-gray-600 rounded-xl text-xs font-semibold hover:bg-gray-50"
            >
              Cancelar
            </button>
            <button 
              type="submit" 
              :disabled="contactStore.loading.mutation"
              class="px-4 py-2 bg-slate-900 hover:bg-slate-800 text-white rounded-xl text-xs font-bold disabled:opacity-50"
            >
              {{ contactStore.loading.mutation ? 'Salvando...' : 'Salvar Contato' }}
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- Modal Criar Card integrado -->
    <CreateCardModal
      :show="showCreateCardModal"
      :initial-contact-data="prefilledContactData"
      @close="showCreateCardModal = false"
      @created="onCardCreated"
    />
  </div>
</template>

<script setup>
import { ref, watch, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useContactStore } from '@/stores/contact'
import { usePipelineStore } from '@/stores/pipeline'
import { useToast } from '@/composables/useToast'
import CreateCardModal from '@/views/pipelines/CreateCardModal.vue'
import { 
  Users, 
  Search, 
  X, 
  ChevronRight, 
  Phone, 
  Mail, 
  Plus, 
  ExternalLink, 
  Briefcase, 
  MessageSquare,
  AlertCircle
} from 'lucide-vue-next'

const router = useRouter()
const contactStore = useContactStore()
const pipelineStore = usePipelineStore()
const toast = useToast()

const searchQuery = ref('')
const showCreateCardModal = ref(false)
const prefilledContactData = ref(null)

const showCreateContactModal = ref(false)
const newContactForm = ref({
  name: '',
  phone: '',
  email: ''
})

// Debounce para busca de contatos (400ms)
let debounceTimeout = null
watch(searchQuery, (newVal) => {
  if (debounceTimeout) clearTimeout(debounceTimeout)
  debounceTimeout = setTimeout(() => {
    contactStore.searchContacts(newVal)
  }, 400)
})

onMounted(async () => {
  await contactStore.fetchContacts()
})

const selectContact = async (id) => {
  await contactStore.fetchContactDetail(id)
}

const closeDetail = () => {
  contactStore.selectedContact = null
}

const formatCurrency = (value, currency = 'BRL') => {
  return new Intl.NumberFormat('pt-BR', {
    style: 'currency',
    currency: currency
  }).format(value || 0)
}

// Iniciais do Nome para Avatar
const getInitials = (name) => {
  if (!name) return '?'
  const parts = name.trim().split(' ')
  if (parts.length >= 2) {
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase()
  }
  return parts[0].substring(0, 2).toUpperCase()
}

// Cores de Avatar baseadas no nome (para diversificar visualmente)
const getAvatarBg = (name) => {
  if (!name) return 'bg-slate-500'
  const charCodeSum = name.split('').reduce((acc, char) => acc + char.charCodeAt(0), 0)
  const colors = [
    'bg-indigo-500',
    'bg-emerald-500',
    'bg-sky-500',
    'bg-violet-600',
    'bg-rose-500',
    'bg-amber-500',
    'bg-teal-600',
    'bg-fuchsia-600'
  ]
  return colors[charCodeSum % colors.length]
}

const getStageName = (stageId) => {
  const stage = pipelineStore.stages.find(s => s.id === stageId)
  return stage ? stage.name : `Etapa #${stageId}`
}

const formatFriendlyTime = (isoString) => {
  if (!isoString) return ''
  const date = new Date(isoString)
  const hours = date.getHours().toString().padStart(2, '0')
  const minutes = date.getMinutes().toString().padStart(2, '0')
  return `${date.toLocaleDateString('pt-BR')} às ${hours}:${minutes}`
}

// Abre o modal de criação de card pré-preenchido
const triggerCreateCard = () => {
  const contact = contactStore.selectedContact
  if (!contact) return

  prefilledContactData.value = {
    contact_name: contact.name,
    contact_phone: contact.phone,
    contact_email: contact.email
  }
  showCreateCardModal.value = true
}

// Quando um card é criado com sucesso, atualizamos a lista e o detalhe do contato para refletir a nova oportunidade
const onCardCreated = async (newCard) => {
  toast.success('Negócio associado com sucesso!')
  const contact = contactStore.selectedContact
  if (contact) {
    // Recarrega o detalhe do contato para atualizar a lista de cards vinculados dele
    await contactStore.fetchContactDetail(contact.id)
  }
}

// Redireciona o usuário para o pipeline correto e abre o negócio
const goToCard = async (card) => {
  closeDetail()
  // Procura a qual pipeline o card pertence na store
  // Como temos stage_id, localizamos o stage correspondente
  const stage = pipelineStore.stages.find(s => s.id === card.stage_id)
  const pipelineId = stage ? stage.pipeline_id : 1 // fallback para principal

  // Mudar de rota
  router.push({
    name: 'card-detail',
    params: {
      id: pipelineId,
      cardId: card.id
    }
  })
}

// Modal Novo Contato
const openCreateContact = () => {
  newContactForm.value = { name: '', phone: '', email: '' }
  showCreateContactModal.value = true
}

const saveNewContact = async () => {
  if (!newContactForm.value.name.trim()) {
    toast.error('O nome do contato é obrigatório!')
    return
  }

  try {
    const contact = await contactStore.createContact({ ...newContactForm.value })
    toast.success('Contato cadastrado com sucesso!')
    showCreateContactModal.value = false
    // Abre automaticamente os detalhes do novo contato
    await selectContact(contact.id)
  } catch (error) {
    toast.error('Erro ao cadastrar contato.')
  }
}
</script>

<style scoped>
@keyframes slideInRight {
  from {
    transform: translateX(100%);
  }
  to {
    transform: translateX(0);
  }
}
.animate-slide-in-right {
  animation: slideInRight 0.25s cubic-bezier(0.16, 1, 0.3, 1) forwards;
}

@keyframes scaleUp {
  from {
    opacity: 0;
    transform: scale(0.95);
  }
  to {
    opacity: 1;
    transform: scale(1);
  }
}
.animate-scale-up {
  animation: scaleUp 0.18s cubic-bezier(0.16, 1, 0.3, 1) forwards;
}
</style>
