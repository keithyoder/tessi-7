# frozen_string_literal: true

module Ubiquiti
  class Provisioner
    SNMP_COMMUNITY = 'erp'
    SNMP_CONTACT = 'Tessi Telecom'

    DNS_PRIMARY = '8.8.8.8'
    DNS_SECONDARY = '8.8.4.4'

    TIMEZONE = 'BRT3'

    NTP_SERVER = '0.ubnt.pool.ntp.org'

    attr_reader :ponto

    def initialize(ponto)
      @ponto = ponto
    end

    def apply!
      config = config_manager.download_config
      UbiquitiBackup.store(ponto, config)
      desired = desired_settings

      return unless needs_update?(config, desired)

      config.merge!(desired)
      config_manager.upload_config(config)
      Rails.logger.info("[Provisioner] Updated config on #{ponto.nome} (#{ponto.ip})")
    end

    def diff
      config = config_manager.download_config
      desired = desired_settings

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

    def desired_settings
      {
        # SNMP
        'snmp.status' => 'enabled',
        'snmp.community' => SNMP_COMMUNITY,
        'snmp.contact' => SNMP_CONTACT,
        'snmp.location' => ponto.servidor.nome,

        # DNS
        'resolv.host.1.name' => ponto.nome,
        'resolv.host.1.status' => 'enabled',
        'resolv.nameserver.1.ip' => DNS_PRIMARY,
        'resolv.nameserver.1.status' => 'enabled',
        'resolv.nameserver.2.ip' => DNS_SECONDARY,
        'resolv.nameserver.2.status' => 'enabled',
        'resolv.nameserver.status' => 'enabled',

        # NTP
        'ntpclient.1.server' => NTP_SERVER,
        'ntpclient.1.status' => 'enabled',
        'ntpclient.status' => 'enabled',

        # Timezone
        'system.timezone' => TIMEZONE
      }
    end

    def needs_update?(config, desired)
      desired.any? { |key, value| config[key] != value }
    end
  end
end
