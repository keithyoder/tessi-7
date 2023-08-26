# frozen_string_literal: true

json.extract! ponto, :id, :nome, :sistema, :tecnologia, :servidor_id, :ip, :usuario, :senha, :created_at, :updated_at
json.url ponto_url(ponto, format: :json)
