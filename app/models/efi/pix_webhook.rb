# frozen_string_literal: true

module Efi
  class PixWebhook
    CHAVE_PIX = 'fc831fd6-1cd0-4d48-a804-1fdf51fbf2aa'
    def initialize
      pagamento_perfil = PagamentoPerfil.find_by(nome: 'Pix Automático')
      @cliente = Efi.cliente(
        certificate: Rails.application.credentials.efi_pix_certificate,
        client_id: pagamento_perfil.client_id,
        client_secret: pagamento_perfil.client_secret,
        'x-skip-mtls-checking': 'true'
      )
    end

    def create
      params = {
        chave: CHAVE_PIX,
        ignorar: ''
      }

      body = {
        webhookUrl: "https://erp7.tessi.com.br#{Webhook.find_by(tipo: :efi_pix).url}"
      }
      Rails.logger.debug @cliente.pixConfigWebhook(params: params, body: body)
    end

    def get
      @cliente.pixDetailWebhook(params: { chave: CHAVE_PIX })
    end
  end
end
