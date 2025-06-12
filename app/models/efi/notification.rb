# frozen_string_literal: true

module Efi
  class Notification # rubocop:disable Style/Documentation
    def initialize(token)
      @token = token
    end

    def payload
      @payload ||= Efi.cliente.getNotification(
        params: { token: @token }
      )
    end

    def pago
      @pago ||= payload['data'].find { |e| e['type'] == 'charge' && e['status']['current'] == 'paid' }
    end

    def identificado
      @identificado ||= payload['data'].find { |e| e['type'] == 'charge' && e['status']['current'] == 'identified' }
    end

    def registro
      @registro ||= payload['data'].find { |e| e['type'] == 'charge' && e['status']['current'] == 'waiting' }
    end

    def cancelado
      @cancelado ||= payload['data'].find { |e| e['type'] == 'charge' && e['status']['current'] == 'canceled' }
    end

    def baixado
      @baixado ||= payload['data'].find { |e| e['type'] == 'charge' && e['status']['current'] == 'settled' }
    end

    def assinatura?
      payload['data'].first['type'] == 'subscription'
    end

    def custom_id
      payload['data'].first['custom_id'].to_i
    end

    def fatura
      @fatura ||= if assinatura?
                    Contrato.find(custom_id).faturas.em_aberto.first
                  else
                    Fatura.find(custom_id)
                  end
    end
  end
end
