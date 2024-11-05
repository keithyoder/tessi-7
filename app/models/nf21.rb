# frozen_string_literal: true

# == Schema Information
#
# Table name: nf21s
#
#  id         :bigint           not null, primary key
#  cadastro   :text
#  emissao    :date
#  mestre     :text
#  numero     :integer
#  valor      :decimal(8, 2)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  fatura_id  :bigint
#
# Indexes
#
#  index_nf21s_on_fatura_id  (fatura_id)
#
class Nf21 < ApplicationRecord
  has_many :nf21_itens
  belongs_to :fatura
  scope :competencia, ->(mes) { where("date_trunc('month', emissao) = ?", DateTime.parse("#{mes}-01")) }

  after_create :gerar_registros

  def gerar_registros
    update!(
      cadastro: Nf21Cadastro.new(self).generate,
      mestre: Nf21Mestre.new(self).generate
    )
    nf21_itens.first_or_initialize.tap do |item|
      item.item = Nf21ItemRecord.new(self).generate
      item.save
    end
  end

  def referencia_item
    Nf21Item.competencia(mes)
            .select('count(*) as itens')
            .joins(:nf21)
            .where('nf21s.numero < ?', numero)[0].itens + 1
  end

  def parsed_mestre(field)
    fixy_field(parse_mestre, field)
  end

  def parsed_cadastro(field)
    fixy_field(parse_cadastro, field)
  end

  def mes
    emissao.strftime('%Y-%m')
  end

  def terminal
    "87#{fatura.contrato.id.to_s.rjust(9, '9')}"
  end

  def serie
    'U'
  end

  def modelo
    21
  end

  def tipo_utilizacao
    2
  end

  private

  def parse_mestre
    @parse_mestre ||= Nf21Mestre.parse(mestre.strip!)[:fields]
  end

  def parse_cadastro
    @parse_cadastro ||= Nf21Cadastro.parse(cadastro.encode('ISO-8859-14').strip!)[:fields]
  end

  def fixy_field(record, field)
    hash = record.find { |h| h[:name] == field }
    hash[:value].force_encoding('iso-8859-14').encode('utf-8').strip
  end
end
