# Seeds idempotentes — seguros para rodar múltiplas vezes
# Uso: docker compose exec zavy-api bundle exec rails db:seed

puts "==> Seeding Zavy CRM..."

# ---------------------------------------------------------------------------
# Admin user
# ---------------------------------------------------------------------------
admin = User.find_or_initialize_by(email: "admin@zavycrm.com")
admin.assign_attributes(
  name:                  "Admin Zavy",
  password:              "Admin123!",
  password_confirmation: "Admin123!"
)
admin.save!
puts "  [User] admin@zavycrm.com #{admin.previously_new_record? ? "criado" : "já existe"}"

# ---------------------------------------------------------------------------
# Demo workspace
# ---------------------------------------------------------------------------
demo_ws = Workspace.find_or_initialize_by(slug: "zavy-demo")
demo_ws.assign_attributes(
  name:     "Zavy Demo",
  plan:     "pro",
  owner:    admin,
  settings: {
    "timezone"   => "America/Sao_Paulo",
    "language"   => "pt-BR",
    "brand_name" => "Zavy CRM"
  }
)
demo_ws.save!
puts "  [Workspace] Zavy Demo #{demo_ws.previously_new_record? ? "criado" : "já existe"}"

# Membership do admin no demo workspace
membership = WorkspaceMembership.find_or_initialize_by(
  workspace: demo_ws,
  user:      admin
)
membership.assign_attributes(
  role:        "owner",
  accepted_at: membership.accepted_at || Time.current,
  invited_at:  membership.invited_at  || Time.current
)
membership.save!
puts "  [Membership] admin → zavy-demo (owner)"

# ---------------------------------------------------------------------------
# Usuários de demonstração
# ---------------------------------------------------------------------------
[
  { email: "manager@zavycrm.com", name: "Maria Gestora", role: "admin" },
  { email: "agent@zavycrm.com",   name: "João Agente",   role: "agent" }
].each do |attrs|
  user = User.find_or_initialize_by(email: attrs[:email])
  user.assign_attributes(
    name:                  attrs[:name],
    password:              "Demo123!",
    password_confirmation: "Demo123!"
  )
  user.save!
  puts "  [User] #{attrs[:email]} #{user.previously_new_record? ? "criado" : "já existe"}"

  m = WorkspaceMembership.find_or_initialize_by(workspace: demo_ws, user: user)
  m.assign_attributes(
    role:        attrs[:role],
    accepted_at: m.accepted_at || Time.current,
    invited_at:  m.invited_at  || Time.current
  )
  m.save!
  puts "  [Membership] #{attrs[:email]} → zavy-demo (#{attrs[:role]})"
end

# ---------------------------------------------------------------------------
# Pipeline de demonstração
# ---------------------------------------------------------------------------
pipeline = Pipeline.find_or_initialize_by(workspace: demo_ws, name: "Pipeline de Vendas")
pipeline.assign_attributes(
  description: "Pipeline padrão de vendas do workspace demo",
  color:       "#6366F1",
  position:    0,
  is_default:  true
)
pipeline.save!
puts "  [Pipeline] #{pipeline.name} #{pipeline.previously_new_record? ? "criado" : "já existe"}"

stages_config = [
  { name: "Novo Lead",        color: "#6C757D", stage_type: "intermediate", win_probability: 10, position: 0 },
  { name: "Qualificado",      color: "#0D6EFD", stage_type: "intermediate", win_probability: 30, position: 1 },
  { name: "Proposta Enviada", color: "#FFC107", stage_type: "intermediate", win_probability: 60, position: 2 },
  { name: "Negociação",       color: "#FD7E14", stage_type: "intermediate", win_probability: 80, position: 3 },
  { name: "Ganho",            color: "#198754", stage_type: "won",          win_probability: 100, position: 4 },
  { name: "Perdido",          color: "#DC3545", stage_type: "lost",         win_probability: 0,   position: 5 }
]

stages_config.each do |attrs|
  stage = Stage.find_or_initialize_by(pipeline: pipeline, name: attrs[:name])
  stage.assign_attributes(attrs)
  stage.save!
  puts "  [Stage] #{stage.name} (#{stage.stage_type})"
end

# ---------------------------------------------------------------------------
# Chatwoot config para o workspace demo
# ---------------------------------------------------------------------------
if ENV["CHATWOOT_URL"].present? && ENV["CHATWOOT_API_TOKEN"].present?
  cw_cfg = ChatwootConfig.find_or_initialize_by(workspace: demo_ws)
  cw_cfg.chatwoot_url        = ENV["CHATWOOT_URL"]
  cw_cfg.chatwoot_account_id = "1"
  cw_cfg.chatwoot_api_token  = ENV["CHATWOOT_API_TOKEN"]
  cw_cfg.save!
  puts "  [ChatwootConfig] workspace demo → account 1 (#{cw_cfg.previously_new_record? ? "criado" : "atualizado"})"
else
  puts "  [ChatwootConfig] SKIPPED (CHATWOOT_URL ou CHATWOOT_API_TOKEN não definidos)"
end

puts ""
puts "==> Seeds concluídos!"
puts "    Admin:   admin@zavycrm.com   / Admin123!"
puts "    Manager: manager@zavycrm.com / Demo123!"
puts "    Agent:   agent@zavycrm.com   / Demo123!"
puts "    Pipeline: #{pipeline.name} (#{pipeline.stages.count} stages)"
