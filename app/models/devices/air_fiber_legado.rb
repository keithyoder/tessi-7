module Devices
  class AirFiberLegado < Device
    store_accessor :properties,
                   :modo, :ssid, :status, :distancia, :tx_power_eirp,
                   :signal, :signal_chain0, :signal_chain1,
                   :remote_mac, :remote_ip

    def atualizar_snmp!
      info = ::Devices::AirFiberLegado::SnmpReader.new(self).coletar_informacoes

      attrs = { last_seen_at: Time.current }
      attrs[:mac] = info[:mac] if info[:mac].present?
      attrs[:firmware] = info[:firmware] if info[:firmware].present?
      attrs[:modo] = info[:modo] if info[:modo].present?
      attrs[:ssid] = info[:ssid] if info[:ssid].present?
      attrs[:status] = info[:status] if info[:status].present?
      attrs[:distancia] = info[:distancia] if info[:distancia].present?
      attrs[:tx_power_eirp] = info[:tx_power_eirp] if info[:tx_power_eirp].present?
      attrs[:signal_chain0] = info[:signal_chain0].to_i if info[:signal_chain0].present?
      attrs[:signal_chain1] = info[:signal_chain1].to_i if info[:signal_chain1].present?
      attrs[:signal] = info[:signal] if info[:signal].present?
      attrs[:remote_mac] = info[:remote_mac] if info[:remote_mac].present?
      attrs[:remote_ip] = info[:remote_ip] if info[:remote_ip].present?

      update!(attrs)
    rescue SNMP::RequestTimeout, Errno::EHOSTUNREACH => e
      Rails.logger.warn("Falha SNMP para device #{id} (#{ip}): #{e.message}")
      false
    end
  end
end
