# frozen_string_literal: true

json.extract! plano_enviar_atributo, :id, :plano_id, :atributo, :op, :valor, :created_at, :updated_at
json.url plano_enviar_atributo_url(plano_enviar_atributo, format: :json)
