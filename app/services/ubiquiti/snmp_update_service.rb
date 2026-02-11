# frozen_string_literal: true

module Ubiquiti
  class SnmpUpdateService
    def self.update_all
      Ponto.radio.where(sistema: :Ubnt).find_each do |ponto|
        ponto.atualizar_snmp!
        Rails.logger.info("[SNMP Update] #{ponto.nome} (#{ponto.ip}) OK")
      rescue StandardError => e
        Rails.logger.error("[SNMP Update] #{ponto.nome} (#{ponto.ip}): #{e.message}")
      end
    end
  end
end
