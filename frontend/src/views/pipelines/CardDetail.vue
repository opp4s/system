<template>
  <div class="fixed inset-0 z-50 flex justify-end">
    <!-- Backdrop de Fundo -->
    <div 
      @click="closeDetail"
      class="absolute inset-0 bg-slate-900/40 backdrop-blur-sm transition-opacity duration-300"
    ></div>

    <!-- Painel Slide-in Lateral (ocupando 60% de largura no desktop, layout dividido) -->
    <div 
      class="relative w-full md:w-[65vw] lg:w-[60vw] h-full bg-white shadow-2xl flex flex-col z-10 animate-slide-in-right transition-transform duration-300"
    >
      <!-- Header do Slide-in -->
      <header class="h-16 px-6 border-b border-gray-100 flex items-center justify-between shrink-0 bg-gray-50/50">
        <div class="flex items-center space-x-3">
          <span class="px-2.5 py-1 text-xs font-bold bg-slate-950 text-white rounded-lg">Negócio #{{ cardId }}</span>
          <span class="text-gray-400">/</span>
          <span class="text-sm font-semibold text-gray-500">Ficha do Lead</span>
        </div>

        <button 
          @click="closeDetail"
          class="p-2 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-xl transition-all duration-150"
        >
          <component :is="X" class="h-5 w-5" />
        </button>
      </header>

      <!-- Corpo do Detalhe -->
      <div v-if="card" class="flex-1 flex flex-col md:flex-row overflow-hidden">
        <!-- Coluna Esquerda: Dados do Card (Painel de ~38% de largura no desktop) -->
        <aside class="w-full md:w-80 border-b md:border-b-0 md:border-r border-gray-100 overflow-y-auto p-5 flex flex-col space-y-5 bg-gray-50/30">
          
          <!-- Seletor de Tabs (Dados, Campos, Histórico) -->
          <div class="flex border-b border-gray-200 shrink-0 bg-transparent -mx-5 px-5">
            <button 
              v-for="tab in ['dados', 'campos', 'historico']" 
              :key="tab"
              @click="activeTab = tab"
              class="pb-2.5 text-xs font-black uppercase tracking-wider border-b-2 transition-all mr-5 focus:outline-none"
              :class="activeTab === tab ? 'border-slate-900 text-slate-900' : 'border-transparent text-gray-400 hover:text-gray-600'"
            >
              {{ tab === 'dados' ? 'Dados' : tab === 'campos' ? 'Campos' : 'Histórico' }}
            </button>
          </div>

          <!-- TAB 1: DADOS PRINCIPAIS -->
          <div v-if="activeTab === 'dados'" class="space-y-3 flex-1">
            <!-- Título do negócio -->
            <div class="border-b border-slate-100 pb-3 mb-3">
              <label class="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">Título do Negócio</label>
              <div v-if="!isEditingTitle" @click="isEditingTitle = true" class="text-xs font-semibold text-slate-850 cursor-pointer hover:bg-slate-100/60 px-2 py-1 rounded-lg min-h-[1.75rem] flex items-center transition-colors">
                {{ card.title }}
              </div>
              <input
                v-else
                v-model="editingTitle"
                @blur="saveTitle"
                @keyup.enter="saveTitle"
                type="text"
                autofocus
                class="text-xs font-semibold text-slate-850 w-full border border-slate-200 focus:outline-none focus:border-slate-800 rounded-xl px-2.5 py-1 bg-white"
              />
            </div>

            <!-- Estágio Atual (StageSwitcher integrado) -->
            <div class="border-b border-slate-100 pb-3 mb-3">
              <label class="text-[10px] font-bold text-slate-400 uppercase tracking-wider block mb-1">Etapa do Funil</label>
              <StageSwitcher 
                :active-stage-id="card.stage_id"
                @change-stage="handleStageChange"
              />
            </div>

            <!-- Valor e Moeda -->
            <div class="border-b border-slate-100 pb-3 mb-3">
              <label class="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">Valor da Oportunidade</label>
              <div v-if="!isEditingValue" @click="isEditingValue = true" class="text-xs font-semibold text-slate-850 cursor-pointer hover:bg-slate-100/60 px-2 py-1 rounded-lg min-h-[1.75rem] flex items-center transition-colors">
                {{ formatCurrency(card.value, card.currency) }}
              </div>
              <div v-else class="flex items-center space-x-1.5">
                <span class="text-xs font-bold text-slate-400">R$</span>
                <input
                  v-model.number="editingValue"
                  @blur="saveValue"
                  @keyup.enter="saveValue"
                  type="number"
                  autofocus
                  class="text-xs font-semibold text-slate-850 w-full border border-slate-200 focus:outline-none focus:border-slate-800 rounded-xl px-2.5 py-1 bg-white"
                />
              </div>
            </div>

            <!-- Dados do Contato Principal -->
            <div class="space-y-3">
              <div class="flex items-center justify-between pb-1">
                <h3 class="text-xs font-bold text-slate-850 uppercase tracking-wider">Contato Principal</h3>
                <span v-if="contactSaveStatus" class="text-[9px] font-bold text-emerald-600 bg-emerald-50 px-2 py-0.5 rounded-full">
                  {{ contactSaveStatus }}
                </span>
              </div>
              
              <div class="border-b border-slate-100 pb-3 mb-3">
                <label class="text-[10px] font-bold text-slate-400 uppercase block">Nome</label>
                <div v-if="!isEditingContactName" @click="isEditingContactName = true" class="text-xs font-semibold text-slate-850 cursor-pointer hover:bg-slate-100/60 px-2 py-1 rounded-lg min-h-[1.75rem] flex items-center transition-colors">
                  {{ card.contact_name || 'Não informado (clique para editar)' }}
                </div>
                <input
                  v-else
                  v-model="editingContactName"
                  @blur="saveContactName"
                  @keyup.enter="saveContactName"
                  type="text"
                  autofocus
                  class="text-xs font-semibold text-slate-850 w-full border border-slate-200 focus:outline-none focus:border-slate-800 rounded-xl px-2.5 py-1 bg-white"
                />
              </div>

              <div class="border-b border-slate-100 pb-3 mb-3">
                <label class="text-[10px] font-bold text-slate-400 uppercase block">Telefone</label>
                <div v-if="!isEditingContactPhone" @click="isEditingContactPhone = true" class="text-xs font-semibold text-slate-850 cursor-pointer hover:bg-slate-100/60 px-2 py-1 rounded-lg min-h-[1.75rem] flex items-center justify-between transition-colors group/phone">
                  <span>{{ card.contact_phone || 'Não informado (clique para editar)' }}</span>
                  <button @click.stop="addSecondaryPhone" class="p-1 opacity-0 group-hover/phone:opacity-100 hover:bg-slate-200 rounded text-slate-500 transition-all" title="Adicionar telefone secundário">
                    <component :is="Plus" class="h-3 w-3" />
                  </button>
                </div>
                <input
                  v-else
                  v-model="editingContactPhone"
                  @blur="saveContactPhone"
                  @keyup.enter="saveContactPhone"
                  type="text"
                  autofocus
                  class="text-xs font-semibold text-slate-850 w-full border border-slate-200 focus:outline-none focus:border-slate-800 rounded-xl px-2.5 py-1 bg-white"
                />
              </div>

              <div class="border-b border-slate-100 pb-3 mb-3">
                <label class="text-[10px] font-bold text-slate-400 uppercase block">E-mail</label>
                <div v-if="!isEditingContactEmail" @click="isEditingContactEmail = true" class="text-xs font-semibold text-slate-850 cursor-pointer hover:bg-slate-100/60 px-2 py-1 rounded-lg min-h-[1.75rem] flex items-center justify-between transition-colors group/email">
                  <span class="break-all">{{ card.contact_email || 'Não informado (clique para editar)' }}</span>
                  <button @click.stop="addSecondaryEmail" class="p-1 opacity-0 group-hover/email:opacity-100 hover:bg-slate-200 rounded text-slate-500 transition-all" title="Adicionar e-mail secundário">
                    <component :is="Plus" class="h-3 w-3" />
                  </button>
                </div>
                <input
                  v-else
                  v-model="editingContactEmail"
                  @blur="saveContactEmail"
                  @keyup.enter="saveContactEmail"
                  type="email"
                  autofocus
                  class="text-xs font-semibold text-slate-850 w-full border border-slate-200 focus:outline-none focus:border-slate-800 rounded-xl px-2.5 py-1 bg-white"
                />
              </div>
            </div>
            
            <!-- Canal de Comunicação -->
            <div class="border-t border-slate-100 pt-4 mt-4">
              <h3 class="text-xs font-bold text-slate-850 uppercase tracking-wider mb-2">Canal de Comunicação</h3>
              
              <div v-if="card.whatsapp_instance" class="space-y-1">
                <div class="flex items-center space-x-1.5 text-xs font-semibold text-slate-800">
                  <span>📱</span>
                  <span>{{ formatPhone(card.whatsapp_instance.phone || card.whatsapp_instance.phone_number) }}</span>
                </div>
                
                <div class="flex items-center space-x-1.5 pl-5 text-[11px] text-slate-500">
                  <span v-if="card.whatsapp_instance.name" class="font-medium">{{ card.whatsapp_instance.name }}</span>
                  <span v-if="card.whatsapp_instance.name">•</span>
                  <div class="flex items-center space-x-1">
                    <span 
                      class="w-2 h-2 rounded-full inline-block"
                      :class="card.whatsapp_instance.status === 'connected' ? 'bg-green-500' : 'bg-red-500'"
                    ></span>
                    <span :class="card.whatsapp_instance.status === 'connected' ? 'text-green-700' : 'text-red-500 font-semibold'">
                      {{ card.whatsapp_instance.status === 'connected' ? 'Conectado' : 'Desconectado' }}
                    </span>
                  </div>
                </div>
              </div>
              
              <div v-else class="text-xs text-slate-400 italic pl-1">
                Canal não definido
              </div>
            </div>
          </div>

          <!-- TAB 2: CAMPOS PERSONALIZADOS (TIPADOS) -->
          <div v-else-if="activeTab === 'campos'" class="space-y-4 flex-1">
            <div class="flex items-center justify-between">
              <h3 class="text-xs font-bold text-gray-800 uppercase tracking-wider">Campos Definidos</h3>
              <span v-if="saveStatus" class="text-[10px] font-bold flex items-center transition-all">
                <span v-if="saveStatus === 'salvando'" class="text-slate-500 flex items-center">
                  <svg class="animate-spin h-3 w-3 mr-1 text-slate-500" fill="none" viewBox="0 0 24 24">
                    <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                    <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                  </svg>
                  Salvando...
                </span>
                <span v-else-if="saveStatus === 'salvo'" class="text-emerald-600 flex items-center">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M5 13l4 4L19 7" />
                  </svg>
                  Salvo
                </span>
              </span>
            </div>

            <!-- Lista de Campos Baseados nas Definições do Funil -->
            <div class="space-y-3 pt-2">
              <div 
                v-for="field in pipelineStore.customFields" 
                :key="field.id"
                class="border-b border-slate-100 pb-3 mb-3"
              >
                <label class="text-[10px] font-bold text-slate-400 uppercase tracking-wider block mb-1">{{ field.name }}</label>
                
                <!-- Tipo: text -->
                <input 
                  v-if="field.field_type === 'text'"
                  v-model="localCustomFields[field.name]"
                  type="text"
                  @blur="triggerAutoSave"
                  class="block w-full px-2.5 py-1 rounded-xl border border-slate-200 focus:outline-none focus:border-slate-800 text-xs text-slate-850 transition-all bg-white"
                  placeholder="Preencher texto..."
                />

                <!-- Tipo: number -->
                <input 
                  v-else-if="field.field_type === 'number'"
                  v-model.number="localCustomFields[field.name]"
                  type="number"
                  @blur="triggerAutoSave"
                  class="block w-full px-2.5 py-1 rounded-xl border border-slate-200 focus:outline-none focus:border-slate-800 text-xs text-slate-850 transition-all bg-white"
                  placeholder="0"
                />

                <!-- Tipo: select -->
                <select 
                  v-else-if="field.field_type === 'select'"
                  v-model="localCustomFields[field.name]"
                  @change="triggerAutoSave"
                  class="block w-full px-2.5 py-1 rounded-xl border border-slate-200 focus:outline-none focus:border-slate-800 text-xs text-slate-850 transition-all bg-white"
                >
                  <option :value="undefined">Selecione...</option>
                  <option v-for="opt in field.options" :key="opt" :value="opt">{{ opt }}</option>
                </select>

                <!-- Tipo: boolean (Toggle Switch ou Checkbox) -->
                <div v-else-if="field.field_type === 'boolean'" class="flex items-center space-x-2 py-1">
                  <input 
                    v-model="localCustomFields[field.name]"
                    type="checkbox"
                    @change="triggerAutoSave"
                    class="h-4 w-4 rounded border-gray-300 text-slate-900 focus:ring-slate-900"
                  />
                  <span class="text-xs text-gray-650 font-semibold">Sim / Confirmado</span>
                </div>

                <!-- Tipo: date -->
                <input 
                  v-else-if="field.field_type === 'date'"
                  v-model="localCustomFields[field.name]"
                  type="date"
                  @change="triggerAutoSave"
                  class="block w-full px-2.5 py-1 rounded-xl border border-slate-200 focus:outline-none focus:border-slate-800 text-xs text-slate-850 transition-all bg-white"
                />
              </div>

              <!-- Lista vazia state -->
              <div v-if="pipelineStore.customFields.length === 0" class="text-center py-8 text-xs text-gray-400 italic">
                Nenhum campo personalizado definido para este funil nas configurações.
              </div>
            </div>
          </div>

          <!-- TAB 3: HISTÓRICO DE EVENTOS -->
          <div v-else-if="activeTab === 'historico'" class="space-y-3.5 flex-1 overflow-y-auto">
            <h3 class="text-xs font-bold text-gray-800 uppercase tracking-wider mb-2">Auditoria do Lead</h3>
            
            <div class="space-y-3 max-h-[400px] overflow-y-auto pr-1">
              <div 
                v-for="event in systemEvents" 
                :key="event.id" 
                class="p-3 bg-white rounded-2xl border border-gray-150 shadow-sm space-y-1.5 transition-all"
              >
                <div class="flex items-center space-x-2 text-[9px] text-gray-400 font-bold uppercase tracking-wider">
                  <component :is="getEventIcon(event.event_type)" class="h-3.5 w-3.5 text-gray-400" />
                  <span>{{ formatFriendlyDate(event.created_at) }}</span>
                </div>
                <p class="text-xs text-slate-750 font-semibold leading-normal">{{ event.description }}</p>
                <p v-if="event.user" class="text-[9px] text-gray-400 font-semibold">Alterado por: {{ event.user.name }}</p>
              </div>
              
              <div v-if="systemEvents.length === 0" class="text-center py-10 text-xs text-gray-400 italic">
                Nenhum histórico registrado no sistema.
              </div>
            </div>
          </div>

        </aside>

        <!-- Coluna Direita / Centro: Timeline de Atividades / WhatsApp Chat -->
        <section class="flex-1 flex flex-col bg-slate-50/50 overflow-hidden">
          <!-- Filtro de Abas no Topo do Chat (WhatsApp, Nota Interna, Histórico) -->
          <div class="h-11 px-6 border-b border-gray-100 flex items-center space-x-5 bg-white shrink-0">
            <button 
              v-for="tab in ['whatsapp', 'notes', 'history']" 
              :key="tab"
              @click="rightActiveTab = tab"
              class="h-full border-b-2 text-xs font-bold transition-all px-1 focus:outline-none"
              :class="rightActiveTab === tab ? 'border-slate-900 text-slate-900' : 'border-transparent text-gray-400 hover:text-gray-600'"
            >
              {{ tab === 'whatsapp' ? 'WhatsApp' : tab === 'notes' ? 'Nota Interna' : 'Histórico' }}
            </button>
          </div>

          <!-- Area de Mensagens / Chat -->
          <div 
            ref="timelineContainer" 
            class="flex-1 overflow-y-auto p-6 space-y-6 scroll-smooth flex flex-col"
          >
            <!-- Loader da Timeline -->
            <div v-if="pipelineStore.loading.timeline && pipelineStore.cardTimeline.length === 0" class="space-y-4">
              <div v-for="i in 3" :key="i" class="h-20 bg-white border border-gray-150 rounded-2xl animate-pulse"></div>
            </div>

            <!-- Se a timeline filtrada estiver vazia -->
            <div v-else-if="filteredTimelineEvents.length === 0" class="h-full flex flex-col items-center justify-center text-center text-sm text-gray-455 py-12 flex-1">
              <component :is="MessageSquare" class="h-10 w-10 text-gray-300 mb-2" />
              <template v-if="rightActiveTab === 'whatsapp'">
                <span class="font-bold text-gray-700 block mb-1">Nenhuma mensagem ainda</span>
                <span class="text-xs text-gray-400">As mensagens aparecerão aqui quando o contato enviar via WhatsApp</span>
              </template>
              <template v-else-if="rightActiveTab === 'notes'">
                <span class="font-bold text-gray-700 block mb-1">Nenhuma nota interna registrada</span>
                <span class="text-xs text-gray-400">Escreva uma nota interna no compositor abaixo para guardar lembretes</span>
              </template>
              <template v-else>
                <span class="font-bold text-gray-700 block mb-1">Nenhum evento registrado</span>
                <span class="text-xs text-gray-400">O histórico de auditoria de etapas e criação aparecerá aqui</span>
              </template>
            </div>

            <!-- Lista Agrupada por Data -->
            <div v-else class="space-y-6">
              <div 
                v-for="group in groupedTimeline" 
                :key="group.date"
                class="space-y-4"
              >
                <!-- Separador de data do chat -->
                <div class="flex justify-center my-4">
                  <span class="px-3 py-1 bg-gray-200/80 text-gray-600 rounded-full text-[10px] font-bold tracking-wide shadow-sm">
                    {{ group.date }}
                  </span>
                </div>

                <!-- Feed do Chat/Eventos -->
                <div class="space-y-3">
                  <template v-for="event in group.events" :key="event.id">
                    <!-- 1. Renderização de Mensagens (Tipo = message) -->
                    <div 
                      v-if="event.event_type === 'message'"
                      class="flex w-full animate-fade-in"
                      :class="[
                        event.message_type === 'outgoing' 
                          ? 'justify-end' 
                          : (event.message_type === 'private' ? 'justify-center' : 'justify-start')
                      ]"
                    >
                      <!-- Bolha de Mensagem Outgoing (Enviada pelo Agente Zavy) -->
                      <div 
                        v-if="event.message_type === 'outgoing'"
                        class="max-w-[70%] flex flex-col items-end space-y-1 relative group"
                      >
                        <!-- Botão Responder para Outgoing -->
                        <button 
                          @click="triggerReply(event)"
                          class="opacity-0 group-hover:opacity-100 absolute left-[-32px] top-1/2 -translate-y-1/2 p-1.5 hover:bg-slate-200 rounded-lg text-slate-400 hover:text-slate-600 transition-all select-none"
                          title="Responder"
                        >
                          <component :is="CornerUpLeft" class="h-3.5 w-3.5" />
                        </button>

                        <div class="flex items-center space-x-1.5 text-[9px] font-bold text-slate-400 pr-1 select-none">
                          <span>{{ getSenderDisplayName(event) }}</span>
                          <span>{{ formatTimeOnly(event.created_at) }}</span>
                          <span class="text-emerald-500 font-bold">✓✓</span>
                        </div>
                        <div class="bg-slate-900 text-white rounded-2xl rounded-tr-none px-4 py-2.5 shadow-sm text-left w-full">
                          <!-- Quote/Reply Reference -->
                          <div v-if="event.in_reply_to" class="mb-2">
                            <div class="text-[10px] bg-slate-800 border-l-2 border-slate-500 px-2 py-1 rounded text-slate-350">
                              <span class="font-bold text-slate-400">Respondendo a:</span>
                              <span class="italic block truncate">"{{ getQuotePreview(event.in_reply_to) }}"</span>
                            </div>
                          </div>

                          <!-- Exibição de Anexos -->
                          <div v-if="event.attachments && event.attachments.length > 0" class="mb-2 space-y-2">
                            <div v-for="(att, attIdx) in event.attachments" :key="event.id + '-att-' + attIdx">
                              <!-- Imagem: preview inline -->
                              <div v-if="isImage(att)" class="my-1 cursor-pointer" @click="openLightbox(att.url)">
                                <img :src="att.url" 
                                     :alt="att.filename"
                                     class="max-w-[200px] max-h-[200px] rounded-lg object-cover hover:opacity-90 transition-opacity"
                                     @error="handleImageError($event)" />
                              </div>

                              <!-- Vídeo: player inline -->
                              <div v-else-if="isVideo(att)" class="my-1">
                                <video controls class="max-w-[240px] max-h-[240px] rounded-lg">
                                  <source :src="att.url" :type="att.content_type || 'video/mp4'" />
                                </video>
                              </div>

                              <!-- Áudio: player inline customizado -->
                              <div v-else-if="isAudio(att)" class="my-1.5 w-full">
                                <AudioPlayer 
                                  :audio-url="att.url"
                                  :is-outgoing="true"
                                  :transcription="getTranscription(event)"
                                  :message-id="event.id"
                                />
                              </div>

                              <!-- Documento: ícone + nome + link para download/visualização -->
                              <a v-else :href="att.url" target="_blank"
                                 class="flex items-center justify-between gap-3 p-3 bg-slate-800 border border-slate-700/60 rounded-xl hover:bg-slate-750 transition-colors w-full max-w-[280px]">
                                <div class="flex items-center gap-2 min-w-0">
                                  <span class="text-lg shrink-0">📄</span>
                                  <div class="min-w-0">
                                    <p class="text-xs text-white font-bold truncate">{{ att.filename || 'Arquivo' }}</p>
                                    <p class="text-[9px] text-slate-300 font-bold">{{ formatSize(att.size) }}</p>
                                  </div>
                                </div>
                                <span class="text-[10px] font-black text-white bg-slate-700 border border-slate-600 px-2 py-1 rounded-lg uppercase tracking-wider hover:bg-slate-650 shrink-0">
                                  Abrir
                                </span>
                              </a>
                            </div>
                          </div>
                          <p v-if="shouldShowContent(event)" class="text-xs leading-relaxed whitespace-pre-wrap">{{ event.content }}</p>
                        </div>
                      </div>

                      <!-- Bolha de Mensagem Incoming (Recebida do Cliente) -->
                      <div 
                        v-else-if="event.message_type === 'incoming'"
                        class="max-w-[70%] flex flex-col items-start space-y-1 relative group"
                      >
                        <!-- Botão Responder para Incoming -->
                        <button 
                          @click="triggerReply(event)"
                          class="opacity-0 group-hover:opacity-100 absolute right-[-32px] top-1/2 -translate-y-1/2 p-1.5 hover:bg-slate-200 rounded-lg text-slate-400 hover:text-slate-600 transition-all select-none"
                          title="Responder"
                        >
                          <component :is="CornerUpLeft" class="h-3.5 w-3.5" />
                        </button>

                        <div class="flex items-center space-x-1.5 text-[9px] font-bold text-zavy-600 pl-1 select-none">
                          <span>{{ event.sender_name || card?.contact_name || 'Cliente' }}</span>
                          <span class="text-slate-450">{{ formatTimeOnly(event.created_at) }}</span>
                        </div>
                        <div class="bg-white border border-slate-200 text-slate-800 rounded-2xl rounded-tl-none px-4 py-2.5 shadow-sm text-left w-full">
                          <!-- Quote/Reply Reference -->
                          <div v-if="event.in_reply_to" class="mb-2">
                            <div class="text-[10px] bg-slate-100 border-l-2 border-slate-300 px-2 py-1 rounded text-slate-600">
                              <span class="font-bold text-slate-400">Respondendo a:</span>
                              <span class="italic block truncate">"{{ getQuotePreview(event.in_reply_to) }}"</span>
                            </div>
                          </div>

                          <!-- Exibição de Anexos -->
                          <div v-if="event.attachments && event.attachments.length > 0" class="mb-2 space-y-2">
                            <div v-for="(att, attIdx) in event.attachments" :key="event.id + '-att-' + attIdx">
                              <!-- Imagem: preview inline -->
                              <div v-if="isImage(att)" class="my-1 cursor-pointer" @click="openLightbox(att.url)">
                                <img :src="att.url" 
                                     :alt="att.filename"
                                     class="max-w-[200px] max-h-[200px] rounded-lg object-cover hover:opacity-90 transition-opacity"
                                     @error="handleImageError($event)" />
                              </div>

                              <!-- Vídeo: player inline -->
                              <div v-else-if="isVideo(att)" class="my-1">
                                <video controls class="max-w-[240px] max-h-[240px] rounded-lg">
                                  <source :src="att.url" :type="att.content_type || 'video/mp4'" />
                                </video>
                              </div>

                              <!-- Áudio: player inline customizado -->
                              <div v-else-if="isAudio(att)" class="my-1.5 w-full">
                                <AudioPlayer 
                                  :audio-url="att.url"
                                  :is-outgoing="false"
                                  :transcription="getTranscription(event)"
                                  :message-id="event.id"
                                />
                              </div>

                              <!-- Documento: ícone + nome + link para download/visualização -->
                              <a v-else :href="att.url" target="_blank"
                                 class="flex items-center justify-between gap-3 p-3 bg-slate-50 border border-slate-200/60 rounded-xl hover:bg-slate-100 transition-colors w-full max-w-[280px]">
                                <div class="flex items-center gap-2 min-w-0">
                                  <span class="text-lg shrink-0">📄</span>
                                  <div class="min-w-0">
                                    <p class="text-xs text-slate-850 font-bold truncate">{{ att.filename || 'Arquivo' }}</p>
                                    <p class="text-[9px] text-slate-400 font-bold">{{ formatSize(att.size) }}</p>
                                  </div>
                                </div>
                                <span class="text-[10px] font-black text-zavy-600 bg-zavy-50 border border-zavy-200 px-2 py-1 rounded-lg uppercase tracking-wider hover:bg-zavy-150 shrink-0">
                                  Abrir
                                </span>
                              </a>
                            </div>
                          </div>
                          <p v-if="shouldShowContent(event)" class="text-xs leading-relaxed whitespace-pre-wrap">{{ event.content }}</p>
                        </div>
                      </div>

                      <!-- Bolha de Nota Interna (Privada) -->
                      <div 
                        v-else-if="event.message_type === 'private'"
                        class="max-w-[85%] bg-amber-50 border border-amber-200 text-amber-900 rounded-2xl px-4 py-3 shadow-inner space-y-1.5 text-left w-full mx-6"
                      >
                        <div class="flex items-center justify-between">
                          <span class="text-[9px] font-bold uppercase tracking-wider text-amber-700 flex items-center space-x-1">
                            <span class="w-1.5 h-1.5 rounded-full bg-amber-500"></span>
                            <span>Nota Interna</span>
                          </span>
                          <span class="text-[9px] text-amber-600 font-medium">{{ formatTimeOnly(event.created_at) }}</span>
                        </div>
                        <p class="text-xs leading-relaxed whitespace-pre-wrap">{{ event.content }}</p>
                        <div class="text-[9px] text-amber-600 font-semibold flex items-center space-x-1">
                          <span>Por: {{ event.user?.name || 'Agente' }}</span>
                        </div>
                      </div>
                    </div>

                    <!-- 2. Renderização de Eventos de Sistema (Criado, Movido, Atualizado) -->
                    <div v-else class="flex justify-center my-2.5">
                      <span class="px-3.5 py-1 bg-gray-200/50 text-gray-500 rounded-full text-[10px] font-semibold flex items-center space-x-1.5 border border-gray-150/40">
                        <component :is="getEventIcon(event.event_type)" class="h-3 w-3 shrink-0 text-gray-400" />
                        <span>{{ event.description }}</span>
                        <span v-if="event.user" class="text-gray-400 font-medium">• por {{ event.user.name }}</span>
                        <span class="text-gray-400 font-medium">• {{ formatTimeOnly(event.created_at) }}</span>
                      </span>
                    </div>
                  </template>
                </div>
              </div>
            </div>
          </div>

          <!-- Banner de erro do WhatsApp -->
          <div 
            v-if="isWhatsappUnavailableError" 
            class="mx-4 mt-2 p-3 bg-rose-50 border border-rose-200 rounded-xl flex items-start justify-between shadow-sm animate-scale-up"
          >
            <div class="flex items-start space-x-2">
              <span class="text-rose-500 shrink-0 text-sm mt-0.5">⚠️</span>
              <div class="text-xs text-rose-800 font-semibold leading-normal">
                {{ lastErrorMessage || 'WhatsApp desconectado. Reconecte para enviar.' }}
              </div>
            </div>
            <router-link 
              to="/settings/whatsapp" 
              class="shrink-0 text-xs font-black text-rose-600 hover:text-rose-800 hover:underline flex items-center space-x-1 pl-3 whitespace-nowrap"
            >
              <span>Ir para conexões</span>
              <span>→</span>
            </router-link>
          </div>

          <!-- Compositor de Mensagens / Notas -->
          <CardComposer 
            :card="card" 
            :replying-to="replyingTo"
            @message-sent="onMessageSent" 
            @cancel-reply="cancelReply"
            @whatsapp-error="handleWhatsappError"
          />
        </section>
      </div>

      <!-- Loader caso o card esteja sendo carregado -->
      <div v-else class="flex-1 flex items-center justify-center">
        <span class="text-sm text-gray-500">Buscando informações do card...</span>
      </div>
    </div>

    <!-- Modal de preview (quando clica na imagem) -->
    <div v-if="lightboxUrl" class="fixed inset-0 z-[100] bg-black/80 flex items-center justify-center cursor-pointer" @click="lightboxUrl = null">
      <img :src="lightboxUrl" class="max-w-[90vw] max-h-[90vh] rounded-lg shadow-2xl" />
      <button class="absolute top-4 right-4 text-white text-3xl font-bold select-none hover:text-gray-300" @click="lightboxUrl = null">✕</button>
    </div>

    <!-- Modal de Motivo de Perda interno do detalhe -->
    <LossReasonModal
      :show="showLossModal"
      :card-title="card?.title"
      :loss-reasons="lossReasons"
      @confirm="handleConfirmLoss"
      @cancel="handleCancelLoss"
    />
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted, watch, nextTick } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { usePipelineStore } from '@/stores/pipeline'
import { useAuthStore } from '@/stores/auth'
import { usePipelineSocket } from '@/composables/usePipelineSocket'
import StageSwitcher from './StageSwitcher.vue'
import LossReasonModal from './LossReasonModal.vue'
import CardComposer from './CardComposer.vue'
import AudioPlayer from './AudioPlayer.vue'
import { X, Plus, MoveRight, HelpCircle, FileText, Send, MessageSquare, CornerUpLeft } from 'lucide-vue-next'
import api from '@/plugins/axios'

