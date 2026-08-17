# frozen_string_literal: true

# == Schema Information
#
# Table name: enlaces
#
#  id                :bigint           not null, primary key
#  canal             :string
#  capacidade_bytes  :bigint
#  fibra_cor         :integer
#  observacoes       :text
#  sinal_normal      :decimal(5, 2)
#  tecnologia        :integer          not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
class Enlace < ApplicationRecord
  include Ransackable

  has_many :extremidades, class_name: 'EnlaceExtremidade', dependent: :destroy, inverse_of: :enlace
  has_many :os, as: :infraestrutura, dependent: :nullify

  accepts_nested_attributes_for :extremidades

  enum :tecnologia, { Radio: 1, Fibra: 2 }, prefix: true
  enum :fibra_cor, Fibra::Cores::CORES

  scope :radio, -> { where(tecnologia: :Radio) }
  scope :fibra, -> { where(tecnologia: :Fibra) }

  validates :tecnologia, presence: true
  validates :capacidade_bytes, numericality: { greater_than: 0 }, allow_nil: true
  validate :duas_extremidades

  before_validation :limpar_campo_irrelevante

  RANSACK_ATTRIBUTES = %w[tecnologia].freeze
  RANSACK_ASSOCIATIONS = %w[extremidades].freeze

  def ponta_a
    extremidades.find(&:posicao_A?)
  end

  def ponta_b
    extremidades.find(&:posicao_B?)
  end

  # Exibe em Mb ou Gb dependendo da magnitude, sempre a partir do valor
  # canônico em bytes.
  def capacidade_formatada
    return nil if capacidade_bytes.blank?

    if capacidade_bytes >= 1_000_000_000
      "#{format_number(capacidade_bytes / 1_000_000_000.0)} Gb"
    else
      "#{format_number(capacidade_bytes / 1_000_000.0)} Mb"
    end
  end

  def sinal_normal_formatado
    return nil if sinal_normal.blank?

    "#{sinal_normal} dBm"
  end

  def to_s
    "#{ponta_a&.infraestrutura} ↔ #{ponta_b&.infraestrutura}"
  end

  private

  def format_number(valor)
    valor == valor.round ? valor.to_i.to_s : valor.round(2).to_s
  end

  def duas_extremidades
    return if extremidades.reject(&:marked_for_destruction?).size == 2

    errors.add(:base, 'um enlace precisa ter exatamente duas extremidades')
  end

  # Um enlace Radio não usa cor de fibra, e um enlace Fibra não usa canal —
  # zera o campo que não se aplica à tecnologia escolhida.
  def limpar_campo_irrelevante
    self.canal = nil if tecnologia_Fibra?
    self.fibra_cor = nil if tecnologia_Radio?
  end
end
