# frozen_string_literal: true

# == Schema Information
#
# Table name: equipamentos
#
#  id         :bigint           not null, primary key
#  fabricante :string
#  modelo     :string
#  tipo       :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Equipamento < ApplicationRecord
  has_many :conexoes
  enum tipo: {
    ONU: 1,
    Radio: 2,
    OLT: 3,
    Radio_PtP: 4,
    Roteador: 5,
    Switch: 6
  }

  has_one_attached :imagem

  scope :cpe, -> { where(tipo: %i[ONU Radio]) }

  def descricao
    "#{fabricante} #{modelo}"
  end
end