const route = useRoute()
const router = useRouter()
const pipelineStore = usePipelineStore()
const authStore = useAuthStore()

const cardId = computed(() => Number(route.params.cardId))
const activeTab = ref('dados')
const rightActiveTab = ref('whatsapp') // 'whatsapp', 'notes', 'history'

// Reply/Quote states
const replyingTo = ref(null)

const triggerReply = (msg) => {
  replyingTo.value = {
    id: msg.payload?.chatwoot_msg_id || msg.payload?.message_id || msg.chatwoot_message_id || msg.id,
    content: msg.content?.substring(0, 100),
    sender_name: msg.sender_name || msg.payload?.sender_name || (msg.message_type === 'outgoing' ? 'Você' : 'Cliente')
  }
}

const cancelReply = () => {
  replyingTo.value = null
}

const isWhatsappUnavailableError = ref(false)
const lastErrorMessage = ref('')

const handleWhatsappError = (err) => {
  isWhatsappUnavailableError.value = true
  lastErrorMessage.value = err.message
}

const onMessageSent = () => {
  replyingTo.value = null
  isWhatsappUnavailableError.value = false
  lastErrorMessage.value = ''
  scrollToBottom()
}

const getSenderDisplayName = (event) => {
  const name = event.user?.name || event.sender_name
  if (!name) return 'Você'
  if (authStore.user?.name && name.toLowerCase() === authStore.user.name.toLowerCase()) {
    return 'Você'
  }
  return name
}

