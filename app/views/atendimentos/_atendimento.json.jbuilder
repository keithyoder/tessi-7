# frozen_string_literal: true

json.extract! atendimento, :id, :pessoa_id, :classificaco_id, :responsavel_id, :fechamento, :contrato_id, :conexao_id,
              :fatura_id, :created_at, :updated_at
json.url atendimento_url(atendimento, format: :json)
