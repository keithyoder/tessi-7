# frozen_string_literal: true

class BancoDoBrasil::Pix::Cobranca < BancoDoBrasil::Pix
  include ActiveModel::Model

  attr_accessor :txid, :calendario, :devedor, :valor, :chave, :solictacao_pagador, :info_adicionais

  def initialize # rubocop:disable Metrics/MethodLength
    super
    @calendario = {
      expiracao: nil,
      data_de_vencimento: nil,
      validade_apos_vencimento: nil
    }
    @devedor = {
      cnpj: nil,
      cpf: nil,
      nome: nil,
      logradouro: nil,
      cidade: nil,
      uf: nil,
      cep: nil
    }
    @valor = {
      original: 0,
      abatimento: {
        modalidade: nil,
        valor_perc: nil
      },
      desconto: {
        modalidade: nil,
        desconto_data_fixa: nil,
        valor_perc: nil

      },
      juros: {
        modalidade: nil,
        valor_perc: nil
      },
      multa: {
        modalidade: nil,
        valor_perc: nil
      }
    }
    @chave = nil
    @solicitacao_pagador = nil
    @info_adicionais = [
      {
        nome: 'Campo 1',
        valor: nil
      }
    ]
  end

  def to_json(*_args)
    {
      calendario: @calendario.transform_keys { |key| key.to_s.camelize(:lower) },
      devedor: @devedor.transform_keys { |key| key.to_s.camelize(:lower) },
      valor: @valor.transform_keys { |key| key.to_s.camelize(:lower) },
      chave: @chave,
      solictacaoPagador: @solicitacao_pagador,
      infoAdicionais: @info_adicionais
    }.to_json
  end

  def teste
    @calendario[:data_de_vencimento] = '2022-03-01'.to_date
    @valor[:original] = 49.90
    @txid = '57384637'
    @devedor[:cpf] = '96050176876'
    @devedor[:nome] = 'VALERIO DE AGUIAR ZORZATO'
    @devedor[:logradouro] = 'Rua Joao Fernandes Vieira, 600'
    @devedor[:cep] = '50050903'
    @devedor[:cidade] = 'Recife'
    @devedor[:uf] = 'PE'
    @solicitacao_pagador = 'Teste'
    @chave = 'financeiro@tessi.com.br'
  end

  def registrar
    puts to_json
    self.class.put(
      "/cob/#{@txid}?gw-dev-app-key=#{Rails.application.credentials.gw_dev_app_key}",
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': "Bearer #{oauth_token}"
      },
      body: to_json
    )
  end
end
