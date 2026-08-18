# frozen_string_literal: true

module Devices
  # Identifica, via SNMP, qual classe de Device corresponde a um IP —
  # usado pela provisão automática (Enlace::ProvisionarDispositivosService
  # e futuramente qualquer fluxo que precise descobrir o tipo de
  # equipamento antes de criar o registro.
  class Detector
    require 'snmp'

    SYS_DESCR_OID = '1.3.6.1.2.1.1.1.0'
    COMMUNITY = Devices::Ubiquiti::Provisioner::SNMP_COMMUNITY

    # Ordem importa: o primeiro padrão que casar vence.
    PADROES = [
      { match: /airfiber/i, classe: 'Devices::AirFiber' },
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
      descr = sys_descr
      return nil if descr.nil?

      PADROES.find { |p| descr.match?(p[:match]) }&.fetch(:classe)&.safe_constantize
    end

    private

    attr_reader :ip

    def sys_descr
      SNMP::Manager.open(host: ip.to_s, community: COMMUNITY, port: 161,
                         version: :SNMPv1, timeout: 2, retries: 1) do |manager|
        manager.get([SYS_DESCR_OID]).varbind_list.first.value.to_s
      end
    rescue SNMP::RequestTimeout, Errno::EHOSTUNREACH
      nil
    end
  end
end
