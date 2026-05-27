require 'rails_helper'

RSpec.describe 'Funnels::Api::Cards', type: :request do
  let(:account)       { create(:account) }
  let(:user)          { create(:user, account: account) }
  let(:headers)       { { 'api_access_token' => user.access_token.token } }
  let!(:funnel)       { create(:funnels_funnel, account: account) }
  let!(:stage_a)      { create(:funnels_stage, funnel: funnel, stage_type: 'intermediate', position: 0) }
  let!(:stage_b)      { create(:funnels_stage, funnel: funnel, stage_type: 'intermediate', position: 1) }
  let!(:stage_lost)   { create(:funnels_stage, funnel: funnel, stage_type: 'lost', position: 2, name: 'Perdido') }

  describe 'GET /api/v1/accounts/:id/funnels/:fid/cards' do
    before { create_list(:funnels_card, 4, funnel: funnel, stage: stage_a, account: account) }

    it 'retorna cards ativos do funil' do
      get "/api/v1/accounts/#{account.id}/funnels/#{funnel.id}/cards", headers: headers
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).length).to eq(4)
    end

    it 'filtra por stage_id' do
      create_list(:funnels_card, 2, funnel: funnel, stage: stage_b, account: account)
      get "/api/v1/accounts/#{account.id}/funnels/#{funnel.id}/cards",
          headers: headers,
          params: { stage_id: stage_b.id }
      expect(JSON.parse(response.body).length).to eq(2)
    end

    it 'não retorna cards arquivados' do
      archived = create(:funnels_card, funnel: funnel, stage: stage_a, account: account,
                        archived_at: 1.day.ago)
      get "/api/v1/accounts/#{account.id}/funnels/#{funnel.id}/cards", headers: headers
      ids = JSON.parse(response.body).map { |c| c['id'] }
      expect(ids).not_to include(archived.id)
    end
  end

  describe 'POST /api/v1/accounts/:id/funnels/:fid/cards' do
    it 'cria um card' do
      expect do
        post "/api/v1/accounts/#{account.id}/funnels/#{funnel.id}/cards",
             headers: headers,
             params: { card: { title: 'Novo Lead', stage_id: stage_a.id, value: 5000 } }
      end.to change(Funnels::Card, :count).by(1)
      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body['title']).to eq('Novo Lead')
      expect(body['value']).to eq(5000.0)
    end

    it 'cria evento card_created' do
      post "/api/v1/accounts/#{account.id}/funnels/#{funnel.id}/cards",
           headers: headers,
           params: { card: { title: 'Lead', stage_id: stage_a.id } }
      card = Funnels::Card.last
      expect(card.card_events.pluck(:event_type)).to include('card_created')
    end

    it 'retorna erro sem título' do
      post "/api/v1/accounts/#{account.id}/funnels/#{funnel.id}/cards",
           headers: headers,
           params: { card: { title: '', stage_id: stage_a.id } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'POST /api/v1/accounts/:id/funnels/:fid/cards/:id/move' do
    let!(:card) { create(:funnels_card, funnel: funnel, stage: stage_a, account: account) }

    it 'move o card para outra etapa' do
      post "/api/v1/accounts/#{account.id}/funnels/#{funnel.id}/cards/#{card.id}/move",
           headers: headers,
           params: { stage_id: stage_b.id }
      expect(response).to have_http_status(:ok)
      expect(card.reload.funnel_stage_id).to eq(stage_b.id)
    end

    it 'salva lost_reason ao mover para etapa Perdido' do
      post "/api/v1/accounts/#{account.id}/funnels/#{funnel.id}/cards/#{card.id}/move",
           headers: headers,
           params: { stage_id: stage_lost.id, lost_reason: 'Preço alto' }
      expect(card.reload.lost_reason).to eq('Preço alto')
    end

    it 'registra evento card_moved' do
      post "/api/v1/accounts/#{account.id}/funnels/#{funnel.id}/cards/#{card.id}/move",
           headers: headers,
           params: { stage_id: stage_b.id }
      expect(card.card_events.pluck(:event_type)).to include('card_moved')
    end

    it 'retorna 404 para etapa inexistente' do
      post "/api/v1/accounts/#{account.id}/funnels/#{funnel.id}/cards/#{card.id}/move",
           headers: headers,
           params: { stage_id: 99999 }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /api/v1/accounts/:id/funnels/:fid/cards/:id/archive' do
    let!(:card) { create(:funnels_card, funnel: funnel, stage: stage_a, account: account) }

    it 'arquiva o card' do
      post "/api/v1/accounts/#{account.id}/funnels/#{funnel.id}/cards/#{card.id}/archive",
           headers: headers
      expect(response).to have_http_status(:no_content)
      expect(card.reload.archived_at).not_to be_nil
    end
  end

  describe 'GET /api/v1/accounts/:id/funnels/:fid/cards/:id/timeline' do
    let!(:card) { create(:funnels_card, funnel: funnel, stage: stage_a, account: account) }

    before do
      card.record_event('card_created', user: user)
      card.record_event('card_moved', payload: { from_stage_name: 'A', to_stage_name: 'B' })
    end

    it 'retorna timeline com eventos' do
      get "/api/v1/accounts/#{account.id}/funnels/#{funnel.id}/cards/#{card.id}/timeline",
          headers: headers
      body = JSON.parse(response.body)
      expect(response).to have_http_status(:ok)
      expect(body['timeline']).to be_an(Array)
      expect(body['timeline'].length).to eq(2)
      event_types = body['timeline'].map { |i| i['event_type'] }
      expect(event_types).to include('card_created', 'card_moved')
    end
  end

  describe 'POST /api/v1/accounts/:id/funnels/:fid/cards/:id/transfer' do
    let!(:other_funnel) { create(:funnels_funnel, account: account, name: 'Outro') }
    let!(:other_stage)  { create(:funnels_stage, funnel: other_funnel, stage_type: 'intermediate') }
    let!(:card)         { create(:funnels_card, funnel: funnel, stage: stage_a, account: account) }

    it 'transfere o card para outro funil' do
      post "/api/v1/accounts/#{account.id}/funnels/#{funnel.id}/cards/#{card.id}/transfer",
           headers: headers,
           params: { funnel_id: other_funnel.id, stage_id: other_stage.id }
      expect(response).to have_http_status(:ok)
      expect(card.reload.funnel_id).to eq(other_funnel.id)
      expect(card.reload.funnel_stage_id).to eq(other_stage.id)
    end
  end
end
