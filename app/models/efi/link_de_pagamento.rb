# frozen_string_literal: true

# Esta classe cria um link de pagamento para uma fatura específica.
# Ela cria uma fatura duplicada com vencimento daqui a  2 dias altera
# o perfil de pagamento "Link de Pagamento".  Depois cancela a fatura original
# e cria um link de pagamento usando a API do Efi.
#
# Exemplo de uso:
#   fatura = Fatura.find(123)
#   link_pagamento = Efi::LinkDePagamento.new(fatura)
#   link_pagamento.create
#
module Efi
  class LinkDePagamento
    def initialize(fatura)
      @fatura = fatura
      @cliente = Efi.cliente(
        client_id: perfil.client_id,
        client_secret: perfil.client_secret
      )
    end

    def create
      resposta = @cliente.createOneStepLink(body: body)
      Rails.logger.debug resposta
      @fatura.update(cancelamento: Time.zone.today)
      fatura_nova.update(
        link: resposta['data']['payment_url'],
        id_externo: resposta['data']['charge_id']
      )
    end

    private

    def fatura_nova
      @fatura_nova ||= @fatura.dup.tap do |f|
        f.vencimento = (DateTime.now + 2.days).to_date
        f.pagamento_perfil = perfil
        f.save!
      end
    end

    def perfil
      return @perfil if defined?(@perfil)

      @perfil = PagamentoPerfil.find_by(banco: 365, nome: 'Link de Pagamento')
    end

    def body
      {
        items: [
          {
            amount: 1,
            name: fatura_nova.contrato.descricao,
            value: (fatura_nova.valor * 100).to_i
          }
        ],
        metadata: {
          custom_id: fatura_nova.id.to_s,
          notification_url: "https://erp7.tessi.com.br/webhooks/#{Webhook.find_by(tipo: :gerencianet).token}"
        },
        customer: {
          email: 'yoder@tessi.com.br'
        },
        settings: {
          payment_method: 'credit_card',
          expire_at: (DateTime.now + 2.days).to_date.iso8601,
          request_delivery_address: false
        }
      }
    end
  end
end
