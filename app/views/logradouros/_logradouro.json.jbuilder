# frozen_string_literal: true

json.extract! logradouro, :id, :nome, :bairro_id, :cep, :created_at, :updated_at
json.url logradouro_url(logradouro, format: :json)
