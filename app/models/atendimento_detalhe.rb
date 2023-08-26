# frozen_string_literal: true

class AtendimentoDetalhe < ApplicationRecord
  belongs_to :atendimento
  belongs_to :atendente, class_name: 'User'

  enum tipo: {
    Presencial: 1,
    Telefone: 2,
    WhatsApp: 3,
    Facebook: 4,
    Email: 5
  }

  validate :nao_contem_dados_de_cartao?

  private

  def nao_contem_dados_de_cartao?
    return unless descricao.gsub(/[^a-zA-Z0-9]/, '').match?(/\d{13,16}/)

    errors.add(:descricao, 'não pode ter dados de cartão')
  end
end
