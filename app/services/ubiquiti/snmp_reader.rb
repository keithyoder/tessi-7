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
      station_ccq: 'SNMPv2-SMI::enterprises.41112.1.4.5.1.7.1'
    }.freeze

    COMMUNITY = SnmpProvisioner::COMMUNITY

    attr_reader :ponto

    def initialize(ponto)
      @ponto = ponto
    end

    def coletar_informacoes
      with_snmp_manager do |manager|
        response = manager.get(OIDS.values)
        parse_response(response)
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

    def parse_response(response)
      result = {}
      response.each_varbind do |vb|
        oid_key = OIDS.key(vb.name.to_s)
        result[oid_key] = vb.value.to_s if oid_key
      end
      result
    end
  end
end