const card = computed(() => {
  return pipelineStore.cards.find(c => c.id === cardId.value)
})

// Modal de perda e estágio pendente
const showLossModal = ref(false)
const pendingStageChange = ref(null)

const pendingStage = computed(() => {
  if (!pendingStageChange.value) return null
  return pipelineStore.stages.find(s => s.id === pendingStageChange.value)
})

const lossReasons = computed(() => {
  return pendingStage.value?.loss_reasons || []
})

// Estados locais de edição inline com auto-save no blur
const isEditingTitle = ref(false)
const editingTitle = ref('')
const isEditingValue = ref(false)
const editingValue = ref(0)
const isEditingContactName = ref(false)
const editingContactName = ref('')
const isEditingContactPhone = ref(false)
const editingContactPhone = ref('')
const isEditingContactEmail = ref(false)
const editingContactEmail = ref('')

const contactSaveStatus = ref('') // 'salvando', 'salvo', ''

// --- LÓGICA DE CAMPOS PERSONALIZADOS ---
const localCustomFields = ref({})
const saveStatus = ref('') // '', 'salvando', 'salvo'

const formatCurrency = (value, currency = 'BRL') => {
  if (value === undefined || value === null) return 'R$ 0,00'
  return new Intl.NumberFormat('pt-BR', {
    style: 'currency',
    currency: currency
  }).format(value)
}

