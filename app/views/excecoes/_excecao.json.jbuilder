# frozen_string_literal: true

json.extract! excecao, :id, :contrato_id, :valido_ate, :tipo, :usuario, :created_at, :updated_at
json.url excecao_url(excecao, format: :json)
