# frozen_string_literal: true

# RailsSettings Model
class Setting < RailsSettings::Base
  cache_prefix { 'v1' }

  # Define your fields
  # field :host, type: :string, default: "http://localhost:3000"
  field :razao_social, default: '', type: :string
  field :cnpj, default: '', type: :string
  field :ie, default: '', type: :string
  field :site, default: '', type: :string
  field :telefone, default: '', type: :string
  field :juros, default: 0.1, type: :decimal
  field :multa, default: 0.2, type: :decimal

  # field :default_locale, default: "en", type: :string
  # field :confirmable_enable, default: "0", type: :boolean
  # field :admin_emails, default: "admin@rubyonrails.org", type: :array
  # field :omniauth_google_client_id, default: (ENV["OMNIAUTH_GOOGLE_CLIENT_ID"] || ""), type: :string, readonly: true
  # field :omniauth_google_client_secret, default: (ENV["OMNIAUTH_GOOGLE_CLIENT_SECRET"] || ""), type: :string, readonly: true
end