// Retorna ícone conforme o tipo de evento
const getEventIcon = (type) => {
  switch (type) {
    case 'card_created': return Plus
    case 'card_moved': return MoveRight
    case 'card_updated': return FileText
    default: return HelpCircle
  }
}

// Sincroniza estados de edição com o card ativo
watch(() => card.value, (newCard) => {
  if (newCard) {
    if (!isEditingTitle.value) editingTitle.value = newCard.title || ''
    if (!isEditingValue.value) editingValue.value = newCard.value || 0
    if (!isEditingContactName.value) editingContactName.value = newCard.contact_name || ''
    if (!isEditingContactPhone.value) editingContactPhone.value = newCard.contact_phone || ''
    if (!isEditingContactEmail.value) editingContactEmail.value = newCard.contact_email || ''
    
    localCustomFields.value = { ...newCard.custom_fields }
  }
}, { immediate: true, deep: true })

// Ações de salvamento inline
const saveTitle = async () => {
  isEditingTitle.value = false
  const trimmed = editingTitle.value.trim()
  if (trimmed && trimmed !== card.value.title) {
    showContactSaving()
    await pipelineStore.updateCard(cardId.value, { title: trimmed })
    hideContactSaving()
  }
}

const saveValue = async () => {
  isEditingValue.value = false
  const val = Number(editingValue.value)
  if (!isNaN(val) && val !== card.value.value) {
    showContactSaving()
    await pipelineStore.updateCard(cardId.value, { value: val })
    hideContactSaving()
  }
}

