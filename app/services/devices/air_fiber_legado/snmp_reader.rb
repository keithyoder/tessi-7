# frozen_string_literal: true

class Devices::AirFiberLegado::SnmpReader # rubocop:disable Style/ClassAndModuleChildren
  require 'snmp'

  CONFIG_OIDS = {
    role: 'SNMPv2-SMI::enterprises.41112.1.3.1.1.3.0',
    linkname: 'SNMPv2-SMI::enterprises.41112.1.3.1.1.14.0'
  }.freeze

  STATUS_OIDS = {
    firmware: 'SNMPv2-SMI::enterprises.41112.1.3.2.1.40.0',
    status: 'SNMPv2-SMI::enterprises.41112.1.3.2.1.42.0',
    distancia_m: 'SNMPv2-SMI::enterprises.41112.1.3.2.1.4.0',
    tx_power_eirp: 'SNMPv2-SMI::enterprises.41112.1.3.2.1.9.0',
    signal_chain0: 'SNMPv2-SMI::enterprises.41112.1.3.2.1.11.0',
    signal_chain1: 'SNMPv2-SMI::enterprises.41112.1.3.2.1.14.0',
    remote_mac: 'SNMPv2-SMI::enterprises.41112.1.3.2.1.45.0',
    remote_ip: 'SNMPv2-SMI::enterprises.41112.1.3.2.1.46.0'
  }.freeze

  ROLES = { '1' => 'master', '2' => 'slave' }.freeze

  COMMUNITY = ::Ubiquiti::Provisioner::SNMP_COMMUNITY

  attr_reader :device

  def initialize(device)
    @device = device
  end

  def coletar_informacoes
    with_snmp_manager do |manager|
      config = get_group(manager, CONFIG_OIDS)
      status = get_group(manager, STATUS_OIDS)

      {
        mac: resolve_mac(manager),
        firmware: status[:firmware],
        modo: ROLES[config[:role]],
        ssid: config[:linkname],
        status: status[:status],
        distancia: status[:distancia_m],
        tx_power_eirp: status[:tx_power_eirp],
        signal_chain0: status[:signal_chain0],
        signal_chain1: status[:signal_chain1],
        signal: media_sinal(status),
        remote_mac: format_mac_value(status[:remote_mac]) || status[:remote_mac],
        remote_ip: status[:remote_ip]
      }
    end
  end

  def acessivel?
    with_snmp_manager do |manager|
      manager.get(['SNMPv2-MIB::sysUpTime.0'])
      true
    end
  rescue SNMP::RequestTimeout, Errno::EHOSTUNREACH
    false
  end

  private

  def with_snmp_manager(&)
    SNMP::Manager.open(snmp_config, &)
  end

  def snmp_config
    {
      host: device.ip.to_s,
      community: COMMUNITY,
      port: 161,
      version: :SNMPv1,
      timeout: 2,
      retries: 1
    }
  end

  def get_group(manager, oids)
    response = manager.get(oids.values)
    result = {}
    response.each_varbind do |vb|
      key = oids.key(vb.name.to_s)
      next unless key
      next unless valid_snmp_value?(vb.value.to_s)

      result[key] = vb.value.to_s
    end
    result
  end

  # Endereço próprio via tabela padrão ifPhysAddress — o índice varia
  # por unidade (visto índice 3 em um dispositivo), então caminha a
  # tabela inteira e usa o primeiro valor válido, igual à correção já
  # feita em Ubiquiti::SnmpReader.
  def resolve_mac(manager)
    manager.walk('1.3.6.1.2.1.2.2.1.6') do |vb|
      valor = format_mac_value(vb.value)
      return valor if valor
    end
    nil
  end

  def media_sinal(status)
    valores = [status[:signal_chain0], status[:signal_chain1]].compact.map(&:to_i)
    return nil if valores.empty?

    (valores.sum / valores.size.to_f).round(1)
  end

  def format_mac_value(value)
    bytes = value.to_s.bytes
    return nil if bytes.length != 6
    return nil if bytes.all?(&:zero?)

    bytes.map { |b| '%02X' % b }.join(':')
  end

  def valid_snmp_value?(value)
    value.present? &&
      %w[Null noSuchInstance noSuchObject].exclude?(value)
  end
end
