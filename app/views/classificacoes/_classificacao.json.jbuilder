# frozen_string_literal: true

json.extract! classificacao, :id, :tipo, :nome, :created_at, :updated_at
json.url classificacao_url(classificacao, format: :json)