const saveContactName = async () => {
  isEditingContactName.value = false
  const trimmed = editingContactName.value.trim()
  if (trimmed !== card.value.contact_name) {
    showContactSaving()
    await pipelineStore.updateCard(cardId.value, { contact_name: trimmed })
    hideContactSaving()
  }
}

const saveContactPhone = async () => {
  isEditingContactPhone.value = false
  const trimmed = editingContactPhone.value.trim()
  if (trimmed !== card.value.contact_phone) {
    showContactSaving()
    await pipelineStore.updateCard(cardId.value, { contact_phone: trimmed })
    hideContactSaving()
  }
}

const saveContactEmail = async () => {
  isEditingContactEmail.value = false
  const trimmed = editingContactEmail.value.trim()
  if (trimmed !== card.value.contact_email) {
    showContactSaving()
    await pipelineStore.updateCard(cardId.value, { contact_email: trimmed })
    hideContactSaving()
  }
}

const showContactSaving = () => {
  contactSaveStatus.value = 'salvando...'
}

const hideContactSaving = () => {
  contactSaveStatus.value = 'salvo!'
  setTimeout(() => {
    contactSaveStatus.value = ''
  }, 1500)
}

// Simuladores de telefones/emails múltiplos
const addSecondaryPhone = () => {
  const phone = prompt('Digite o telefone secundário:')
  if (phone && phone.trim()) {
    const key = `Telefone ${Object.keys(localCustomFields.value).filter(k => k.startsWith('Telefone')).length + 2}`
    localCustomFields.value[key] = phone.trim()
    triggerAutoSave()
    toastInfo(`Telefone secundário cadastrado em ${key}`)
  }
}

