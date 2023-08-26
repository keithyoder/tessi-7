# frozen_string_literal: true

json.extract! conexao_verificar_atributo, :id, :conexao_id, :atributo, :op, :valor, :created_at, :updated_at
json.url conexao_verificar_atributo_url(conexao_verificar_atributo, format: :json)
