# frozen_string_literal: true

class UbiquitiBackup < ApplicationRecord
  belongs_to :ponto

  validates :config, presence: true
  validates :checksum, presence: true

  before_validation :compute_checksum, if: -> { config.present? && checksum.blank? }

  # Don't store duplicate configs
  def self.store(ponto, config_hash)
    raw = config_hash.map { |k, v| "#{k}=#{v}" }.join("\n") + "\n"
    digest = Digest::SHA256.hexdigest(raw)

    # Skip if latest backup is identical
    return false if ponto.ubiquiti_backups.order(created_at: :desc).pick(:checksum) == digest

    ponto.ubiquiti_backups.create!(config: raw, checksum: digest)
  end

  def to_hash
    config.each_line.with_object({}) do |line, hash|
      line = line.strip
      next if line.empty? || line.start_with?('#')

      key, value = line.split('=', 2)
      hash[key] = value
    end
  end

  private

  def compute_checksum
    self.checksum = Digest::SHA256.hexdigest(config)
  end
end
