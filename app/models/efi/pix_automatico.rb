# frozen_string_literal: true

module Efi
  class PixAutomatico # rubocop:disable Style/Documentation
    def initialize(contrato)
      @contrato = contrato
      @cliente = Efi.cliente(
        client_id: contrato.pagamento_perfil.client_id,
        client_secret: contrato.pagamento_perfil.client_secret,
        certificate: Rails.application.credentials.efi_pix_certificate
      )
    end

    def create
      resposta = @cliente.createPixRecurring(body: body)
      @contrato.update(recorrencia_id: resposta['idRec'])
    end

    def pix
      @pix ||= get
    end

    def status
      pix['status']
    end

    def banco
      Efi::IspdParticipantes[pix.dig('pagador', 'ispbParticipante').to_i]
    end

    def qrcode
      pix.dig('dadosQR', 'pixCopiaECola')
    end

    def qrcode_base64
      return unless qrcode.present?

      ::RQRCode::QRCode.new(qrcode, level: :q).as_png(margin: 0).to_data_url
    end

    def cpf_pagador
      CPF.new(pix.dig('pagador', 'cpf'))
    end

    def list
      @cliente.listPixRecurring(params: { inicio: '2025-06-25T16:01:35Z', fim: '2025-07-01T16:01:35Z' })
    end

    def cobrancas
      @cliente.listChargesRecurring(params: { inicio: '2025-06-25T16:01:35Z', fim: '2025-07-01T16:01:35Z' })
    end

    def proxima_cobranca
      fatura = @contrato.faturas.em_aberto.first
      return unless fatura.id_externo.present?

      @cliente.getChargeRecurring(params: { txid: fatura.id_externo })
    end

    def criar_cobranca
      cobranca = @cliente.createChargeRecurring(body: cobranca_body)
      @contrato.faturas.em_aberto.first.update(id_externo: cobranca['txid'])
    end

    private

    def get
      @cliente.getPixRecurring(params: { id: @contrato.recorrencia_id })
    end

    def location
      @location ||= @cliente.createLocationRecurring
    end

    def body # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
      {
        vinculo: {
          contrato: @contrato.id.to_s,
          devedor: {
            cpf: CPF.new(@contrato.pessoa.cpf).stripped.to_s,
            nome: @contrato.pessoa.nome.strip
          },
          objeto: @contrato.descricao_personalizada.presence || @contrato.plano.nome
        },
        loc: location['id'],
        calendario: {
          dataInicial: @contrato.faturas.em_aberto.first.vencimento.strftime('%Y-%m-%d'),
          periodicidade: 'MENSAL'
        },
        valor: {
          valorRec: format('%.2f', @contrato.plano.valor_com_desconto)
        },
        politicaRetentativa: 'PERMITE_3R_7D'
      }
    end

    def cobranca_body # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      {
        "idRec": @contrato.recorrencia_id,
        "infoAdicional": @contrato.descricao_personalizada.presence || @contrato.plano.nome,
        "calendario": {
          "dataDeVencimento": [@contrato.faturas.em_aberto.first.vencimento,
                               Date.today + 2.days].max.strftime('%Y-%m-%d')
        },
        "valor": {
          "original": format('%.2f', @contrato.plano.valor_com_desconto)
        },
        "ajusteDiaUtil": true,
        "devedor": {
          "cep": @contrato.pessoa.logradouro.cep,
          "cidade": @contrato.pessoa.cidade.nome,
          "logradouro": @contrato.pessoa.endereco.strip,
          "uf": @contrato.pessoa.estado.sigla
        },
        "recebedor": {
          "agencia": '0001',
          "conta": @contrato.pagamento_perfil.conta.to_s,
          "tipoConta": 'PAGAMENTO'
        }
      }
    end
  end
end
