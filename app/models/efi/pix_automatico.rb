# frozen_string_literal: true

module Efi
  class PixAutomatico # rubocop:disable Style/Documentation,Metrics/ClassLength
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

    def cancel
      resposta = @cliente.updatePixRecurring(
        body: { status: 'CANCELADA' },
        params: { id: @contrato.recorrencia_id }
      )
      puts resposta
      # @contrato.update(recorrencia_id: resposta['idRec'])
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
      @proxima_cobranca ||= begin
        fatura = @contrato.faturas.a_vencer.first
        return unless fatura.id_externo.present?

        resposta = @cliente.getChargeRecurring(params: { txid: fatura.id_externo })
        return resposta unless resposta['status'] == 400
      end
    end

    def reenviar_cobranca
      @cliente.retryChargeRecurring(
        params: { txid: @contrato.faturas.a_vencer.first.id_externo, data: 1.day.from_now.strftime('%Y-%m-%d') }
      )
    end

    def criar_cobranca
      cobranca = @cliente.createChargeRecurring(body: cobranca_body)
      puts cobranca
      @contrato.faturas.a_vencer.first.update(id_externo: cobranca['txid'])
    end

    private

    def get
      @cliente.getPixRecurring(params: { id: @contrato.recorrencia_id })
    end

    def location
      @location ||= @cliente.createLocationRecurring
    end

    def body # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
      cpf_cnpj = if @contrato.pessoa.cpf.present?
                   { vinculo: { devedor: { cpf: CPF.new(@contrato.pessoa.cpf).stripped.to_s } } }
                 else
                   { vinculo: { devedor: { cnpj: CNPJ.new(@contrato.pessoa.cnpj).stripped.to_s } } }
                 end
      {
        vinculo: {
          contrato: @contrato.id.to_s,
          devedor: {
            nome: @contrato.pessoa.nome.strip
          },
          objeto: @contrato.descricao_personalizada.presence || @contrato.plano.nome
        },
        loc: location['id'],
        calendario: {
          dataInicial: @contrato.faturas.a_vencer.first.vencimento.strftime('%Y-%m-%d'),
          periodicidade: 'MENSAL'
        },
        valor: {
          valorRec: format('%.2f',
                           @contrato.mensalidade_com_desconto)
        },
        politicaRetentativa: 'PERMITE_3R_7D'
      }.deep_merge(cpf_cnpj)
    end

    def cobranca_body # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      {
        "idRec": @contrato.recorrencia_id,
        "infoAdicional": @contrato.descricao_personalizada.presence || @contrato.plano.nome,
        "calendario": {
          "dataDeVencimento": [@contrato.faturas.a_vencer.first.vencimento,
                               Date.today + 3.days].max.strftime('%Y-%m-%d')
        },
        "valor": {
          "original": format(
            '%.2f',
            @contrato.mensalidade_com_desconto
          )
        },
        "ajusteDiaUtil": false,
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
