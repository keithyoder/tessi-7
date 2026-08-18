# frozen_string_literal: true

# == Schema Information
#
# Table name: devices
#
#  id              :bigint           not null, primary key
#  deviceable_type :string
#  firmware        :string
#  last_seen_at    :datetime
#  mac             :string
#  properties      :jsonb
#  senha           :string
#  type            :string           not null
#  usuario         :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  deviceable_id   :bigint
#  equipamento_id  :bigint
#
class Devices::AirFiber < Device # rubocop:disable Style/ClassAndModuleChildren
  store_accessor :properties,
                 :modo, :frequencia, :canal_tamanho, :ssid,
                 :signal, :signal_chain0, :signal_chain1, :distancia,
                 :tx_rate, :rx_rate, :remote_mac, :remote_modelo,
                 :remote_ip, :latencia

  def atualizar_snmp!
    info = SnmpReader.new(self).coletar_informacoes

    attrs = { last_seen_at: Time.current }
    attrs[:mac] = info[:mac] if info[:mac].present?
    attrs[:firmware] = info[:firmware] if info[:firmware].present?
    attrs[:modo] = info[:modo] if info[:modo].present?
    attrs[:frequencia] = info[:frequencia] if info[:frequencia].present?
    attrs[:canal_tamanho] = info[:canal_tamanho] if info[:canal_tamanho].present?
    attrs[:ssid] = info[:ssid] if info[:ssid].present?
    attrs[:signal] = info[:signal] if info[:signal].present?
    attrs[:signal_chain0] = info[:signal_chain0].to_i if info[:signal_chain0].present?
    attrs[:signal_chain1] = info[:signal_chain1].to_i if info[:signal_chain1].present?
    attrs[:distancia] = info[:distancia].to_f if info[:distancia].present?
    attrs[:tx_rate] = info[:tx_rate] if info[:tx_rate].present?
    attrs[:rx_rate] = info[:rx_rate] if info[:rx_rate].present?
    attrs[:remote_mac] = info[:remote_mac] if info[:remote_mac].present?
    attrs[:remote_modelo] = info[:remote_modelo] if info[:remote_modelo].present?
    attrs[:remote_ip] = info[:remote_ip] if info[:remote_ip].present?
    attrs[:latencia] = info[:latencia].to_i if info[:latencia].present?

    attrs[:equipamento] = Equipamento.find_by(modelo: info[:modelo]) if info[:modelo].present?

    update!(attrs)
  rescue SNMP::RequestTimeout, Errno::EHOSTUNREACH => e
    Rails.logger.warn("Falha SNMP para device #{id} (#{ip}): #{e.message}")
    false
  end
end
