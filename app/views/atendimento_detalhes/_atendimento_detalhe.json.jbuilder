# frozen_string_literal: true

json.extract! atendimento_detalhe, :id, :atendimento_id, :tipo, :atendente_id, :descricao, :created_at, :updated_at
json.url atendimento_detalhe_url(atendimento_detalhe, format: :json)
