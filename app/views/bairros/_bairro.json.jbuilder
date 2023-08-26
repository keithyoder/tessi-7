# frozen_string_literal: true

json.extract! bairro, :id, :nome, :cidade_id, :latitude, :longitude, :created_at, :updated_at
json.url bairro_url(bairro, format: :json)
