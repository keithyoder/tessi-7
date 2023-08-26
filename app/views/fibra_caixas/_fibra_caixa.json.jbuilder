# frozen_string_literal: true

json.extract! fibra_caixa, :id, :nome, :fibra_rede_id, :capacidade, :created_at, :updated_at
json.url fibra_caixa_url(fibra_caixa, format: :json)