const addSecondaryEmail = () => {
  const email = prompt('Digite o e-mail secundário:')
  if (email && email.trim()) {
    const key = `E-mail ${Object.keys(localCustomFields.value).filter(k => k.startsWith('E-mail')).length + 2}`
    localCustomFields.value[key] = email.trim()
    triggerAutoSave()
    toastInfo(`E-mail secundário cadastrado em ${key}`)
  }
}

const toastInfo = (msg) => {
  // Dispara evento global de toast se tiver
  console.log('Zavy CRM Event:', msg)
}

const closeDetail = () => {
  router.push({
    name: 'pipelines-detail',
    params: { id: route.params.id }
  })
}

// Gerencia mudança de etapa via switcher
const handleStageChange = async (targetStageId) => {
  if (!card.value) return
  const targetStage = pipelineStore.stages.find(s => s.id === targetStageId)

  if (targetStage && targetStage.stage_type === 'lose') {
    pendingStageChange.value = targetStageId
    showLossModal.value = true
  } else {
    try {
      await pipelineStore.moveCard(card.value.id, card.value.stage_id, targetStageId, 0)
      // Atualiza a timeline após mover
      await pipelineStore.fetchCardTimeline(route.params.id, cardId.value)
    } catch (error) {
      // Rollback na store
    }
  }
}

// Confirma perda do lead e atualiza a timeline
const handleConfirmLoss = async (reason) => {
  if (!card.value || !pendingStageChange.value) return
  const targetStageId = pendingStageChange.value
  showLossModal.value = false

  try {
    await pipelineStore.moveCard(card.value.id, card.value.stage_id, targetStageId, 0)
    
    // Atualiza justificativa nos custom fields
    const cardIdx = pipelineStore.cards.findIndex(c => c.id === card.value.id)
    if (cardIdx !== -1) {
      if (!pipelineStore.cards[cardIdx].custom_fields) {
        pipelineStore.cards[cardIdx].custom_fields = {}
      }
      pipelineStore.cards[cardIdx].custom_fields['Motivo da Perda'] = reason
    }

    // Atualiza a timeline
    await pipelineStore.fetchCardTimeline(route.params.id, cardId.value)
  } catch (error) {
    // Rollback na store
  } finally {
    pendingStageChange.value = null
  }
}

const handleCancelLoss = () => {
  showLossModal.value = false
  pendingStageChange.value = null
}

// Instancia o socket para tempo real
const socket = usePipelineSocket()
const timelineContainer = ref(null)

const loadTimeline = async () => {
  if (route.params.id && cardId.value) {
    await pipelineStore.fetchCardTimeline(route.params.id, cardId.value)
    scrollToBottom()
  }
}

const loadCustomFieldDefinitions = async () => {
  if (route.params.id) {
    await pipelineStore.fetchCustomFields(Number(route.params.id))
  }
}

// Escuta teclado Esc para fechar
const handleKeyDown = (e) => {
  if (e.key === 'Escape') {
    closeDetail()
  }
}

const onNewMessageReceived = () => {
  scrollToBottom()
}

let pollInterval = null

