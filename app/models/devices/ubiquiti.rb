# frozen_string_literal: true

# app/models/devices/ubiquiti.rb
module Devices
  class Ubiquiti < Device
    has_many :backups, class_name: 'Devices::UbiquitiBackup',
                       foreign_key: :device_id, dependent: :destroy

    PASSWORD_GROUPS = {
      legacy: ['Loco M5', 'Rocket M5', 'Powerbeam M5', 'NanoStation M5', 'NanoBeam M5'],
      ac: ['Litebeam AC-16-120', 'LiteAP AC'],
      gps: ['LiteAP GPS']
    }.freeze

    # Accessors for properties
    store_accessor :properties,
                   :signal, :noise, :ssid, :frequencia, :canal_tamanho,
                   :conectados, :qualidade_airmax, :station_ccq

    def atualizar_snmp!
      info = ::Ubiquiti::SnmpReader.new(self).coletar_informacoes

      attrs = { last_seen_at: Time.current }
      attrs[:mac] = info[:mac] if info[:mac].present?
      attrs[:firmware] = info[:firmware] if info[:firmware].present?
      attrs[:signal] = info[:signal].to_i if info[:signal].present?
      attrs[:noise] = info[:noise].to_i if info[:noise].present?
      attrs[:ssid] = info[:ssid] if info[:ssid].present?
      attrs[:frequencia] = info[:frequencia] if info[:frequencia].present?
      attrs[:canal_tamanho] = info[:canal_tamanho].to_i if info[:canal_tamanho].present?
      attrs[:conectados] = info[:conectados].to_i if info[:conectados].present?

      eq = ::Ubiquiti::ModelNormalizer.resolve(info[:modelo])
      attrs[:equipamento] = eq if eq

      update!(attrs)
    rescue SNMP::RequestTimeout, Errno::EHOSTUNREACH => e
      Rails.logger.warn("Falha SNMP para device #{id} (#{ip}): #{e.message}")
      false
    end

    def passwords
      primary = password_for_equipamento
      all = all_passwords
      [primary, *(all - [primary])].compact.uniq
    end

    private

    def default_user = 'ubnt'
    def default_password = passwords.first

    def password_for_equipamento
      return credentials[:legacy] unless equipamento

      group = PASSWORD_GROUPS.find { |_g, models| models.include?(equipamento.modelo) }&.first
      credentials[group || :legacy]
    end

    def all_passwords
      credentials.values.uniq
    end

    def credentials
      Rails.application.credentials.ubiquiti[:passwords]
    end
  end
end
