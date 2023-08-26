# frozen_string_literal: true

json.extract! pagamento_perfil, :id, :nome, :tipo, :cedente, :agencia, :conta, :carteira, :created_at, :updated_at
json.url pagamento_perfil_url(pagamento_perfil, format: :json)