onMounted(() => {
  window.addEventListener('keydown', handleKeyDown)
  loadTimeline()
  loadCustomFieldDefinitions()
  
  if (route.params.id && cardId.value) {
    pipelineStore.fetchCardDetail(route.params.id, cardId.value)
  }

  // Conecta ao ActionCable via WebSocket para updates em tempo real
  if (route.params.id) {
    socket.connect(route.params.id, cardId.value)
  }

  // Escuta evento customizado de nova mensagem para fazer scroll
  window.addEventListener('zavy-new-message', onNewMessageReceived)

  // Polling incremental a cada 5 segundos para garantir atualização em tempo real sem piscar a tela
  pollInterval = setInterval(async () => {
    if (route.params.id && cardId.value) {
      try {
        const response = await api.get(`/api/v1/pipelines/${route.params.id}/cards/${cardId.value}/timeline`)
        const newItems = response.data.data || response.data
        
        // Deep compare timeline items to prevent useless state mutation & flickering
        const isChanged = newItems.length !== pipelineStore.cardTimeline.length ||
                          newItems.some((item, idx) => {
                            const oldItem = pipelineStore.cardTimeline[idx]
                            return !oldItem || 
                                   oldItem.id !== item.id || 
                                   oldItem.created_at !== item.created_at ||
                                   oldItem.event_type !== item.event_type ||
                                   JSON.stringify(oldItem.payload) !== JSON.stringify(item.payload)
                          })
        
        if (isChanged) {
          pipelineStore.cardTimeline = newItems
        }
      } catch (e) {
        console.error("Erro no polling de timeline:", e)
      }
    }
  }, 5000)
})

onUnmounted(() => {
  window.removeEventListener('keydown', handleKeyDown)
  window.removeEventListener('zavy-new-message', onNewMessageReceived)
  socket.disconnect()
  if (pollInterval) {
    clearInterval(pollInterval)
  }
})

watch(() => cardId.value, (newCardId) => {
  if (newCardId) {
    isWhatsappUnavailableError.value = false
    lastErrorMessage.value = ''
    
    // Conecta novamente o socket
    socket.disconnect()
    if (route.params.id) {
      socket.connect(route.params.id, newCardId)
    }
    
    // Recarrega os dados
    loadTimeline()
    loadCustomFieldDefinitions()
    if (route.params.id) {
      pipelineStore.fetchCardDetail(route.params.id, newCardId)
    }
  }
})

const formatPhone = (phone) => {
  if (!phone) return '—'
  const clean = String(phone).replace(/\D/g, '')
  // Formato brasileiro: +55 XX XXXXX-XXXX
  if (clean.length === 13) {
    return `+${clean.slice(0,2)} ${clean.slice(2,4)} ${clean.slice(4,9)}-${clean.slice(9)}`
  }
  if (clean.length === 12) {
    return `+${clean.slice(0,2)} ${clean.slice(2,4)} ${clean.slice(4,8)}-${clean.slice(8)}`
  }
  return phone.startsWith('+') ? phone : `+${clean}`
}

const scrollToBottom = () => {
  nextTick(() => {
    if (timelineContainer.value) {
      timelineContainer.value.scrollTop = timelineContainer.value.scrollHeight
    }
  })
}

// Rola para baixo apenas quando novas mensagens/eventos forem adicionados
watch(() => pipelineStore.cardTimeline.length, (newVal, oldVal) => {
  if (newVal > oldVal) {
    scrollToBottom()
  }
})

// Extrai a hora, minuto e segundo formatados (HH:MM:SS)
const formatTimeOnly = (isoString) => {
  if (!isoString) return ''
  const date = new Date(isoString)
  const hours = date.getHours().toString().padStart(2, '0')
  const minutes = date.getMinutes().toString().padStart(2, '0')
  const seconds = date.getSeconds().toString().padStart(2, '0')
  return `${hours}:${minutes}:${seconds}`
}

// Formatador amigável de datas
const formatFriendlyDate = (isoString) => {
  if (!isoString) return ''
  const date = new Date(isoString)
  return date.toLocaleDateString('pt-BR') + ' às ' + date.toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' })
}

const openFullscreen = (url) => {
  window.open(url, '_blank')
}

const lightboxUrl = ref(null)
const openLightbox = (url) => {
  lightboxUrl.value = url
}

const handleImageError = (e) => {
  console.error('Erro ao carregar imagem:', e.target.src)
}

const isVideo = (att) => {
  if (!att) return false
  const type = att.content_type || att.type || ''
  const filename = att.filename || ''
  return type.toLowerCase().startsWith('video') || 
         filename.toLowerCase().endsWith('.mp4') || 
         filename.toLowerCase().endsWith('.3gp') || 
         filename.toLowerCase().endsWith('.mov')
}

const shouldShowContent = (event) => {
  if (!event.content) return false
  if (event.attachments && event.attachments.length > 0) {
    return !event.attachments.some(att => att.filename === event.content)
  }
  return true
}

const isAudio = (att) => {
  if (!att) return false
  const type = att.content_type || att.type || ''
  const filename = att.filename || ''
  return type.toLowerCase().startsWith('audio') || 
         filename.toLowerCase().endsWith('.ogg') || 
         filename.toLowerCase().endsWith('.oga') || 
         filename.toLowerCase().endsWith('.mp3') || 
         filename.toLowerCase().endsWith('.webm') ||
         filename.toLowerCase().endsWith('.m4a') ||
         filename.toLowerCase().endsWith('.wav')
}

const isImage = (att) => {
  if (!att) return false
  const type = att.content_type || att.type || ''
  const filename = att.filename || ''
  return type.toLowerCase().startsWith('image') || 
         filename.toLowerCase().endsWith('.jpg') || 
         filename.toLowerCase().endsWith('.jpeg') || 
         filename.toLowerCase().endsWith('.png') || 
         filename.toLowerCase().endsWith('.webp') ||
         filename.toLowerCase().endsWith('.gif')
}

const getAudioMimeType = (att) => {
  const type = att.content_type || ''
  if (type.startsWith('audio/')) return type
  const filename = att.filename || ''
  if (filename.toLowerCase().endsWith('.mp3')) return 'audio/mpeg'
  if (filename.toLowerCase().endsWith('.wav')) return 'audio/wav'
  if (filename.toLowerCase().endsWith('.webm')) return 'audio/webm'
  if (filename.toLowerCase().endsWith('.m4a')) return 'audio/x-m4a'
  return 'audio/ogg' // fallback padrão
}

const getTranscription = (event) => {
  return event.transcription ||
         event.metadata?.transcription || 
         event.payload?.metadata?.transcription || 
         event.payload?.transcription || 
         null
}



const getQuotePreview = (inReplyToId) => {
  if (!inReplyToId) return '...'
  const original = pipelineStore.cardTimeline.find(item => {
    const itemId = item.id?.toString()
    const itemCwId = (item.payload?.chatwoot_msg_id || item.payload?.message_id || item.chatwoot_message_id || item.payload?.in_reply_to || item.in_reply_to)?.toString()
    return itemId === inReplyToId.toString() || itemCwId === inReplyToId.toString()
  })
  
  if (!original) return '...'
  
  const attachments = original.payload?.attachments || original.attachments || []
  if (attachments.some(isAudio)) return '🎙 Áudio'
  if (attachments.some(a => a.content_type?.startsWith('image/') || a.type?.startsWith('image'))) return '🖼️ Imagem'
  if (attachments.length > 0) {
    const att = attachments[0]
    return '📄 ' + (att.filename || 'Arquivo')
  }
  
  return original.payload?.content || original.content || '...'
}

