Devise::JWT.configure do |config|
  config.secret = ENV.fetch("DEVISE_JWT_SECRET_KEY")
  config.expiration_time = 7.days.to_i
  config.dispatch_requests = [
    ["POST", %r{^/auth/login$}]
  ]
  config.revocation_requests = [
    ["DELETE", %r{^/auth/logout$}]
  ]
end
