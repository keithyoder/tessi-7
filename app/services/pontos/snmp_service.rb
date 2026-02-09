# frozen_string_literal: true

module Pontos
  # Serviço para coletar informações SNMP de pontos (Access Points Ubiquiti)
  #
  # Este serviço encapsula toda a lógica de comunicação SNMP,
  # removendo dependências de rede do modelo Ponto.
  #
  # Uso:
  #   service = Pontos::SnmpService.new(ponto)
  #   info = service.coletar_informacoes
  #   # => { ssid: "Tessi-5G", frequencia: "5180", canal_tamanho: "20" }
  #
  #   # Atualizar o ponto com as informações coletadas
  #   service.atualizar_ponto!
  #
  class SnmpService
    require 'snmp'

    # OIDs SNMP para equipamentos Ubiquiti
    # https://community.ui.com/questions/SNMP-OID-for-UBNT-AirMax/
    SNMP_OIDS = {
      uptime: 'SNMPv2-MIB::sysUpTime.0',
      ssid: 'SNMPv2-SMI::enterprises.41112.1.4.5.1.2.1',
      frequencia: 'SNMPv2-SMI::enterprises.41112.1.4.1.1.4.1',
      canal_tamanho: 'SNMPv2-SMI::enterprises.41112.1.4.5.1.14.1',
      conectados: 'SNMPv2-SMI::enterprises.41112.1.4.5.1.15.1',
      qualidade_airmax: 'SNMPv2-SMI::enterprises.41112.1.4.6.1.3.1',
      station_ccq: 'SNMPv2-SMI::enterprises.41112.1.4.5.1.7.1'
    }.freeze

    attr_reader :ponto

    def initialize(ponto)
      @ponto = ponto
    end

    # Coleta informações SNMP do ponto
    #
    # @return [Hash] hash com as informações coletadas
    # @raise [SNMP::RequestTimeout] se o ponto não responder
    def coletar_informacoes
      with_snmp_manager do |manager|
        response = manager.get(SNMP_OIDS.values)
        parse_response(response)
      end
    end

    # Coleta informações e atualiza o ponto
    # Usa update_columns para evitar callbacks
    #
    # @return [Boolean] true se atualizou com sucesso
    def atualizar_ponto!
      info = coletar_informacoes

      ponto.update!(
        ssid: info[:ssid],
        frequencia: info[:frequencia],
        canal_tamanho: info[:canal_tamanho]
      )

      true
    rescue SNMP::RequestTimeout, Errno::EHOSTUNREACH => e
      Rails.logger.warn("Falha SNMP para ponto #{ponto.id}: #{e.message}")
      false
    end

    # Verifica se o ponto está acessível via SNMP
    #
    # @return [Boolean]
    def acessivel?
      with_snmp_manager do |manager|
        manager.get(['SNMPv2-MIB::sysUpTime.0'])
        true
      end
    rescue SNMP::RequestTimeout, Errno::EHOSTUNREACH
      false
    end

    # Retorna o uptime do equipamento em segundos
    #
    # @return [Integer, nil]
    def uptime
      info = coletar_informacoes
      info[:uptime]&.to_i
    rescue SNMP::RequestTimeout, Errno::EHOSTUNREACH
      nil
    end

    # Retorna estatísticas de conexão do ponto
    #
    # @return [Hash]
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
        community: 'public',
        port: 161,
        version: :SNMPv1,
        timeout: 2,
        retries: 1
      }
    end

    def parse_response(response)
      result = {}

      response.each_varbind do |vb|
        oid_key = SNMP_OIDS.key(vb.name.to_s)
        result[oid_key] = vb.value.to_s if oid_key
      end

      result
    end
  end
end
