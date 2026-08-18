# frozen_string_literal: true

# == Schema Information
#
# Table name: enlace_extremidades
#
#  id                    :bigint           not null, primary key
#  infraestrutura_type   :string           not null
#  ip                    :inet
#  posicao               :integer          not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  enlace_id             :bigint           not null
#  infraestrutura_id     :bigint           not null
#
class EnlaceExtremidade < ApplicationRecord
  include Ransackable

  belongs_to :enlace, inverse_of: :extremidades
  belongs_to :infraestrutura, polymorphic: true
  has_one :device, as: :deviceable, dependent: :destroy

  enum :posicao, { A: 1, B: 2 }, prefix: true

  validates :posicao, presence: true, uniqueness: { scope: :enlace_id }
  validates :infraestrutura_type, inclusion: { in: %w[Servidor Ponto] }

  RANSACK_ATTRIBUTES = %w[posicao].freeze
  RANSACK_ASSOCIATIONS = %w[infraestrutura].freeze

  # Mesmo padrão de device_id= usado em Ponto
  def device_id
    device&.id
  end

  def device_id=(id)
    new_id = id.presence&.to_i
    return if device&.id == new_id
    return if new_id.blank?

    Device.find(new_id).update!(deviceable: self)
    reload_device
  end

  def sinal_atual
    return nil if device&.signal.blank?

    "#{device.signal} dBm"
  end

  delegate :to_s, to: :infraestrutura
end
