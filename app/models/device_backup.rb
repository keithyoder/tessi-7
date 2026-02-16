# frozen_string_literal: true

# == Schema Information
#
# Table name: device_backups
#
#  id         :bigint           not null, primary key
#  checksum   :string           not null
#  config     :text             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  device_id  :bigint           not null
#
# Indexes
#
#  index_device_backups_on_device_id  (device_id)
#
# Foreign Keys
#
#  fk_rails_...  (device_id => devices.id)
#
class DeviceBackup < ApplicationRecord
  belongs_to :device

  validates :config, presence: true
  validates :checksum, presence: true

  before_validation :compute_checksum, if: -> { config.present? && checksum.blank? }

  # Armazena config se não for duplicata do último backup
  #
  # @param device [Device] o device associado
  # @param config_text [String] conteúdo bruto do arquivo de configuração
  # @return [DeviceBackup, false] o backup criado ou false se duplicata
  def self.store(device, config_text)
    digest = Digest::SHA256.hexdigest(config_text)

    # Pula se o último backup é idêntico
    return false if device.backups.order(created_at: :desc).pick(:checksum) == digest

    device.backups.create!(config: config_text, checksum: digest)
  end

  private

  def compute_checksum
    self.checksum = Digest::SHA256.hexdigest(config)
  end
end
