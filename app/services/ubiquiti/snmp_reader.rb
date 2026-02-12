# frozen_string_literal: true

module Ubiquiti
  class SnmpReader
    require 'snmp'

    OIDS = {
      uptime: 'SNMPv2-MIB::sysUpTime.0',
      ssid: 'SNMPv2-SMI::enterprises.41112.1.4.5.1.2.1',
      frequencia: 'SNMPv2-SMI::enterprises.41112.1.4.1.1.4.1',
      canal_tamanho: 'SNMPv2-SMI::enterprises.41112.1.4.5.1.14.1',
      conectados: 'SNMPv2-SMI::enterprises.41112.1.4.5.1.15.1',
      qualidade_airmax: 'SNMPv2-SMI::enterprises.41112.1.4.6.1.3.1',
      station_ccq: 'SNMPv2-SMI::enterprises.41112.1.4.5.1.7.1',
      modelo: '1.2.840.10036.3.1.2.1.3.5',
      firmware: '1.2.840.10036.3.1.2.1.4.5',
      sys_descr: '1.3.6.1.2.1.1.1.0',
      mac: '1.3.6.1.2.1.2.2.1.6.2'
    }.freeze

    COMMUNITY = Provisioner::SNMP_COMMUNITY

    attr_reader :ponto

    def initialize(ponto)
      @ponto = ponto
    end

    def coletar_informacoes
      with_snmp_manager do |manager|
        response = manager.get(OIDS.values)
        parse_response(response)
        result = parse_response(response)
        result[:modelo] = resolve_modelo(result)
        result
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

    def estatisticas_conexao
      info = coletar_informacoes
      {
        conectados: info[:conectados].to_i,
        qualidade_airmax: info[:qualidade_airmax].to_i,
        station_ccq: info[:station_ccq].to_i
      }
    rescue SNMP::RequestTimeout, Errno::EHOSTUNREACH
      { conectados: 0, qualidade_airmax: 0, station_ccq: 0 }
    end

    private

    def with_snmp_manager(&)
      SNMP::Manager.open(snmp_config, &)
    end

    def snmp_config
      {
        host: ponto.ip.to_s,
        community: COMMUNITY,
        port: 161,
        version: :SNMPv1,
        timeout: 2,
        retries: 1
      }
    end

    def resolve_modelo(result)
      modelo = result[:modelo]
      return modelo if valid_snmp_value?(modelo)

      # Walk the parent OID to find the model regardless of index
      with_snmp_manager do |manager|
        manager.walk('1.2.840.10036.3.1.2.1.3') do |vb|
          return vb.value.to_s if valid_snmp_value?(vb.value.to_s)
        end
      end
    end

    def parse_response(response)
      result = {}
      response.each_varbind do |vb|
        oid_key = OIDS.key(vb.name.to_s)
        result[oid_key] = vb.value.to_s if oid_key
      end
      result
    end

    def valid_snmp_value?(value)
      value.present? &&
        %w[Null noSuchInstance noSuchObject].exclude?(value)
    end
  end
end
