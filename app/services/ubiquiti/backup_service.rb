# frozen_string_literal: true

module Ubiquiti
  class BackupService
    def self.backup_all
      Ponto.radio.where(sistema: :Ubnt).find_each do |ponto|
        config = ConfigManager.new(
          ponto.ip.to_s,
          user: ponto.usuario.presence,
          password: ponto.senha.presence
        ).download_config

        UbiquitiBackup.store(ponto, config)
        Rails.logger.info("[Backup] #{ponto.nome} (#{ponto.ip}) OK")
      rescue StandardError => e
        Rails.logger.error("[Backup] #{ponto.nome} (#{ponto.ip}): #{e.message}")
      end
    end
  end
end
