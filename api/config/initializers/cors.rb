Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(
      "https://chat.zavycrm.com",
      "https://app.zavycrm.com",
      /https:\/\/.*\.zavycrm\.com$/,
      # Desenvolvimento local
      "http://localhost:3000",
      "http://localhost:5173",
      "http://localhost:4173"
    )

    resource "*",
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      expose: ["Authorization"],
      max_age: 600
  end
end
