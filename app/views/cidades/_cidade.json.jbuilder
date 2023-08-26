# frozen_string_literal: true

json.extract! cidade, :id, :nome, :estado_id, :ibge, :created_at, :updated_at
json.url cidade_url(cidade, format: :json)
