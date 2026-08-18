# frozen_string_literal: true

class Devices::AirFiber::SnmpReader # rubocop:disable Style/ClassAndModuleChildren
  require 'snmp'

  CONFIG_OIDS = {
    role: 'SNMPv2-SMI::enterprises.41112.1.10.1.2.1.0',
    frequencia: 'SNMPv2-SMI::enterprises.41112.1.10.1.2.2.0',
    bandwidth: 'SNMPv2-SMI::enterprises.41112.1.10.1.2.4.0',
    linkname: 'SNMPv2-SMI::enterprises.41112.1.10.1.2.5.0'
  }.freeze

  STATUS_OIDS = {
    mac: 'SNMPv2-SMI::enterprises.41112.1.10.1.3.1.0',
    modelo: 'SNMPv2-SMI::enterprises.41112.1.10.1.3.2.0',
    firmware: 'SNMPv2-SMI::enterprises.41112.1.10.1.3.4.0'
  }.freeze

  # Colunas da tabela de estação (indexada pelo MAC do remoto — como um
  # enlace ponto-a-ponto só tem uma estação, pegamos a primeira linha).
  STATION_BASE = '1.3.6.1.4.1.41112.1.10.1.4.1'
  STATION_COLUMNS = {
    capacidade_tx: 3,
    capacidade_rx: 4,
    signal_chain0: 5,
    signal_chain1: 6,
    remote_mac: 11,
    remote_modelo: 12,
    remote_latencia: 22,
    distancia: 23,
    remote_ip: 25
  }.freeze

  ROLES = { '0' => 'master', '1' => 'slave' }.freeze

  COMMUNITY = ::Ubiquiti::Provisioner::SNMP_COMMUNITY

  attr_reader :device

  def initialize(device)
    @device = device
  end

  def coletar_informacoes
    with_snmp_manager do |manager|
      config = get_group(manager, CONFIG_OIDS)
      status = get_group(manager, STATUS_OIDS)
      station = station_row(manager)

      {
        mac: format_mac_value(status[:mac]),
        modelo: status[:modelo],
        firmware: status[:firmware],
        modo: ROLES[config[:role]],
        frequencia: config[:frequencia],
        canal_tamanho: config[:bandwidth],
        ssid: config[:linkname],
        signal_chain0: station[:signal_chain0],
        signal_chain1: station[:signal_chain1],
        signal: media_sinal(station),
        distancia: station[:distancia],
        tx_rate: rate_em_bps(station[:capacidade_tx]),
        rx_rate: rate_em_bps(station[:capacidade_rx]),
        remote_mac: format_mac_value(station[:remote_mac]),
        remote_modelo: station[:remote_modelo],
        remote_ip: format_ip_value(station[:remote_ip]),
        latencia: station[:remote_latencia]
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

  def station_row(manager)
    colunas = STATION_COLUMNS.transform_values { |n| "#{STATION_BASE}.#{n}" }
    linha = {}

    manager.walk(colunas.values) do |*varbinds|
      colunas.keys.each_with_index { |chave, i| linha[chave] = varbinds[i].value }
      break
    end

    linha
  end

  def media_sinal(station)
    valores = [station[:signal_chain0], station[:signal_chain1]].compact.map(&:to_i)
    return nil if valores.empty?

    (valores.sum / valores.size.to_f).round(1)
  end

  def rate_em_bps(capacidade_kbps)
    return nil if capacidade_kbps.blank?

    capacidade_kbps.to_i * 1000
  end

  def format_mac_value(value)
    bytes = value.to_s.bytes
    return nil if bytes.length != 6
    return nil if bytes.all?(&:zero?)

    bytes.map { |b| '%02X' % b }.join(':')
  end

  def format_ip_value(value)
    bytes = value.to_s.bytes
    return nil if bytes.length != 4

    bytes.join('.')
  end

  def valid_snmp_value?(value)
    value.present? &&
      %w[Null noSuchInstance noSuchObject].exclude?(value)
  end
end
