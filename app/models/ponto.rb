# frozen_string_literal: true

require 'snmp'

class Ponto < ApplicationRecord
  belongs_to :servidor
  has_many :conexoes, dependent: :restrict_with_exception
  has_many :ip_redes, dependent: :restrict_with_exception
  has_many :redes, class_name: 'FibraRede', dependent: :restrict_with_exception
  has_many :caixas, through: :redes, source: :fibra_caixas
  has_many :autenticacoes, through: :conexoes, source: :autenticacoes
  scope :ativo, -> { joins(:servidor).where('servidores.ativo') }
  scope :fibra, -> { where(tecnologia: :Fibra) }

  enum tecnologia: {
    Radio: 1,
    Fibra: 2
  }
  enum sistema: {
    Ubnt: 1,
    Mikrotik: 2,
    Chima: 3,
    Outro: 4
  }
  enum equipamento: {
    'Ubiquiti Loco M5' => 'locoM5',
    'Ubiquiti Rocket M5' => 'rocketM5',
    'Ubiquiti Litebeam AC-16-120' => 'litebeamAC',
    'Ubiquiti Powerbeam M5' => 'powerbeamM5',
    'Ubiquiti Nanostation M5' => 'nanostationM5'
  }

  after_touch :save
  before_save do
    info = snmp
    self.frequencia = info[:frequencia]
    self.ssid = info[:ssid]
    self.canal_tamanho = info[:canal_tamanho]
  rescue StandardError
  end

  SNMP_CAMPOS = {
    uptime: 'SNMPv2-MIB::sysUpTime.0',
    ssid: 'SNMPv2-SMI::enterprises.41112.1.4.5.1.2.1',
    frequencia: 'SNMPv2-SMI::enterprises.41112.1.4.1.1.4.1',
    canal_tamanho: 'SNMPv2-SMI::enterprises.41112.1.4.5.1.14.1',
    conectados: 'SNMPv2-SMI::enterprises.41112.1.4.5.1.15.1',
    qualidade_airmax: 'SNMPv2-SMI::enterprises.41112.1.4.6.1.3.1',
    station_ccq: 'SNMPv2-SMI::enterprises.41112.1.4.5.1.7.1'
  }.freeze

  def to_csv
    attributes = %i[id nome ip sistema tecnologia]
    CSV.generate(headers: true) do |csv|
      csv << attributes

      all.find_each do |estado|
        csv << attributes.map { |attr| estado.send(attr) }
      end
    end
  end

  def frequencia_text
    "#{frequencia} MHz#{canal_tamanho.present? ? " (#{canal_tamanho})" : ''}"
  end

  def snmp
    snmp_manager do |manager|
      response = manager.get(SNMP_CAMPOS.values)
      result = {}
      response.each_varbind do |vb|
        result.merge!(SNMP_CAMPOS.key(vb.name.to_s) => vb.value)
      end
      result
    end
  end

  def google_maps_pins
    result = 'markers=color:blue%7Clabel:C'
    conexoes.each do |cnx|
      result += "|#{cnx.latitude},#{cnx.longitude}" if cnx.latitude.present?
    end
    result
  end

  def lista_ips
    ips = []
    ip_redes.each do |rede|
      ips += rede.to_a
    end
    ips
  end

  def ipv4_disponiveis
    ips = []
    ip_redes.ipv4.each do |rede|
      ips += rede.ips_disponiveis
    end
    ips
  end

  def ipv6_disponiveis
    ips = []
    ip_redes.ipv6.each do |rede|
      ips += rede.ips_disponiveis
    end
    ips
  end

  private

  def snmp_manager
    SNMP::Manager.open(
      host: ip.to_s,
      community: 'public',
      port: 161,
      version: :SNMPv1
    )
  end
end
