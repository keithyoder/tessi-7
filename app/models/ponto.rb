# frozen_string_literal: true

# == Schema Information
#
# Table name: pontos
#
#  id            :bigint           not null, primary key
#  canal_tamanho :integer
#  equipamento   :string
#  frequencia    :string
#  ip            :inet
#  ipv6          :inet
#  nome          :string
#  senha         :string
#  sistema       :integer
#  ssid          :string
#  tecnologia    :integer
#  usuario       :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  servidor_id   :bigint
#
# Indexes
#
#  index_pontos_on_servidor_id  (servidor_id)
#
# Foreign Keys
#
#  fk_rails_...  (servidor_id => servidores.id)
#
class Ponto < ApplicationRecord
  include Ransackable

  belongs_to :servidor
  has_many :conexoes, dependent: :restrict_with_exception
  has_many :ip_redes, dependent: :restrict_with_exception
  has_many :redes, class_name: 'FibraRede', dependent: :restrict_with_exception
  has_many :caixas, through: :redes, source: :fibra_caixas
  has_many :autenticacoes, through: :conexoes
  has_many :ubiquiti_backups, dependent: :destroy

  # Scopes
  scope :ativo, -> { joins(:servidor).where('servidores.ativo') }
  scope :fibra, -> { where(tecnologia: :Fibra) }
  scope :radio, -> { where(tecnologia: :Radio) }

  # Ransack configuration
  RANSACK_ATTRIBUTES = %w[nome ssid ip_string].freeze
  RANSACK_ASSOCIATIONS = %w[servidor].freeze

  ransacker :ip_string do
    Arel.sql('ip::text')
  end

  # Enums
  enum :tecnologia, {
    Radio: 1,
    Fibra: 2
  }, prefix: true

  enum :sistema, {
    Ubnt: 1,
    Mikrotik: 2,
    Chima: 3,
    Outro: 4
  }, prefix: true

  enum :equipamento, {
    'NanoStation loco M5' => 'locoM5',
    'Rocket M5' => 'rocketM5',
    'Litebeam AC-16-120' => 'litebeamAC',
    'Powerbeam M5' => 'powerbeamM5',
    'NanoStation M5' => 'nanostationM5',
    'NanoBeam M5' => 'nanobeamM5'
  }

  # Validations
  validates :nome, presence: true
  validates :ip, presence: true
  validates :tecnologia, presence: true
  validates :servidor, presence: true

  # ========================================================================
  # Métodos de informação de frequência
  # ========================================================================

  # Retorna texto formatado da frequência com tamanho do canal
  #
  # @return [String] ex: "5180 MHz (20)" ou "5180 MHz"
  def frequencia_formatada
    return nil unless frequencia.present?

    texto = "#{frequencia} MHz"
    texto += " (#{canal_tamanho})" if canal_tamanho.present?
    texto
  end
  alias frequencia_text frequencia_formatada

  # ========================================================================
  # Métodos de IP disponíveis
  # ========================================================================

  # Retorna todos os IPs das redes associadas ao ponto
  #
  # @return [Array<IPAddr>]
  def lista_ips
    ip_redes.flat_map(&:para_array)
  end

  # Retorna IPs IPv4 disponíveis (não ocupados por conexões)
  #
  # @return [Array<IPAddr>]
  def ipv4_disponiveis
    ip_redes.ipv4.flat_map(&:ips_disponiveis)
  end

  # Retorna IPs IPv6 disponíveis (não ocupados por conexões)
  #
  # @return [Array<IPAddr>]
  def ipv6_disponiveis
    ip_redes.ipv6.flat_map(&:ips_disponiveis)
  end

  def snmp_reader
    @snmp_reader ||= Ubiquiti::SnmpReader.new(self)
  end

  def snmp_provisioner
    @snmp_provisioner ||= Ubiquiti::SnmpProvisioner.new(self)
  end

  delegate :coletar_informacoes, :acessivel?, :estatisticas_conexao, to: :snmp_reader, prefix: :snmp

  def atualizar_snmp!
    info = snmp_reader.coletar_informacoes

    attrs = {
      ssid: info[:ssid],
      frequencia: info[:frequencia],
      canal_tamanho: info[:canal_tamanho]
    }

    equipamento_key = Ubiquiti::ModelNormalizer.resolve(info[:modelo])
    attrs[:equipamento] = equipamento_key if equipamento_key

    update!(attrs)
  rescue SNMP::RequestTimeout, Errno::EHOSTUNREACH => e
    Rails.logger.warn("Falha SNMP para ponto #{id} (#{ip}): #{e.message}")
    false
  end

  # ========================================================================
  # Métodos de apresentação
  # ========================================================================

  def to_s
    nome
  end
end
