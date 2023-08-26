# frozen_string_literal: true

require 'fixy/numeric'
require 'fixy/amount'
require 'fixy/date'
require 'digest'

class Nf21ItemRecord < Fixy::Record
  include Fixy::Formatter::Alphanumeric
  include Fixy::Formatter::Numeric
  include Fixy::Formatter::Amount
  include Fixy::Formatter::Date
  set_line_ending Fixy::Record::LINE_ENDING_CRLF
  set_record_length 331

  # Fields Declaration:
  # -----------------------------------------------------------
  #       name              size  Range             Format
  # ------------------------------------------------------------

  field :cnpj_cpf, 14, '1-14', :numeric
  field :uf,                     2, '15-16',      :alphanumeric
  field :classe_consumo,         1, '17-17',      :numeric
  field :tipo_utilizacao,        1, '18-18',      :numeric
  field :grupo_tensao,           2, '19-20',      :numeric
  field :data_emissao,           8, '21-28',      :date
  field :modelo,                 2, '29-30',      :numeric
  field :serie,                  3, '31-33',      :alphanumeric
  field :numero,                 9, '34-42',      :numeric
  field :cfop,                   4, '43-46',      :numeric
  field :ordem,                  3, '47-49',      :numeric
  field :codigo,                10, '50-59',      :numeric
  field :descricao,             40, '60-99',      :alphanumeric
  field :classificacao,          4, '100-103',    :numeric
  field :unidade,                6, '104-109',    :alphanumeric
  field :quantidade_contratada, 12, '110-121',    :numeric
  field :quantidade_medida,     12, '122-133',    :numeric
  field :valor_total,           11, '134-144',    :amount
  field :desconto,              11, '145-155',    :amount
  field :acrescimos,            11, '156-166',    :amount
  field :bc_icms,               11, '167-177',    :amount
  field :icms,                  11, '178-188',    :amount
  field :isentas,               11, '189-199',    :amount
  field :outros_valores,        11, '200-210',    :amount
  field :aliquota,               4, '211-214',    :amount
  field :situacao,               1, '215-215',    :alphanumeric
  field :referencia_item,        4, '216-219',    :alphanumeric
  field :contrato,              15, '220-234',    :alphanumeric
  field :quantidade_faturada,   12, '235-246',    :numeric
  field :tarifa,                11, '247-257',    :numeric
  field :aliquota_pis_pasep, 6, '258-263', :numeric
  field :valor_pis_pasep, 11, '264-274', :amount
  field :aliquota_cofins, 6, '275-280', :numeric
  field :valor_cofins, 11, '281-291', :amount
  field :desconto_judicial,      1, '292-292',    :alphanumeric
  field :tipo_isencao,           2, '293-294',    :numeric
  field :brancos,                5, '295-299',    :alphanumeric
  field :autenticacao_digital, 32, '300-331', :alphanumeric

  def initialize(nf)
    @nf = nf
  end

  field_value :cnpj_cpf,              -> { @nf.fatura.pessoa.cpf_cnpj }
  field_value :uf,                    -> { @nf.fatura.pessoa.cidade.estado.sigla }
  field_value :classe_consumo,        -> { 0 }
  field_value :tipo_utilizacao,       -> { @nf.tipo_utilizacao }
  field_value :grupo_tensao,          -> { 0 }
  field_value :data_emissao,          -> { @nf.emissao }
  field_value :modelo,                -> { @nf.modelo }
  field_value :serie,                 -> { @nf.serie }
  field_value :numero,                -> { @nf.numero }
  field_value :cfop,                  -> { @nf.fatura.cfop }
  field_value :ordem,                 -> { 1 }
  field_value :codigo,                -> { @nf.fatura.plano.id }
  field_value :descricao,             -> { @nf.fatura.contrato.descricao.parameterize(separator: ' ').upcase }
  field_value :classificacao,         -> { 102 }
  field_value :unidade,               -> { '' }
  field_value :quantidade_contratada, -> { 0 }
  field_value :quantidade_medida,     -> { 0 }
  field_value :valor_total,           -> { @nf.fatura.base_calculo_icms }
  field_value :desconto,              -> { 0 }
  field_value :acrescimos,            -> { 0 }
  field_value :bc_icms,               -> { 0 }
  field_value :icms,                  -> { @nf.fatura.valor_icms }
  field_value :isentas,               -> { 0 }
  field_value :outros_valores,        -> { @nf.fatura.base_calculo_icms }
  field_value :aliquota,              -> { 0 }
  field_value :situacao,              -> { 'N' }
  field_value :contrato,              -> { @nf.fatura.contrato.id }
  field_value :quantidade_faturada,   -> { 0 }
  field_value :tarifa,                -> { 0 }
  field_value :aliquota_pis_pasep,    -> { 0 }
  field_value :valor_pis_pasep,       -> { 0 }
  field_value :aliquota_cofins,       -> { 0 }
  field_value :valor_cofins,          -> { 0 }
  field_value :desconto_judicial,     -> { '' }
  field_value :tipo_isencao,          -> { 0 }
  field_value :brancos,               -> { '' }

  def referencia_item
    @nf.emissao.strftime('%y%m')
  end

  def autenticacao_digital
    decorator = Fixy::Decorator::Default
    output = String.new
    current_position = 1
    current_record = 1

    while current_record <= 37

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
