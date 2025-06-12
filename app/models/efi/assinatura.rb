# frozen_string_literal: true

module Efi
  class Assinatura # rubocop:disable Style/Documentation
    def initialize(contrato)
      @contrato = contrato
      @cliente = Efi.cliente(
        client_id: contrato.pagamento_perfil.client_id,
        client_secret: contrato.pagamento_perfil.client_secret
      )
    end

    def create
      params = {
        id: @contrato.plano.gerencianet_id
      }
      resposta = @cliente.createOneStepSubscriptionLink(params: params, body: body)
      puts resposta
      @contrato.update(recorrencia_id: resposta['data']['subscription_id'])
    end

    def update
      params = {
        id: contrato.recorrencia_id
      }
      cliente.updateSubscriptionMetadata(
        params: params,
        body: {
          notification_url: 'https://webhook.site/#!/view/49da8d53-2210-4b88-a0a1-8b2d1772c7ff/53c3466b-76e9-49d8-aea8-e2a327dffce0/1',
          custom_id: contrato.id.to_s
        }
      )
    end

    def get
      @cliente.detailSubscription(params: { id: @contrato.recorrencia_id })
    end

    def link
      @cliente.detailCharge(params: { id: get.dig('data', 'link', 'payment_url') })
    end

    private

    def body # rubocop:disable Metrics/MethodLength
      {
        "items": [
          {
            "amount": 1,
            "name": @contrato.descricao,
            "value": (@contrato.plano.valor_com_desconto * 100).to_i
          }
        ],
        "metadata": {
          "custom_id": @contrato.id.to_s,
          "notification_url": "https://erp7.tessi.com.br/webhooks/#{Webhook.find_by(tipo: :gerencianet).token}"
        },
        "customer": {
          "email": 'yoder@tessi.com.br'
        },
        "settings": {
          "payment_method": 'credit_card',
          "expire_at": (DateTime.now + 2.days).to_date.iso8601,
          "request_delivery_address": false
        }
      }
    end
  end
end
