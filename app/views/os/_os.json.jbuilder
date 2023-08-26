# frozen_string_literal: true

json.extract! os, :id, :tipo, :classificao_id, :pessoa_id, :conexao_id, :aberto_por_id, :responsavel_id, :tecnico_1_id,
              :tecnico_2_id, :fechamento, :descricao, :encerramento, :created_at, :updated_at
json.url os_url(os, format: :json)
