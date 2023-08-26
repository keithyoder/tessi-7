# frozen_string_literal: true

json.extract! plano, :id, :nome, :mensalidade, :upload, :download, :burst, :created_at, :updated_at
json.url plano_url(plano, format: :json)
