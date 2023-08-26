# frozen_string_literal: true

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

  def descricao
    "#{fabricante} #{modelo}"
  end
end
