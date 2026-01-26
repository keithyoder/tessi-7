Autentique.configure do |config|
  config.api_key = Rails.application.credentials.dig(:autentique, :api_key)
  config.sandbox = Rails.env.local?
end
