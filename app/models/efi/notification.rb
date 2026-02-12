# frozen_string_literal: true

module Efi
  class Notification
    CHARGE_TYPES = %w[charge subscription_charge].freeze

    def initialize(token)
      @token = token
    end

    def payload
      @payload ||= Efi.cliente.getNotification(
        params: { token: @token }
      )
    end

    def pago
      @pago ||= payload['data'].find { |e| charge_status?(e, 'paid') }
    end

    def identificado
      @identificado ||= payload['data'].find { |e| charge_status?(e, 'identified') }
    end

    def registro
      @registro ||= payload['data'].find { |e| charge_status?(e, 'waiting') }
    end

    def cancelado
      @cancelado ||= payload['data'].find { |e| charge_status?(e, 'canceled') }
    end

    def baixado
      @baixado ||= payload['data'].find { |e| charge_status?(e, 'settled') }
    end

    def assinatura?
      payload['data'].first['type'] == 'subscription'
    end

    def fatura
      @fatura ||= Fatura.find(custom_id) ||
                  Fatura.find_by(id_externo: charge_id) ||
                  Contrato.find(custom_id).faturas.em_aberto.first
    end

    private

    def custom_id
      payload['data'].first['custom_id'].to_i
    end

    def charge_id
      payload['data'].last.dig('identifiers', 'charge_id')
    end

    def charge_status?(payload, status)
      CHARGE_TYPES.any?(payload['type']) && payload['status']['current'] == status
    end
  end
end
