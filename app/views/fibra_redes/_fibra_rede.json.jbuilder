# frozen_string_literal: true

json.extract! fibra_rede, :id, :nome, :ponto_id, :created_at, :updated_at
json.url fibra_rede_url(fibra_rede, format: :json)
