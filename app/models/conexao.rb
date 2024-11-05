# frozen_string_literal: true

# == Schema Information
#
# Table name: conexoes
#
#  id             :bigint           not null, primary key
#  auto_bloqueio  :boolean
#  bloqueado      :boolean
#  complemento    :string
#  inadimplente   :boolean          default(FALSE), not null
#  ip             :inet
#  ipv6           :inet
#  latitude       :decimal(10, 6)
#  longitude      :decimal(10, 6)
#  mac            :string
#  numero         :string
#  observacao     :string
#  pool           :cidr
#  porta          :integer
#  senha          :string
#  tipo           :integer
#  usuario        :string
#  velocidade     :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  caixa_id       :bigint
#  contrato_id    :bigint
#  equipamento_id :bigint
#  logradouro_id  :bigint
#  pessoa_id      :bigint
#  plano_id       :bigint
#  ponto_id       :bigint
#
# Indexes
#
#  index_conexoes_on_caixa_id        (caixa_id)
#  index_conexoes_on_contrato_id     (contrato_id)
#  index_conexoes_on_equipamento_id  (equipamento_id)
#  index_conexoes_on_logradouro_id   (logradouro_id)
#  index_conexoes_on_pessoa_id       (pessoa_id)
#  index_conexoes_on_plano_id        (plano_id)
#  index_conexoes_on_ponto_id        (ponto_id)
#
# Foreign Keys
#
#  fk_rails_...  (logradouro_id => logradouros.id)
#  fk_rails_...  (pessoa_id => pessoas.id)
#  fk_rails_...  (plano_id => planos.id)
#  fk_rails_...  (ponto_id => pontos.id)
#
class Conexao < ApplicationRecord
  include Ransackable

  belongs_to :pessoa
  belongs_to :plano
  belongs_to :ponto
  belongs_to :caixa, class_name: 'FibraCaixa', optional: true
  has_one :servidor, through: :ponto
  belongs_to :contrato, optional: true
  has_one :cidade, through: :pessoa
  belongs_to :logradouro, optional: true
  has_one :logradouro_pessoa, through: :pessoa, source: :logradouro
  has_one :bairro, through: :pessoa
  has_many :faturas, through: :contrato
  has_many :conexao_enviar_atributos, dependent: :delete_all
  has_many :conexao_verificar_atributos, dependent: :delete_all
  has_many :autenticacoes, primary_key: :usuario, foreign_key: :username
  has_many :rad_accts, primary_key: :usuario, foreign_key: :username
  has_many :os, dependent: :nullify
  belongs_to :equipamento, optional: true

  RANSACK_ATTRIBUTES = %w[usuario mac ip_s nome].freeze
  RANSACK_ASSOCIATIONS = %w[pessoa].freeze
  ransacker :ip_s do
    Arel.sql('ip::text')
  end

  scope :bloqueado, -> { where('bloqueado') }
  scope :ativo, -> { where('not bloqueado') }
  scope :conectada, lambda {
    where(id: Conexao.select('conexoes.id')
      .joins(:rad_accts)
      .where('AcctStartTime > ? and AcctStopTime is null', 2.days.ago)
      .group('conexoes.id'))
  }
  scope :desconectada, lambda {
    where.not(id: Conexao.select('conexoes.id')
      .joins(:rad_accts)
      .where('AcctStartTime > ? and AcctStopTime is null', 2.days.ago)
      .group('conexoes.id'))
  }
  scope :sem_autenticar, lambda {
    where.not(id: Conexao.select('DISTINCT conexoes.id')
      .joins(:rad_accts)
      .where('AcctStartTime > ?', 3.days.ago))
  }
  scope :inadimplente, -> { where('inadimplente') }
  scope :radio, -> { joins(:ponto).where(pontos: { tecnologia: :Radio }) }
  scope :fibra, -> { joins(:ponto).where(pontos: { tecnologia: :Fibra }) }
  scope :pessoa_fisica, -> { joins(:pessoa).where(pessoas: { tipo: 'Pessoa Física' }) }
  scope :pessoa_juridica, -> { joins(:pessoa).where(pessoas: { tipo: 'Pessoa Jurídica' }) }
  scope :ate_1M, -> { joins(:plano).where('planos.download <= 1') }
  scope :ate_2M, -> { joins(:plano).where('planos.download BETWEEN 1.01 AND 2') }
  scope :ate_8M, -> { joins(:plano).where('planos.download BETWEEN 2.01 AND 8') }
  scope :ate_12M, -> { joins(:plano).where('planos.download BETWEEN 8.01 AND 12') }
  scope :ate_34M, -> { joins(:plano).where('planos.download BETWEEN 12.01 AND 34') }
  scope :acima_34M, -> { joins(:plano).where('planos.download > 34') }
  enum :tipo, { Cobranca: 1, Cortesia: 2, Outro_3: 3, Outro_4: 4, Outros: 5 }
  scope :rede_ip, ->(rede) { where('ip::inet << ?::inet', rede) }
  scope :georeferencidas, -> { where.not(latitude: nil, longitude: nil) }
  scope :sem_contrato, lambda {
    left_joins(:contrato).where('conexoes.tipo = 1 and contrato_id is null or cancelamento is not null')
  }

  attr_accessor :current_user

  RADIUS_SENHA = 'Cleartext-Password'
  RADIUS_HOTSPOT_IP = 'Mikrotik-Host-Ip'
  RADIUS_PPPOE_IP = 'Framed-IP-Address'
  RADIUS_RATE_LIMIT = 'Mikrotik-Rate-Limit'

  validates :usuario, :senha, presence: true
  validates :mac,
            format: { with: /\A([0-9a-fA-F]{2}[:-]){5}[0-9a-fA-F]{2}\z/i,
                      on: %i[create update],
                      message: 'Endereço MAC inválido' }

  after_touch :save
  after_save do
    atualizar_senha
    atualizar_ip_e_mac
    atualizar_velocidade
  end

  after_commit :on_commit, on: :update

  def self.to_csv
    attributes = %w[id Pessoa Plano Ponto IP]
    CSV.generate(headers: true) do |csv|
      csv << attributes

      all.find_each do |conexao|
        csv << [
          conexao.id,
          conexao.pessoa.nome,
          conexao.plano.nome,
          conexao.ponto.nome,
          conexao.ip
        ]
      end
    end
  end

  def self.ransackable_scopes(_auth_object = nil)
    %i[inadimplente radio fibra conectada bloqueado sem_contrato]
  end

  def status_hotspot
    result = servidor.mk_command(['/ip/hotspot/active/print', "?user=#{usuario}"])
    if result.present?
      result[0][0]
    else
      ['uptime' => 'Desconectado']
    end
  end

  def desconectar
    Rails.logger.info "Desconectando usuario #{usuario}"
    if ponto.tecnologia == 'Radio'
      servidor.desconectar_hotspot(usuario)
    else
      servidor.desconectar_pppoe(usuario)
    end
  end

  def conectado
    rad_accts.where('AcctStartTime > ? and AcctStopTime is null', 2.days.ago)
             .count.positive?
  end

  def link_google_maps
    return unless latitude && longitude

    "http://maps.google.com/maps?q=#{latitude},#{longitude}"
  end

  def integrar
    atualizar_senha(true)
    atualizar_ip_e_mac(true)
    atualizar_velocidade(true)
  end

  def endereco
    return "#{pessoa.endereco} - #{pessoa.logradouro.bairro.nome_cidade_uf}" if logradouro.blank?

    "#{logradouro.nome} - #{logradouro.bairro.nome_cidade_uf}"
  end

  def as_geojson # rubocop:disable Metrics/MethodLength
    {
      type: 'Feature',
      properties: {
        nome: pessoa.nome,
        tecnologia: ponto.tecnologia
      },
      geometry: {
        type: 'Point',
        coordinates: [longitude, latitude, 0.0]
      }
    }.to_json
  end

  private

  def on_commit
    if saved_change_to_bloqueado?
      criar_atendimento
      desconectar
    elsif saved_change_to_plano_id? || saved_change_to_inadimplente?
      desconectar
    end
  end

  def atualizar_senha(forcar = false)
    return unless forcar || usuario.present? && senha.present? && (saved_change_to_senha? || saved_change_to_usuario?)

    atr = conexao_verificar_atributos.where(atributo: RADIUS_SENHA).first_or_create
    atr.update!(op: ':=', valor: senha)
  end

  def atualizar_ip_e_mac(forcar = false)
    return unless forcar || saved_change_to_ip? || saved_change_to_ponto_id? || saved_change_to_mac?

    case ponto.tecnologia
    when 'Radio'
      conexao_verificar_atributos.where(atributo: 'Calling-Station-Id').destroy_all
      conexao_enviar_atributos.where(atributo: RADIUS_PPPOE_IP).destroy_all
      atr = conexao_verificar_atributos.where(atributo: RADIUS_HOTSPOT_IP).first_or_create
      atr.update!(op: '==', valor: ip.to_s)
    when 'Fibra'
      conexao_verificar_atributos.where(atributo: RADIUS_HOTSPOT_IP).destroy_all
      atr = conexao_verificar_atributos.where(atributo: 'Calling-Station-Id').first_or_create
      atr.update!(op: '==', valor: mac)
      atr = conexao_enviar_atributos.where(atributo: RADIUS_PPPOE_IP).first_or_create
      atr.update!(op: ':=', valor: ip.to_s)
    end
  end

  def atualizar_velocidade(forcar = false)
    return unless forcar || saved_change_to_velocidade?

    conexao_enviar_atributos.where(atributo: RADIUS_RATE_LIMIT).destroy_all
    return if velocidade.blank?

    atr = conexao_enviar_atributos.where(atributo: RADIUS_RATE_LIMIT).first_or_create
    atr.update!(op: '=', valor: velocidade)
  end

  def criar_atendimento
    atendimento = pessoa.atendimentos.where(
      fechamento: nil,
      conexao_id: id,
      classificacao_id: 22
    ).order(created_at: :desc).first_or_create do |atend|
      atend.responsavel = User.find(1)
    end
    if bloqueado
      atendimento.detalhes.create(tipo: :Presencial, atendente_id: 1, descricao: 'Acesso Suspenso')
    else
      atendimento.detalhes.create(tipo: :Presencial, atendente_id: 1, descricao: 'Acesso Liberado')
      atendimento.fechamento = DateTime.now
      atendimento.save!
    end
  end
end
