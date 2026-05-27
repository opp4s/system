require 'rails_helper'

RSpec.describe 'Funnels::Api::Stages', type: :request do
  let(:account) { create(:account) }
  let(:user)    { create(:user, account: account) }
  let(:headers) { { 'api_access_token' => user.access_token.token } }
  let!(:funnel) { create(:funnels_funnel, account: account) }

  describe 'GET /api/v1/accounts/:id/funnels/:fid/stages' do
    it 'retorna etapas ordenadas por position' do
      create(:funnels_stage, funnel: funnel, name: 'B', position: 1)
      create(:funnels_stage, funnel: funnel, name: 'A', position: 0)
      get "/api/v1/accounts/#{account.id}/funnels/#{funnel.id}/stages", headers: headers
      body = JSON.parse(response.body)
      expect(body.map { |s| s['name'] }).to eq(%w[A B])
    end
  end

  describe 'POST /api/v1/accounts/:id/funnels/:fid/stages' do
    it 'cria uma etapa intermediária' do
      post "/api/v1/accounts/#{account.id}/funnels/#{funnel.id}/stages",
           headers: headers,
           params: { stage: { name: 'Nova Etapa', stage_type: 'intermediate' } }
      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body['name']).to eq('Nova Etapa')
      expect(body['stage_type']).to eq('intermediate')
    end

    it 'rejeita stage_type inválido' do
      post "/api/v1/accounts/#{account.id}/funnels/#{funnel.id}/stages",
           headers: headers,
           params: { stage: { name: 'X', stage_type: 'invalido' } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'PATCH /api/v1/accounts/:id/funnels/:fid/stages/:id' do
    let!(:stage) { create(:funnels_stage, funnel: funnel, name: 'Antes') }

    it 'atualiza a etapa' do
      patch "/api/v1/accounts/#{account.id}/funnels/#{funnel.id}/stages/#{stage.id}",
            headers: headers,
            params: { stage: { name: 'Depois', color: '#00FF00' } }
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['name']).to eq('Depois')
    end
  end

  describe 'DELETE /api/v1/accounts/:id/funnels/:fid/stages/:id' do
    context 'sem cards ativos' do
      let!(:stage) { create(:funnels_stage, funnel: funnel) }

      it 'exclui a etapa' do
        delete "/api/v1/accounts/#{account.id}/funnels/#{funnel.id}/stages/#{stage.id}",
               headers: headers
        expect(response).to have_http_status(:no_content)
      end
    end

    context 'com cards ativos' do
      let!(:stage) { create(:funnels_stage, funnel: funnel) }

      before { create(:funnels_card, funnel: funnel, stage: stage, account: account) }

      it 'impede a exclusão' do
        delete "/api/v1/accounts/#{account.id}/funnels/#{funnel.id}/stages/#{stage.id}",
               headers: headers
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['error']).to be_present
      end
    end
  end

  describe 'POST /api/v1/accounts/:id/funnels/:fid/stages/reorder' do
    let!(:s1) { create(:funnels_stage, funnel: funnel, position: 0) }
    let!(:s2) { create(:funnels_stage, funnel: funnel, position: 1) }
    let!(:s3) { create(:funnels_stage, funnel: funnel, position: 2) }

    it 'reordena as etapas' do
      post "/api/v1/accounts/#{account.id}/funnels/#{funnel.id}/stages/reorder",
           headers: headers,
           params: { stage_ids: [s3.id, s1.id, s2.id] }
      expect(response).to have_http_status(:ok)
      expect(s3.reload.position).to eq(0)
      expect(s1.reload.position).to eq(1)
      expect(s2.reload.position).to eq(2)
    end
  end
end
