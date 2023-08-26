# frozen_string_literal: true

json.extract! conexao_enviar_atributo, :id, :conexao_id, :atributo, :op, :valor, :created_at, :updated_at
json.url conexao_enviar_atributo_url(conexao_enviar_atributo, format: :json)
