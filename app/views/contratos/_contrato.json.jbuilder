# frozen_string_literal: true

json.extract! contrato, :id, :pessoa_id, :plano_id, :status, :dia_vencimento, :adesao, :valor_instalacao,
              :numero_conexoes, :cancelamento, :emite_nf, :primeiro_vencimento, :prazo_meses, :created_at, :updated_at
json.url contrato_url(contrato, format: :json)
