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

puts ""
puts "==> Seeds concluídos!"
puts "    Admin:   admin@zavycrm.com   / Admin123!"
puts "    Manager: manager@zavycrm.com / Demo123!"
puts "    Agent:   agent@zavycrm.com   / Demo123!"
