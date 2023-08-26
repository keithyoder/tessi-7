# frozen_string_literal: true

json.extract! equipamento, :id, :fabricante, :modelo, :tipo, :created_at, :updated_at
json.url equipamento_url(equipamento, format: :json)
