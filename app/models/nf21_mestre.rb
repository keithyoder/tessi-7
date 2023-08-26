# frozen_string_literal: true

require 'fixy/numeric'
require 'fixy/amount'
require 'fixy/date'
require 'digest'

class Nf21Mestre < Fixy::Record
  include Fixy::Formatter::Alphanumeric
  include Fixy::Formatter::Numeric
  include Fixy::Formatter::Amount
  include Fixy::Formatter::Date
  set_line_ending Fixy::Record::LINE_ENDING_CRLF
  set_record_length 425

  # Fields Declaration:
  # -----------------------------------------------------------
  #       name              size  Range             Format
  # ------------------------------------------------------------

  field :cnpj_cpf,            14, '1-14',        :numeric
  field :ie,                  14, '15-28',       :alphanumeric
  field :razao_social,        35, '29-63',       :alphanumeric
  field :uf,                   2, '64-65',       :alphanumeric
  field :classe_consumo,       1, '66-66',       :numeric
  field :tipo_utilizacao,      1, '67-67',       :numeric
  field :grupo_tensao,         2, '68-69',       :numeric
  field :codigo_assinante, 12, '70-81', :alphanumeric
  field :data_emissao,         8, '82-89',       :date
  field :modelo,               2, '90-91',       :numeric
  field :serie,                3, '92-94',       :alphanumeric
  field :numero,               9, '95-103',      :numeric
  field :codigo_autenticacao, 32, '104-135',     :alphanumeric
  field :valor_total,         12, '136-147',     :amount
  field :bc_icms,             12, '148-159',     :amount
  field :icms,                12, '160-171',     :amount
  field :isentas,             12, '172-183',     :amount
  field :outros_valores,      12, '184-195',     :amount
  field :situacao,             1, '196-196',     :alphanumeric
  field :referencia,           4, '197-200',     :numeric
  field :referencia_item,      9, '201-209',     :numeric
  field :numero_terminal, 12, '210-221', :alphanumeric
  field :tipo_campo_1,         1, '222-222',     :numeric
  field :tipo_cliente,         2, '223-224',     :numeric
  field :subclasse_consumo,    2, '225-226',     :numeric
  field :terminal_principal,  12, '227-238',     :alphanumeric
  field :cnpj_emitente,       14, '239-252',     :numeric
  field :fatura_comercial,    20, '253-272',     :alphanumeric
  field :valor_fatura,        12, '273-284',     :amount
  field :leitura_anterior,     8, '285-292',     :date
  field :leitura_atual,        8, '293-300',     :date
  field :brancos_1, 50, '301-350', :alphanumeric
  field :brancos_2, 8, '351-358', :numeric
  field :informacoes, 30, '359-388', :alphanumeric
  field :brancos_3, 5, '389-393', :alphanumeric
  field :autenticacao_digital, 32, '394-425', :alphanumeric

  def initialize(nf)
    @nf = nf
  end

  field_value :cnpj_cpf,            -> { @nf.fatura.pessoa.cpf_cnpj }
  field_value :ie,                  -> { @nf.fatura.pessoa.ie.empty? ? 'ISENTO' : @nf.fatura.pessoa.ie }
  field_value :razao_social,        -> { @nf.fatura.pessoa.nome_sem_acentos }
  field_value :uf,                  -> { @nf.fatura.pessoa.cidade.estado.sigla }
  field_value :classe_consumo,      -> { 0 }
  field_value :tipo_utilizacao,     -> { @nf.tipo_utilizacao }
  field_value :grupo_tensao,        -> { 0 }
  field_value :codigo_assinante,    -> { @nf.fatura.pessoa.id }
  field_value :data_emissao,        -> { @nf.emissao }
  field_value :modelo,              -> { @nf.modelo }
  field_value :serie,               -> { @nf.serie }
  field_value :numero,              -> { @nf.numero }
  field_value :valor_total,         -> { @nf.fatura.base_calculo_icms }
  field_value :bc_icms,             -> { 0 }
  field_value :icms,                -> { @nf.fatura.valor_icms }
  field_value :isentas,             -> { 0 }
  field_value :outros_valores,      -> { @nf.fatura.base_calculo_icms }
  field_value :situacao,            -> { 'N' }
  field_value :referencia_item,     -> { @nf.referencia_item }
  field_value :numero_terminal,     -> { @nf.terminal }
  field_value :subclasse_consumo,   -> { 0 }
  field_value :terminal_principal,  -> { @nf.terminal }
  field_value :cnpj_emitente,       -> { Setting.cnpj }
  field_value :fatura_comercial,    -> { @nf.fatura.id }
  field_value :valor_fatura,        -> { @nf.fatura.base_calculo_icms }
  # futuramente vai precisar colocar data inicio e data final da prestacao de servicos.
  field_value :leitura_anterior,    -> { nil }
  field_value :leitura_atual,       -> { nil }
  #########
  field_value :brancos_1,           -> { '' }
  field_value :brancos_2,           -> { 0 }
  field_value :informacoes,         -> { '' }
  field_value :brancos_3,           -> { '' }

  def formatted_value(field_number)
    field = record_fields[field_number]
    raise StandardError, "Undefined field for position #{field_number}" unless field

    # We will first retrieve the value, then format it
    method          = field[:name]
    value           = send(method)
    formatted_value = format_value(value, field[:size], field[:type])
    Fixy::Decorator::Default.field(formatted_value, 1, field_number, method, field[:size], field[:type])
  end

  def tipo_campo_1
    if @nf.fatura.pessoa.pessoa_fisica?
      2
    else
      1
    end
  end

  def referencia
    @nf.emissao.strftime('%y%m')
  end

  def tipo_cliente
    if @nf.fatura.pessoa.pessoa_fisica?
      3
    else
      1
    end
  end

  def codigo_autenticacao
    cnpj = format_value(@nf.fatura.pessoa.cpf_cnpj, 14, :numeric)
    nf = format_value(@nf.numero, 9, :numeric)
    valor = format_value(@nf.fatura.base_calculo_icms, 12, :amount)
    #icms = format_value(@nf.fatura.base_calculo_icms, 12, :amount)
    icms = format_value(0, 12, :amount)
    icms_valor = format_value(@nf.fatura.valor_icms, 12, :amount)
    emissao = format_value(@nf.emissao, 8, :date)
    emitente = format_value(Setting.cnpj, 14, :numeric)
    Digest::MD5.new.hexdigest(cnpj + nf + valor + icms + icms_valor + emissao + emitente)
  end

  def autenticacao_digital
    decorator = Fixy::Decorator::Default
    output = String.new
    current_position = 1
    current_record = 1

    while current_record <= 35

      field = record_fields[current_position]
      raise StandardError, "Undefined field for position #{current_position}" unless field

      # We will first retrieve the value, then format it
      method          = field[:name]
      value           = send(method)
      formatted_value = format_value(value, field[:size], field[:type])
      formatted_value = decorator.field(
        formatted_value,
        current_record,
        current_position,
        method,
        field[:size],
        field[:type]
      )

      output << formatted_value
      current_position = field[:to] + 1
      current_record += 1
    end
    Digest::MD5.new.hexdigest(output).downcase
  end
end
