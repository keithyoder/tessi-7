# frozen_string_literal: true

# == Schema Information
#
# Table name: pessoas
#
#  id            :bigint           not null, primary key
#  cnpj          :string
#  complemento   :string
#  cpf           :string
#  email         :string
#  ie            :string
#  latitude      :decimal(10, 6)
#  longitude     :decimal(10, 6)
#  nascimento    :date
#  nome          :string
#  nomemae       :string
#  numero        :string
#  rg            :string
#  telefone1     :string
#  telefone2     :string
#  tipo          :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  logradouro_id :bigint
#
# Indexes
#
#  index_pessoas_on_logradouro_id  (logradouro_id)
#  index_pessoas_on_nome           (nome)
#
# Foreign Keys
#
#  fk_rails_...  (logradouro_id => logradouros.id)
#
class Pessoa < ApplicationRecord
  include Ransackable

  belongs_to :logradouro
  has_one :bairro, through: :logradouro
  has_one :cidade, through: :logradouro
  has_one :estado, through: :logradouro
  has_many :conexoes
  has_many :contratos
  has_many :os
  has_many :atendimentos
  has_one_attached :rg_imagem
  scope :assinantes, -> { select('pessoas.id').joins(:conexoes).group('pessoas.id').having('count(*) > 0') }

  delegate :endereco, to: :logradouro, prefix: :logradouro

  enum :tipo, { 'Pessoa Física' => 1, 'Pessoa Jurídica' => 2 }

  validates :tipo, presence: true
  validates :telefone1, presence: true
  validates :cpf, presence: true, if: :pessoa_fisica?
  validates :cnpj, presence: true, if: :pessoa_juridica?
  validates :cpf, absence: true, if: :pessoa_juridica?
  validates :cnpj, absence: true, if: :pessoa_fisica?
  validate :cpf_valido?
  validate :cnpj_valido?
  validate :telefone1_valido?
  validate :telefone2_valido?
  validates :cpf, uniqueness: true, allow_blank: true
  validates :cnpj, uniqueness: true, allow_blank: true

  RANSACK_ATTRIBUTES = %w[cnpj cpf email nome telefone1 telefone2].freeze
  RANSACK_ASSOCIATIONS = %w[].freeze

  def endereco
    "#{logradouro.nome}, #{numero} #{complemento}"
  end

  def idade
    ((Time.zone.now - nascimento.to_time) / 1.year.seconds).floor
  end

  def cpf_cnpj
    cpf.present? ? CPF.new(cpf).stripped : CNPJ.new(cnpj).stripped
  end

  def cpf_cnpj_formatado
    cpf.present? ? cpf.to_s : cnpj.to_s
  end

  def tipo_documento
    tipo == 'Pessoa Física' ? 'CPF' : 'CNPJ'
  end

  def rg_ie
    rg.present? ? rg : ie
  end

  def assinante?
    conexoes.count.positive?
  end

  def cpf_valido?
    CPF.valid?(cpf) if cpf.present?
  end

  def cnpj_valido?
    CNPJ.valid?(cnpj) if cnpj.present?
  end

  def telefone1_valido?
    return if telefone1.present? && Phonelib.valid?(telefone1)

    errors.add :telefone1, "inválido"
  end

  def telefone2_valido?
    return if telefone2.blank?
    return if Phonelib.valid?(telefone2)

    errors.add :telefone2, "inválido"
  end

  def telefone1=(value)
    super(Phonelib.parse(value).sanitized)
  end

  def telefone1
    Phonelib.parse(super).national
  end

  def telefone2=(value)
    super(Phonelib.parse(value).sanitized)
  end

  def telefone2
    Phonelib.parse(super).national
  end

  def pessoa_fisica?
    tipo == 'Pessoa Física'
  end

  def pessoa_juridica?
    tipo == 'Pessoa Jurídica'
  end

  def nome_sem_acentos
    nome.parameterize(separator: ' ').upcase
  end
end
