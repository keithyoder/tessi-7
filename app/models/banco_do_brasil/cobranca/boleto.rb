# frozen_string_literal: true

class BancoDoBrasil::Cobranca::Boleto < BancoDoBrasil::Cobranca
  include ActiveModel::Model

  attr_accessor :numero_convenio, :numero_carteira, :numero_variacao_carteira, :codigo_modalidade,
                :data_emissao, :data_vencimento, :valor_original, :valor_abatimento, :quantidade_dias_protesto,
                :indicador_aceite_titulo_vencido, :numero_dias_limite_recebimento, :codigo_aceite,
                :codigo_tipo_titulo, :descricao_tipo_titulo, :indicador_permissao_recebimento_parcial,
                :numero_titulo_beneficiario, :campo_utilizacao_beneficiario, :numero_titulo_cliente,
                :mensagem_bloqueto_ocorrencia, :desconto, :segundo_desconto, :terceiro_desconto, :juros_mora,
                :multa, :pagador, :beneficiario_final, :quantidade_dias_negativacao, :orgao_negativador,
                :indicador_pix

  def initialize # rubocop:disable Metrics/MethodLength
    super
    @numero_convenio = 3_128_557
    @numero_carteira = 17
    @numero_variacao_carteira = 35
    @quantidade_dias_protesto = 0
    @indicador_aceite_titulo_vencido = 'S'
    @numero_dias_limite_recebimento = 90
    @codigo_aceite = 'A'
    @codigo_tipo_titulo = 2
    @descricao_tipo_titulo = 'DM'
    @indicador_permissao_recebimento_parcial = 'N'
    @desconto = {
      tipo: 0,
      data_expiracao: nil,
      porcentagem: 0,
      valor: 0
    }
    @segundo_desconto = {
      data_expiracao: nil,
      porcentagem: 0,
      valor: 0
    }
    @terceiro_desconto = {
      data_expiracao: nil,
      porcentagem: 0,
      valor: 0
    }
    @juros_mora = {
      tipo: 0,
      porcentagem: 0,
      valor: 0
    }
    @multa = {
      tipo: 0,
      data: nil,
      porcentagem: 0,
      valor: 0
    }
    @pagador = {
      tipo_inscricao: 1,
      numero_inscricao: nil,
      nome: nil,
      endereco: nil,
      cep: nil,
      cidade: nil,
      bairro: nil,
      uf: nil,
      telefone: nil
    }
    @beneficiario_final = {
      tipo_inscricao: nil,
      numero_inscricao: nil,
      nome: nil
    }
  end

  def to_json(*_args) # rubocop:disable Metrics/MethodLength
    {
      numeroConvenio: @numero_convenio,
      numeroCarteira: @numero_carteira,
      numeroVariacaoCarteira: @numero_variacao_carteira,
      codigoModalidade: @codigo_modalidade,
      dataEmissao: @data_emissao,
      dataVencimento: format_date(@data_vencimento),
      valorOriginal: @valor_original,
      valorAbatimento: @valor_abatimento,
      quantidadeDiasProtesto: @quantidade_dias_protesto,
      indicadorAceiteTituloVencido: @indicador_aceite_titulo_vencido,
      numeroDiasLimiteRecebimento: @numero_dias_limite_recebimento,
      codigoAceite: @codigo_aceite,
      codigoTipoTitulo: @codigo_tipo_titulo,
      descricaoTipoTitulo: @descricao_tipo_titulo,
      indicadorPermissaoRecebimentoParcial: @indicador_permissao_recebimento_parcial,
      numeroTituloBeneficiario: @numero_titulo_beneficiario,
      campoUtilizacaoBeneficiario: @campo_utilizacao_beneficiario,
      numeroTituloCliente: @numero_titulo_cliente,
      mensagemBloquetoOcorrencia: @mensagem_bloqueto_ocorrencia,
      desconto: @desconto,
      segundoDesconto: @segundo_desconto,
      terceiroDesconto: @terceiro_desconto,
      jurosMora: @juros_mora,
      multa: @multa,
      pagador: @pagador.transform_keys! { |key| key.to_s.camelize(:lower) },
      beneficiarioFinal: @beneficiario_final.transform_keys! { |key| key.to_s.camelize(:lower) },
      quantidadeDiasNegativacao: @quantidade_dias_negativacao,
      orgaoNegativador: @orgao_negativador,
      indicadorPix: @indicador_pix
    }.to_json
  end

  def teste
    @data_vencimento = '2022-02-25'.to_date
    @valor_original = 49.90
    @numero_titulo_cliente = '00031285570057384637'
    @pagador[:numero_inscricao] = '96050176876'
    @pagador[:nome] = 'VALERIO DE AGUIAR ZORZATO'
    @pagador[:endereco] = 'Rua Joao Fernandes Vieira, 600'
    @pagador[:cep] = '50050903'
    @pagador[:cidade] = 'Recife'
    @pagador[:bairro] = 'Boa Vista'
    @pagador[:uf] = 'PE'
  end

  def registrar
    puts to_json
    self.class.post(
      "/boletos?gw-dev-app-key=#{Rails.application.credentials.gw_dev_app_key}",
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': "Bearer #{oauth_token}"
      },
      body: to_json
    )
  end
end
