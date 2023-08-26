# frozen_string_literal: true

json.extract! plano_verificar_atributo, :id, :plano_id, :atributo, :op, :valor, :created_at, :updated_at
json.url plano_verificar_atributo_url(plano_verificar_atributo, format: :json)
