# frozen_string_literal: true

json.extract! servidor, :id, :nome, :ip, :usuario, :senha, :api_porta, :ssh_porta, :snmp_porta, :snmp_comunidade,
              :created_at, :updated_at
json.url servidor_url(servidor, format: :json)
