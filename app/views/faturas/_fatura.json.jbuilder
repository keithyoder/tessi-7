# frozen_string_literal: true

json.extract! fatura, :id, :contrato_id, :valor, :vencimento, :nossonumero, :parcela, :arquivo_remessa, :data_remessa,
              :data_cancelamento, :created_at, :updated_at
json.url fatura_url(fatura, format: :json)
