# frozen_string_literal: true

class Devices::Ubiquiti::Provisioner < Devices::Provisioner # rubocop:disable Style/ClassAndModuleChildren
  SNMP_COMMUNITY = 'erp'
  SNMP_CONTACT = 'Tessi Telecom'

  DNS_PRIMARY = '8.8.8.8'
  DNS_SECONDARY = '8.8.4.4'

  TIMEZONE = 'BRT3'

  NTP_SERVER = '0.ubnt.pool.ntp.org'

  private

  def configurar(device)
    config = config_manager(device).download_config
    desired = desired_settings(device)

    return unless needs_update?(config, desired)

    config.merge!(desired)
    config_manager(device).upload_config(config)
    Rails.logger.info("[Provisioner] Updated config on #{deviceable} (#{deviceable.ip})")
  end

  def config_manager(device)
    ::Ubiquiti::ConfigManager.new(
      device.ip.to_s,
      user: device.effective_user,
      password: device.effective_password
    )
  end

  def desired_settings(device)
    {
      'snmp.status' => 'enabled',
      'snmp.community' => SNMP_COMMUNITY,
      'snmp.contact' => SNMP_CONTACT,
      'snmp.location' => localizacao_para(device),
      'resolv.host.1.name' => deviceable.to_s,
      'resolv.host.1.status' => 'enabled',
      'resolv.nameserver.1.ip' => DNS_PRIMARY,
      'resolv.nameserver.1.status' => 'enabled',
      'resolv.nameserver.2.ip' => DNS_SECONDARY,
      'resolv.nameserver.2.status' => 'enabled',
      'resolv.nameserver.status' => 'enabled',
      'ntpclient.1.server' => NTP_SERVER,
      'ntpclient.1.status' => 'enabled',
      'ntpclient.status' => 'enabled',
      'system.timezone' => TIMEZONE
    }
  end

  def needs_update?(config, desired)
    desired.any? { |key, value| config[key] != value }
  end

  # snmp.location espera o nome do servidor "pai" — Ponto já tem essa
  # relação direta; EnlaceExtremidade não, então cai no próprio
  # deviceable até esse conceito ser generalizado.
  def localizacao_para(_device)
    deviceable.respond_to?(:servidor) ? deviceable.servidor.nome : deviceable.to_s
  end
end
