# frozen_string_literal: true

json.extract! conexao, :id, :pessoa_id, :plano_id, :ponto_id, :ip, :velocidade, :bloqueado, :auto_bloqueio,
              :created_at, :updated_at
json.url conexao_url(conexao, format: :json)
