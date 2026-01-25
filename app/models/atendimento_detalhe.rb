# frozen_string_literal: true

# == Schema Information
#
# Table name: atendimento_detalhes
#
#  id             :bigint           not null, primary key
#  descricao      :text
#  tipo           :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  atendente_id   :bigint
#  atendimento_id :bigint
#
class AtendimentoDetalhe < ApplicationRecord
  belongs_to :atendimento
  belongs_to :atendente, class_name: 'User'

  enum :tipo, {
    Presencial: 1,
    Telefone: 2,
    WhatsApp: 3,
    Facebook: 4,
    Email: 5
  }

  # Validações
  validates :descricao, presence: true
  validates :tipo, presence: true
  validate :nao_contem_dados_de_cartao?

  # Scopes
  scope :recentes, -> { order(created_at: :desc) }
  scope :por_tipo, ->(tipo) { where(tipo: tipo) }
  scope :do_atendente, ->(atendente) { where(atendente: atendente) }
  scope :do_periodo, ->(inicio, fim) { where(created_at: inicio..fim) }

  # Métodos públicos
  def tipo_icone
    {
      'Presencial' => '👤',
      'Telefone' => '📞',
      'WhatsApp' => '💬',
      'Facebook' => '📘',
      'Email' => '📧'
    }[tipo]
  end

  def resumo(limite: 100)
    descricao.truncate(limite, separator: ' ')
  end

  private

  def nao_contem_dados_de_cartao?
    return false if descricao.blank?

    texto_limpo = descricao.gsub(/[\s\-.]/, '')

    return false unless texto_limpo.match?(/\d{13,19}/) && parece_numero_cartao?(texto_limpo)

    errors.add(:descricao, 'não pode conter dados de cartão de crédito')
  end

  def parece_numero_cartao?(texto)
    numeros = texto.scan(/\d{13,19}/)
    numeros.any? { |num| valida_luhn?(num) }
  end

  # Algoritmo de Luhn para validar números de cartão
  def valida_luhn?(numero)
    digits = numero.chars.map(&:to_i).reverse

    sum = digits.each_with_index.sum do |digit, index|
      if index.odd?
        doubled = digit * 2
        doubled > 9 ? doubled - 9 : doubled
      else
        digit
      end
    end

    (sum % 10).zero?
  end
end
