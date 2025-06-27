# frozen_string_literal: true

module Efi
  class PixWebhook # rubocop:disable Style/Documentation
    CHAVE_PIX = 'fc831fd6-1cd0-4d48-a804-1fdf51fbf2aa'
    def initialize
      @cliente = Efi.cliente(
        certificate: 'vendor/producao.pem',
        client_id: 'Client_Id_c4e2a29034f02859e0558eb5741a81abc0b3b426',
        client_secret: 'Client_Secret_5f4c11834df3524877d711d09bbf2b93b274ea28',
        "x-skip-mtls-checking": 'true'
      )
    end

    def create
      params = {
        chave: CHAVE_PIX,
        ignorar: true
      }

      body = {
        webhookUrl: 'https://webhook.site/bfb6d6c7-6754-451b-b79a-087e2a7a2743'
      }
      puts @cliente.pixConfigWebhook(params: params, body: body)
    end

    def get
      @cliente.pixDetailWebhook(params: { chave: CHAVE_PIX })
    end
  end
end
