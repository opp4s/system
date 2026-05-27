FactoryBot.define do
  factory :funnels_funnel, class: 'Funnels::Funnel' do
    association :account
    sequence(:name) { |n| "Funil #{n}" }
    color       { '#1F93FF' }
    position    { 0 }
    is_default  { false }
  end

  factory :funnels_stage, class: 'Funnels::Stage' do
    association :funnel, factory: :funnels_funnel
    sequence(:name) { |n| "Etapa #{n}" }
    color       { '#6C757D' }
    stage_type  { 'intermediate' }
    position    { 0 }
    win_probability { 50 }
  end

  factory :funnels_card, class: 'Funnels::Card' do
    association :funnel,  factory: :funnels_funnel
    association :stage,   factory: :funnels_stage
    association :account
    sequence(:title) { |n| "Lead #{n}" }
    value     { 0 }
    currency  { 'BRL' }
    stage_changed_at { Time.current }
  end

  factory :funnels_stage_automation, class: 'Funnels::StageAutomation' do
    association :funnel_stage, factory: :funnels_stage
    association :account
    automation_type { 'webhook' }
    trigger_event   { 'on_enter' }
    config          { { url: 'https://example.com/hook', method: 'POST', include_card: true } }
    active          { true }
    position        { 0 }
  end
end
