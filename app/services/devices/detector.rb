# frozen_string_literal: true

module Devices
  # Identifica, via SNMP, qual classe de Device corresponde a um IP —
  # usado pela provisão automática (Enlace::ProvisionarDispositivosService
  # e futuramente qualquer fluxo que precise descobrir o tipo de
  # equipamento antes de criar o registro.
  class Detector
    require 'snmp'

    SYS_DESCR_OID = '1.3.6.1.2.1.1.1.0'
    AIRFIBER_MODELO_OID = 'SNMPv2-SMI::enterprises.41112.1.10.1.3.2.0'
    AIRFIBER_LEGADO_FIRMWARE_OID = 'SNMPv2-SMI::enterprises.41112.1.3.2.1.40.1'
    COMMUNITY = Devices::Ubiquiti::Provisioner::SNMP_COMMUNITY

    # Ordem importa: o primeiro padrão que casar vence.
    PADROES = [
      { match: /\ARouterOS/i, classe: 'Devices::Mikrotik' },
      { match: /jetstream/i, classe: 'Devices::TpLink' },
      { match: //, classe: 'Devices::Ubiquiti' } # fallback Ubiquiti genérico
    ].freeze

    def self.resolve(ip)
      new(ip).resolve
    end

    def initialize(ip)
      @ip = ip
    end

    def resolve
      return Devices::AirFiber if airfiber?
      return Devices::AirFiberLegado if airfiber_legado?

      descr = sys_descr
      return nil if descr.nil?

      PADROES.find { |p| descr.match?(p[:match]) }&.fetch(:classe)&.safe_constantize
    end

    private

    attr_reader :ip

    # AirFiber mais novo (ex.: 5XHD) expõe a própria OID de modelo no
    # branch dedicado — só um AirFiber real responde algo válido ali.
    def airfiber?
      probe(AIRFIBER_MODELO_OID)
    end

    # Gerações mais antigas (ex.: AF-5X, firmware 4.1.0) não têm o branch
    # acima nem mencionam "airfiber" no sysDescr — só um sysDescr
    # genérico de kernel, indistinguível por texto de um airMAX antigo.
    # Ainda assim respondem no branch legado (.3.*), então testamos
    # diretamente a OID de firmware desse branch.
    def airfiber_legado?
      probe(AIRFIBER_LEGADO_FIRMWARE_OID)
    end

    def probe(oid)
      with_snmp_manager do |manager|
        response = manager.get([oid])
        valid_snmp_value?(response.varbind_list.first.value.to_s)
      end
    rescue SNMP::RequestTimeout, Errno::EHOSTUNREACH
      false
    end

    def sys_descr
      with_snmp_manager do |manager|
        manager.get([SYS_DESCR_OID]).varbind_list.first.value.to_s
      end
    rescue SNMP::RequestTimeout, Errno::EHOSTUNREACH
      nil
    end

    def with_snmp_manager(&)
      SNMP::Manager.open(host: ip.to_s, community: COMMUNITY, port: 161,
                         version: :SNMPv1, timeout: 2, retries: 1, &)
    end

    def valid_snmp_value?(value)
      value.present? && %w[Null noSuchInstance noSuchObject].exclude?(value)
    end
  end
end
