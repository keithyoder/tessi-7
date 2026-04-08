Autentique.configure do |config|
  config.api_key = Rails.application.credentials[:autentique_key]
  config.sandbox = Rails.env.local?
end
