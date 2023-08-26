# frozen_string_literal: true

json.extract! ip_rede, :id, :rede, :created_at, :updated_at
json.url ip_rede_url(ip_rede, format: :json)
