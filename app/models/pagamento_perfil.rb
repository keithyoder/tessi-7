# frozen_string_literal: true

# == Schema Information
#
# Table name: pagamento_perfis
#
#  id            :bigint           not null, primary key
#  agencia       :integer
#  ativo         :boolean          default(TRUE)
#  banco         :integer
#  carteira      :string
#  cedente       :integer
#  client_secret :string
#  conta         :integer
#  nome          :string
#  sequencia     :integer
#  tipo          :integer
#  variacao      :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  client_id     :string
#
class PagamentoPerfil < ApplicationRecord
  has_many :faturas, dependent: :restrict_with_exception
  has_many :contratos, dependent: :restrict_with_exception
  has_many :retornos, dependent: :restrict_with_exception
  enum tipo: { 'Boleto' => 3, 'Débito Automático' => 2, 'API' => 4 }
  scope :ativos, ->(perfil_atual = nil) { where('ativo').or(PagamentoPerfil.where(id: perfil_atual)) }

  def remessa(sequencia = 1)
    pagamentos = faturas_para_registrar + faturas_para_baixar + faturas_canceladas
    case banco
    when 33
      remessa_santander(pagamentos)
    when 1
      remessa_banco_brasil(pagamentos, sequencia)
    end
  end

  def proximo_nosso_numero
    faturas.select('MAX(nossonumero::bigint) as nossonumero')
           .where("nossonumero ~ E'^\\\\d+$'")
           .to_a[0][:nossonumero]
           .to_i
  end

  def liquidacoes(mes, meio_liquidacao)
    faturas.where("date_trunc('month', liquidacao) = ? and meio_liquidacao = ?", mes, meio_liquidacao)
  end

  def inadimplentes(mes)
    faturas.inadimplentes.where("date_trunc('month', vencimento) = ?", mes)
  end

  def meses
    faturas.select("date_trunc('month', vencimento) as mes")
           .where('vencimento < :agora or (liquidacao is null and liquidacao < :agora)', agora: DateTime.now)
           .group(:mes)
           .order(mes: :desc)
  end

  def forma_pagamento
    case tipo
    when 'Boleto', 'API'
      'Boleto Bancário'
    when 'Débito Automático'
      if nome == 'Cielo'
        'Cartão de Crédito'
      else
        nome
      end
    end
  end

  private

  def remessa_banco_brasil(pagamentos, sequencia)
    Brcobranca::Remessa::Cnab400::BancoBrasil.new(
      remessa_attr(pagamentos).merge(
        sequencial_remessa: sequencia,
        variacao_carteira: variacao.to_s,
        convenio: cedente.to_s,
        convenio_lider: cedente.to_s
      )
    )
  end

  def remessa_santander(pagamentos)
    Brcobranca::Remessa::Cnab400::Santander.new(
      remessa_attr(pagamentos).merge(
        codigo_transmissao: santander_codigo_transmissao,
        codigo_carteira: variacao.to_s
      )
    )
  end

  def remessa_attr(pagamentos)
    {
      carteira: carteira.to_s,
      agencia: agencia.to_s,
      conta_corrente: conta.to_s,
      digito_conta: '1',
      empresa_mae: 'TESSI Tec. em Seg. e Sistemas',
      documento_cedente: Setting.cnpj,
      pagamentos: pagamentos
    }
  end

  def santander_codigo_transmissao
    "#{agencia}0#{cedente}#{conta.to_s.rjust(10, '0')}"[0...20]
  end

  def faturas_com_numero
    faturas.eager_load(%i[pessoa logradouro bairro cidade estado plano])
           .where.not(nossonumero: '')
  end

  def faturas_para_registrar
    # registrar todos os boletos com vencimento nos proximos 30 dias
    # e que nao foram liquidados ainda e nao foram registrados anteriormente.
    faturas_com_numero.where(
      vencimento: Time.zone.today..30.days.from_now,
      cancelamento: nil,
      liquidacao: nil,
      registro_id: nil
    ).map(&:remessa)
  end

  def faturas_para_baixar
    # baixar todos os boletos que foram liquidados nos ultimos 30 dias
    # nao por meio bancario ainda e nao foram baixados anteriormente.
    faturas_com_numero.where(
      retorno_id: nil,
      baixa_id: nil,
      liquidacao: 1.month.ago..Time.zone.today
    ).where.not(liquidacao: nil, registro_id: nil).map(&:remessa)
  end

  def faturas_antigas
    # baixar todos os boletos que foram liquidados nos ultimos 30 dias
    # nao por meio bancario ainda e nao foram baixados anteriormente.
    faturas_com_numero.where(
      retorno_id: nil,
      baixa_id: nil,
      liquidacao: nil,
      vencimento: 4.months.ago..2.months.ago
    ).where.not(registro_id: nil).map(&:remessa)
  end

  def faturas_canceladas
    # baixar todos os boletos que foram canceladas e nao foram baixados anteriormente.
    faturas_com_numero.where(
      retorno_id: nil,
      baixa_id: nil
    ).where.not(cancelamento: nil, registro_id: nil).map(&:remessa)
  end
end
