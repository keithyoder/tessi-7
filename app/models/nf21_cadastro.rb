# frozen_string_literal: true

require 'fixy/numeric'
require 'fixy/amount'
require 'fixy/date'
require 'digest'

class Nf21Cadastro < Fixy::Record
  include Fixy::Formatter::Alphanumeric
  include Fixy::Formatter::Numeric
  include Fixy::Formatter::Amount
  include Fixy::Formatter::Date
  set_line_ending Fixy::Record::LINE_ENDING_CRLF
  set_record_length 287

  # Fields Declaration:
  # -----------------------------------------------------------
  #       name              size  Range             Format
  # ------------------------------------------------------------

  field :cnpj_cpf,            14, '1-14',        :numeric
  field :ie,                  14, '15-28',       :alphanumeric
  field :razao_social,        35, '29-63',       :alphanumeric
  field :logradouro,          45, '64-108',      :alphanumeric
  field :numero,               5, '109-113',     :numeric
  field :complemento,         15, '114-128',     :alphanumeric
  field :cep,                  8, '129-136',     :alphanumeric
  field :bairro,              15, '137-151',     :alphanumeric
  field :municipio,           30, '152-181',     :alphanumeric
  field :uf,                   2, '182-183',     :alphanumeric
  field :telefone,            12, '184-195',     :alphanumeric
  field :codigo,              12, '196-207',     :alphanumeric
  field :terminal,            12, '208-219',     :alphanumeric
  field :uf_terminal,          2, '220-221',     :alphanumeric
  field :data_emissao,         8, '222-229',     :date
  field :modelo,               2, '230-231',     :numeric
  field :serie,                3, '232-234',     :alphanumeric
  field :numero_nf,            9, '235-243',     :numeric
  field :codigo_municipio,     7, '244-250',     :numeric
  field :brancos,              5, '251-255',     :alphanumeric
  field :autenticacao_digital, 32, '256-287',    :alphanumeric

  def initialize(nf)
    @nf = nf
  end

  field_value :cnpj_cpf,             -> { @nf.fatura.pessoa.cpf_cnpj }
  field_value :ie,                   -> { @nf.fatura.pessoa.ie.empty? ? 'ISENTO' : @nf.fatura.pessoa.ie }
  field_value :razao_social,         -> { @nf.fatura.pessoa.nome_sem_acentos }
  field_value :logradouro,           -> { @nf.fatura.pessoa.logradouro.nome.parameterize(separator: ' ').upcase }
  field_value :numero,               -> { @nf.fatura.pessoa.numero.to_i }
  field_value :complemento,          -> { @nf.fatura.pessoa.complemento.parameterize(separator: ' ').upcase }
  field_value :cep,                  -> { @nf.fatura.pessoa.logradouro.cep }
  field_value :bairro,               -> { @nf.fatura.pessoa.bairro.nome.parameterize(separator: ' ').upcase }
  field_value :municipio,            -> { @nf.fatura.pessoa.cidade.nome.encode('ISO-8859-14') }
  field_value :uf,                   -> { @nf.fatura.pessoa.cidade.estado.sigla }
  field_value :telefone,             -> { @nf.fatura.pessoa.telefone1.gsub(/\D/, '') }
  field_value :codigo,               -> { @nf.fatura.pessoa.id }
  field_value :terminal,             -> { @nf.terminal }
  field_value :uf_terminal,          -> { 'PE' }
  field_value :data_emissao,         -> { @nf.emissao }
  field_value :modelo,               -> { 21 }
  field_value :serie,                -> { @nf.serie }
  field_value :numero_nf,            -> { @nf.numero }
  field_value :codigo_municipio,     -> { @nf.fatura.pessoa.cidade.ibge }
  field_value :brancos,              -> { ' ' }

  def autenticacao_digital
    decorator = Fixy::Decorator::Default
    output = String.new
    current_position = 1
    current_record = 1

    while current_record <= 20

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
