module Funnels
  class Seeder
    DEFAULT_STAGES = [
      { name: 'Novo Lead',       color: '#6C757D', stage_type: 'intermediate', win_probability: 10,  position: 0 },
      { name: 'Qualificado',     color: '#007BFF', stage_type: 'intermediate', win_probability: 25,  position: 1 },
      { name: 'Proposta Enviada',color: '#FFC107', stage_type: 'intermediate', win_probability: 50,  position: 2 },
      { name: 'Negociação',      color: '#FD7E14', stage_type: 'intermediate', win_probability: 75,  position: 3 },
      { name: 'Ganho',           color: '#28A745', stage_type: 'won',          win_probability: 100, position: 4 },
      { name: 'Perdido',         color: '#DC3545', stage_type: 'lost',         win_probability: 0,   position: 5 },
    ].freeze

    def self.seed_default_funnel(account_id)
      ActiveRecord::Base.transaction do
        funnel = Funnels::Funnel.create!(
          account_id: account_id,
          name: 'Pipeline de Vendas',
          description: 'Funil padrão de gestão de oportunidades',
          color: '#1F93FF',
          position: 0,
          is_default: true
        )
        DEFAULT_STAGES.each do |attrs|
          funnel.stages.create!(attrs)
        end
        funnel
      end
    end
  end
end
