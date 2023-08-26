# frozen_string_literal: true

class Excecao < ApplicationRecord
  belongs_to :contrato
  enum tipo: { Bloqueio: 1, Desbloqueio: 2 }
  scope :validas_para_desbloqueio, lambda {
    where(tipo: :Desbloqueio)
    where("? BETWEEN DATE_TRUNC('day', created_at) and valido_ate", Date.today)
  }
  scope :validas_para_bloqueio, lambda {
    where(tipo: :Bloqueio)
    where("? BETWEEN DATE_TRUNC('day', created_at) and valido_ate", Date.today)
  }
end
