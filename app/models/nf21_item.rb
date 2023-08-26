# frozen_string_literal: true

class Nf21Item < ApplicationRecord
  belongs_to :nf21

  scope :competencia, lambda { |mes|
                        joins(:nf21).where("date_trunc('month', nf21s.emissao) = ?", DateTime.parse("#{mes}-01"))
                      }

  def parsed_item(field)
    fixy_field(parse_item, field)
  end

  private

  def parse_item
    @parse_item ||= Nf21ItemRecord.parse(item.strip!)[:fields]
  end

  def fixy_field(record, field)
    hash = record.find { |h| h[:name] == field }
    hash[:value].strip
  end
end
