# frozen_string_literal: true

# == Schema Information
#
# Table name: devices
#
#  id              :bigint           not null, primary key
#  deviceable_type :string           not null
#  firmware        :string
#  last_seen_at    :datetime
#  mac             :string
#  properties      :jsonb
#  senha           :string
#  type            :string           not null
#  usuario         :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  deviceable_id   :bigint           not null
#  equipamento_id  :bigint
#
# Indexes
#
#  index_devices_on_deviceable                         (deviceable_type,deviceable_id)
#  index_devices_on_deviceable_type_and_deviceable_id  (deviceable_type,deviceable_id) UNIQUE
#  index_devices_on_equipamento_id                     (equipamento_id)
#  index_devices_on_mac                                (mac)
#  index_devices_on_properties                         (properties) USING gin
#  index_devices_on_type                               (type)
#
# Foreign Keys
#
#  fk_rails_...  (equipamento_id => equipamentos.id)
#
class Device < ApplicationRecord
  belongs_to :deviceable, polymorphic: true
  belongs_to :equipamento, optional: true
  has_many :backups, class_name: 'DeviceBackup', dependent: :destroy

  validates :deviceable_type, inclusion: { in: %w[Ponto Conexao] }
  validates :mac, uniqueness: true, allow_nil: true

  def ip
    deviceable.ip.to_s
  end

  def name
    case deviceable
    when Ponto then deviceable.nome
    when Conexao then "#{deviceable.pessoa.nome} #{deviceable.observacao.to_s.first(10)}".strip
    end
  end

  def servidor_nome
    case deviceable
    when Ponto then deviceable.servidor.nome
    when Conexao then deviceable.ponto.servidor.nome
    end
  end

  def ap?
    deviceable_type == 'Ponto'
  end

  def effective_user
    usuario.presence || default_user
  end

  def effective_password
    senha.presence || default_password
  end

  private

  def default_user = 'admin'
  def default_password = nil
end