const formatSize = (bytes) => {
  if (bytes === undefined || bytes === null || isNaN(bytes)) return '0 B'
  const k = 1024
  const sizes = ['B', 'KB', 'MB', 'GB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i]
}

// Agrupador e formatador de datas da timeline
const getFriendlyDateKey = (dateStr) => {
  const date = new Date(dateStr)
  const today = new Date()
  const yesterday = new Date()
  yesterday.setDate(today.getDate() - 1)
  
  if (date.toDateString() === today.toDateString()) {
    return 'Hoje'
  } else if (date.toDateString() === yesterday.toDateString()) {
    return 'Ontem'
  } else {
    return date.toLocaleDateString('pt-BR', { day: 'numeric', month: 'long' })
  }
}

const normalizedTimeline = computed(() => {
  const list = pipelineStore.cardTimeline.map(event => {
    const mergedMetadata = {
      ...(event.metadata || {}),
      ...(event.payload?.metadata || {})
    }

    if (event.event_type === 'chatwoot_message') {
      return {
        ...event,
        event_type: 'message',
        content: event.payload?.content || '',
        message_type: event.payload?.message_type || 'incoming',
        sender_name: event.payload?.sender_name || '',
        attachments: event.payload?.attachments || event.attachments || [],
        in_reply_to: event.payload?.in_reply_to || event.in_reply_to || null,
        metadata: Object.keys(mergedMetadata).length > 0 ? mergedMetadata : null
      }
    }
    if (event.event_type === 'message_sent') {
      return {
        ...event,
        event_type: 'message',
        content: event.payload?.content || '',
        message_type: event.payload?.private_note ? 'private' : 'outgoing',
        sender_name: 'Você',
        attachments: event.payload?.attachments || event.attachments || [],
        in_reply_to: event.payload?.in_reply_to || event.in_reply_to || null,
        metadata: Object.keys(mergedMetadata).length > 0 ? mergedMetadata : null
      }
    }
    if (event.event_type === 'message') {
      return {
        ...event,
        attachments: event.payload?.attachments || event.attachments || [],
        in_reply_to: event.payload?.in_reply_to || event.in_reply_to || null,
        metadata: Object.keys(mergedMetadata).length > 0 ? mergedMetadata : null
      }
    }
    return event
  })
  
  // Ordena por data de criação crescente (mais antiga primeiro no topo, mais recente embaixo)
  list.sort((a, b) => new Date(a.created_at) - new Date(b.created_at))
  
  // Deduplicador de mensagens reativo para evitar duplicar envios locais e eventos do webhook
  const uniqList = []
  list.forEach(item => {
    const isDuplicate = uniqList.some(existing => {
      if (existing.id && item.id && existing.id === item.id) return true
      
      const isMsg1 = existing.event_type === 'message'
      const isMsg2 = item.event_type === 'message'
      
      if (isMsg1 && isMsg2) {
        const cwId1 = existing.payload?.chatwoot_msg_id || existing.payload?.message_id || existing.chatwoot_message_id
        const cwId2 = item.payload?.chatwoot_msg_id || item.payload?.message_id || item.chatwoot_message_id
        
        if (cwId1 && cwId2 && cwId1.toString() === cwId2.toString()) return true
        
        // Se o conteúdo e o tipo coincidirem e a data estiver dentro de 60s (apenas se houver texto na mensagem para evitar agrupar anexos vazios distintos)
        if (existing.content && existing.content.trim() !== '' &&
            existing.content.trim() === item.content.trim() &&
            existing.message_type === item.message_type) {
          const diff = Math.abs(new Date(existing.created_at) - new Date(item.created_at))
          if (diff < 60000) return true
        }
      }
      return false
    })
    
    if (!isDuplicate) {
      uniqList.push(item)
    } else {
      // Se for duplicado e um tiver informações de banco de dados adicionais, mesclamos
      const idx = uniqList.findIndex(existing => {
        const cwId1 = existing.payload?.chatwoot_msg_id || existing.payload?.message_id || existing.chatwoot_message_id
        const cwId2 = item.payload?.chatwoot_msg_id || item.payload?.message_id || item.chatwoot_message_id
        return cwId1 && cwId2 && cwId1.toString() === cwId2.toString()
      })
      if (idx !== -1) {
        uniqList[idx] = { ...uniqList[idx], ...item }
      }
    }
  })
  
  return uniqList
})

const filteredTimelineEvents = computed(() => {
  if (rightActiveTab.value === 'whatsapp') {
    // Apenas mensagens do WhatsApp (ignora notas internas e histórico de auditoria)
    return normalizedTimeline.value.filter(e => e.event_type === 'message' && e.message_type !== 'private')
  } else if (rightActiveTab.value === 'notes') {
    // Apenas notas internas do time
    return normalizedTimeline.value.filter(e => e.event_type === 'message' && e.message_type === 'private')
  } else {
    // Apenas histórico do sistema (eventos que não sejam mensagens de chat)
    return normalizedTimeline.value.filter(e => e.event_type !== 'message')
  }
})

const groupedTimeline = computed(() => {
  const groupsMap = {}
  filteredTimelineEvents.value.forEach(event => {
    const dateKey = getFriendlyDateKey(event.created_at)
    if (!groupsMap[dateKey]) {
      groupsMap[dateKey] = []
    }
    groupsMap[dateKey].push(event)
  })
  
  return Object.keys(groupsMap).map(date => ({
    date,
    events: groupsMap[date]
  }))
})

// Timeline de Auditoria de Sistema
const systemEvents = computed(() => {
  return normalizedTimeline.value.filter(event => event.event_type !== 'message')
})



let autoSaveTimeout = null

// Dispara o salvamento automático com de-bounce de 500ms
const triggerAutoSave = () => {
  saveStatus.value = 'salvando'
  
  if (autoSaveTimeout) {
    clearTimeout(autoSaveTimeout)
  }
  
  autoSaveTimeout = setTimeout(async () => {
    try {
      await pipelineStore.updateCard(cardId.value, {
        custom_fields: { ...localCustomFields.value }
      })
      saveStatus.value = 'salvo'
      setTimeout(() => {
        if (saveStatus.value === 'salvo') {
          saveStatus.value = ''
        }
      }, 1500)
    } catch (error) {
      saveStatus.value = ''
    }
  }, 500)
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
    transform: scale(0.97);
  }
  to {
    opacity: 1;
    transform: scale(1);
  }
}
.animate-scale-up {
  animation: scaleUp 0.15s cubic-bezier(0.16, 1, 0.3, 1) forwards;
}
</style>
