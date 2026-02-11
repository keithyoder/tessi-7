# frozen_string_literal: true

module Ubiquiti
  class SnmpProvisioner
    COMMUNITY = 'erp'
    CONTACT = 'Tessi Telecom'

    attr_reader :ponto

    def initialize(ponto)
      @ponto = ponto
    end

    # Returns true if changes were made, false if already in sync
    def apply!
      config = config_manager.download_config
      UbiquitiBackup.store(ponto, config)
      desired = desired_snmp_settings

      return unless needs_update?(config, desired)

      config.merge!(desired)
      config_manager.upload_config(config)
      Rails.logger.info("[SNMP] Updated config on #{ponto.nome} (#{ponto.ip})")
    end

    # Just check without making changes
    def in_sync?
      config = config_manager.download_config
      !needs_update?(config, desired_snmp_settings)
    end

    # Returns a hash of what would change
    def diff
      config = config_manager.download_config
      desired = desired_snmp_settings

      desired.each_with_object({}) do |(key, value), changes|
        current = config[key]
        changes[key] = { current: current, desired: value } if current != value
      end
    end

    private

    def config_manager
      @config_manager ||= ConfigManager.new(
        ponto.ip.to_s,
        user: ponto.usuario.presence || 'ubnt',
        password: ponto.senha.presence || 'ubnt'
      )
    end

    def desired_snmp_settings
      {
        'snmp.status' => 'enabled',
        'snmp.community' => COMMUNITY,
        'snmp.contact' => CONTACT,
        'snmp.location' => ponto.servidor.nome
      }
    end

    def needs_update?(config, desired)
      desired.any? { |key, value| config[key] != value }
    end
  end
end
