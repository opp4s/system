import axios from 'axios';

const state = {
  funnels: [],
  funnelsLoaded: false,   // evita re-fetch desnecessário no sidebar
  currentFunnelId: null,
  stages: [],
  cards: {},       // { [stageId]: Card[] }
  loading: false,
  loadingCards: false,
  error: null,
};

const getters = {
  allFunnels: s => s.funnels,
  funnelsLoaded: s => s.funnelsLoaded,
  currentFunnel: s => s.funnels.find(f => f.id === s.currentFunnelId) || null,
  stages: s => s.stages,
  visibleStages: s => (showTerminal = false) => {
    return showTerminal
      ? s.stages
      : s.stages.filter(st => st.stage_type === 'intermediate');
  },
  cardsByStage: s => stageId => s.cards[stageId] || [],
  isLoading: s => s.loading,
  isLoadingCards: s => s.loadingCards,
};

const mutations = {
  SET_FUNNELS(state, funnels) { state.funnels = funnels; },
  SET_CURRENT_FUNNEL(state, id) {
    state.currentFunnelId = id;
    state.stages = [];
    state.cards = {};
  },
  SET_STAGES(state, stages) { state.stages = stages; },
  SET_CARDS(state, { stageId, cards }) {
    state.cards = { ...state.cards, [stageId]: cards };
  },
  SET_ALL_CARDS(state, cardsByStage) { state.cards = cardsByStage; },
  ADD_CARD(state, card) {
    const stageCards = state.cards[card.stage_id] || [];
    state.cards = { ...state.cards, [card.stage_id]: [...stageCards, card] };
  },
  UPDATE_CARD(state, updatedCard) {
    const newCards = {};
    Object.keys(state.cards).forEach(sid => {
      newCards[sid] = state.cards[sid].map(c =>
        c.id === updatedCard.id ? updatedCard : c
      );
    });
    state.cards = newCards;
  },
  MOVE_CARD_OPTIMISTIC(state, { cardId, fromStageId, toStageId }) {
    const fromCards = (state.cards[fromStageId] || []);
    const card = fromCards.find(c => c.id === cardId);
    if (!card) return;
    state.cards = {
      ...state.cards,
      [fromStageId]: fromCards.filter(c => c.id !== cardId),
      [toStageId]: [...(state.cards[toStageId] || []), { ...card, stage_id: toStageId }],
    };
  },
  MOVE_CARD_TO_STAGE(state, updatedCard) {
    const newCards = {};
    Object.keys(state.cards).forEach(sid => {
      newCards[sid] = (state.cards[sid] || []).filter(c => c.id !== updatedCard.id);
    });
    const key = String(updatedCard.stage_id);
    newCards[key] = [...(newCards[key] || []), updatedCard];
    state.cards = newCards;
  },
  REMOVE_CARD(state, cardId) {
    const newCards = {};
    Object.keys(state.cards).forEach(sid => {
      newCards[sid] = state.cards[sid].filter(c => c.id !== cardId);
    });
    state.cards = newCards;
  },
  SET_LOADING(state, v) { state.loading = v; },
  SET_LOADING_CARDS(state, v) { state.loadingCards = v; },
  SET_ERROR(state, msg) { state.error = msg; },
  SET_FUNNELS_LOADED(state, v) { state.funnelsLoaded = v; },
};

const actions = {
  async fetchFunnels({ commit, rootGetters }) {
    commit('SET_LOADING', true);
    try {
      const accountId = rootGetters['getCurrentAccountId'];
      const { data } = await axios.get(`/api/v1/accounts/${accountId}/funnels`);
      commit('SET_FUNNELS', data);
      commit('SET_FUNNELS_LOADED', true);
    } catch (e) {
      commit('SET_ERROR', e.message);
    } finally {
      commit('SET_LOADING', false);
    }
  },

  // Chamado pelo sidebar no onMounted — só busca se ainda não carregou
  fetchFunnelsIfNeeded({ state, dispatch }) {
    if (!state.funnelsLoaded && !state.loading) {
      dispatch('fetchFunnels');
    }
  },

  async selectFunnel({ commit, dispatch, rootGetters }, funnelId) {
    commit('SET_CURRENT_FUNNEL', funnelId);
    const accountId = rootGetters['getCurrentAccountId'];
    commit('SET_LOADING', true);
    try {
      const { data } = await axios.get(`/api/v1/accounts/${accountId}/funnels/${funnelId}`);
      commit('SET_STAGES', data.stages || []);
    } catch (e) {
      commit('SET_ERROR', e.message);
    } finally {
      commit('SET_LOADING', false);
    }
    dispatch('fetchAllCards', { accountId, funnelId });
  },

  async fetchAllCards({ commit, rootGetters }, { funnelId }) {
    commit('SET_LOADING_CARDS', true);
    try {
      const accountId = rootGetters['getCurrentAccountId'];
      const { data } = await axios.get(
        `/api/v1/accounts/${accountId}/funnels/${funnelId}/cards`
      );
      const byStage = {};
      data.forEach(card => {
        if (!byStage[card.stage_id]) byStage[card.stage_id] = [];
        byStage[card.stage_id].push(card);
      });
      commit('SET_ALL_CARDS', byStage);
    } catch (e) {
      commit('SET_ERROR', e.message);
    } finally {
      commit('SET_LOADING_CARDS', false);
    }
  },

  async createCard({ commit, rootGetters }, { funnelId, cardData }) {
    const accountId = rootGetters['getCurrentAccountId'];
    const { data } = await axios.post(
      `/api/v1/accounts/${accountId}/funnels/${funnelId}/cards`,
      { card: cardData }
    );
    commit('ADD_CARD', data);
    return data;
  },

  async moveCard({ commit, rootGetters }, { funnelId, cardId, stageId, fromStageId, lostReason }) {
    commit('MOVE_CARD_OPTIMISTIC', { cardId, fromStageId, toStageId: stageId });
    try {
      const accountId = rootGetters['getCurrentAccountId'];
      const { data } = await axios.post(
        `/api/v1/accounts/${accountId}/funnels/${funnelId}/cards/${cardId}/move`,
        { stage_id: stageId, lost_reason: lostReason }
      );
      commit('UPDATE_CARD', data);
    } catch (e) {
      commit('MOVE_CARD_OPTIMISTIC', { cardId, fromStageId: stageId, toStageId: fromStageId });
      throw e;
    }
  },

  applyRealtimeEvent({ commit }, { event, card }) {
    if (event === 'card_created')                    commit('ADD_CARD', card);
    else if (event === 'card_updated')               commit('UPDATE_CARD', card);
    else if (event === 'card_moved')                 commit('MOVE_CARD_TO_STAGE', card);
    else if (event === 'card_transferred')           commit('REMOVE_CARD', card.id);
    else if (event === 'card_deleted' ||
             event === 'card_archived')              commit('REMOVE_CARD', card.id);
  },

  // Atualiza contagens de uma etapa após broadcast stage_updated
  refreshStageCount({ commit, state }, stageId) {
    const stage = state.stages.find(s => s.id === stageId);
    if (!stage) return;
    commit('SET_STAGES', state.stages.map(s =>
      s.id === stageId
        ? { ...s, cards_count: (state.cards[stageId] || []).length }
        : s
    ));
  },
};

export default {
  namespaced: true,
  state,
  getters,
  mutations,
  actions,
};
