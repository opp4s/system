require 'rails_helper'

RSpec.describe 'Funnels::Api::Funnels', type: :request do
  let(:account)  { create(:account) }
  let(:user)     { create(:user, account: account) }
  let(:headers)  { { 'api_access_token' => user.access_token.token } }

  describe 'GET /api/v1/accounts/:id/funnels' do
    context 'quando não há funis' do
      it 'retorna array vazio' do
        get "/api/v1/accounts/#{account.id}/funnels", headers: headers
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq([])
      end
    end

    context 'com funis existentes' do
      let!(:funnel) { create(:funnels_funnel, account: account) }

      it 'retorna lista de funis' do
        get "/api/v1/accounts/#{account.id}/funnels", headers: headers
        body = JSON.parse(response.body)
        expect(body.length).to eq(1)
        expect(body.first['id']).to eq(funnel.id)
        expect(body.first['name']).to eq(funnel.name)
      end

      it 'não retorna funis de outra conta' do
        other_account = create(:account)
        create(:funnels_funnel, account: other_account)
        get "/api/v1/accounts/#{account.id}/funnels", headers: headers
        expect(JSON.parse(response.body).length).to eq(1)
      end
    end

    it 'retorna 401 sem token' do
      get "/api/v1/accounts/#{account.id}/funnels"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'POST /api/v1/accounts/:id/funnels' do
    it 'cria um funil' do
      post "/api/v1/accounts/#{account.id}/funnels",
           headers: headers,
           params: { funnel: { name: 'Novo Funil', color: '#FF0000' } }
      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body['name']).to eq('Novo Funil')
      expect(body['color']).to eq('#FF0000')
    end

    it 'retorna erro com nome em branco' do
      post "/api/v1/accounts/#{account.id}/funnels",
           headers: headers,
           params: { funnel: { name: '' } }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['errors']).to be_present
    end
  end

  describe 'GET /api/v1/accounts/:id/funnels/:funnel_id' do
    let!(:funnel) { create(:funnels_funnel, account: account) }

    it 'retorna funil com etapas' do
      create_list(:funnels_stage, 3, funnel: funnel)
      get "/api/v1/accounts/#{account.id}/funnels/#{funnel.id}", headers: headers
      body = JSON.parse(response.body)
      expect(body['id']).to eq(funnel.id)
      expect(body['stages'].length).to eq(3)
    end

    it 'retorna 404 para funil inexistente' do
      get "/api/v1/accounts/#{account.id}/funnels/99999", headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'PATCH /api/v1/accounts/:id/funnels/:funnel_id' do
    let!(:funnel) { create(:funnels_funnel, account: account, name: 'Original') }

    it 'atualiza o funil' do
      patch "/api/v1/accounts/#{account.id}/funnels/#{funnel.id}",
            headers: headers,
            params: { funnel: { name: 'Atualizado' } }
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['name']).to eq('Atualizado')
    end
  end

  describe 'DELETE /api/v1/accounts/:id/funnels/:funnel_id' do
    let!(:funnel) { create(:funnels_funnel, account: account) }

    it 'exclui o funil' do
      delete "/api/v1/accounts/#{account.id}/funnels/#{funnel.id}", headers: headers
      expect(response).to have_http_status(:no_content)
      expect(Funnels::Funnel.find_by(id: funnel.id)).to be_nil
    end
  end

  describe 'GET /api/v1/accounts/:id/funnels/:funnel_id/analytics' do
    let!(:funnel) { create(:funnels_funnel, account: account) }
    let!(:stage_a) { create(:funnels_stage, funnel: funnel, stage_type: 'intermediate', position: 0) }
    let!(:stage_won)  { create(:funnels_stage, funnel: funnel, stage_type: 'won',  position: 1) }
    let!(:stage_lost) { create(:funnels_stage, funnel: funnel, stage_type: 'lost', position: 2) }

    before do
      create_list(:funnels_card, 3, funnel: funnel, stage: stage_a, account: account, value: 1000)
      create(:funnels_card, funnel: funnel, stage: stage_won, account: account, value: 500)
    end

    it 'retorna métricas do funil' do
      get "/api/v1/accounts/#{account.id}/funnels/#{funnel.id}/analytics", headers: headers
      body = JSON.parse(response.body)
      expect(response).to have_http_status(:ok)
      expect(body['total_cards']).to eq(4)
      expect(body['total_value'].to_f).to eq(3500.0)
      expect(body['won_cards']).to eq(1)
      expect(body['lost_cards']).to eq(0)
      expect(body['conversion_rate']).to eq(25.0)
      expect(body['stages'].length).to eq(3)
    end
  end
end
