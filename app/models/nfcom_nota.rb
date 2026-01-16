# frozen_string_literal: true

# == Schema Information
#
# Table name: nfcoms
#
#  id                :bigint           not null, primary key
#  chave_acesso      :string(44)
#  competencia       :date             not null
#  data_autorizacao  :datetime
#  mensagem_sefaz    :string
#  numero            :integer          not null
#  protocolo         :string(15)
#  serie             :integer          default(1), not null
#  status            :string           default("pending"), not null
#  valor_total       :decimal(13, 2)
#  xml_autorizado    :text
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  fatura_id         :bigint
#
# Indexes
#
#  index_nfcoms_on_chave_acesso     (chave_acesso) UNIQUE
#  index_nfcoms_on_competencia      (competencia)
#  index_nfcoms_on_fatura_id        (fatura_id)
#  index_nfcoms_on_serie_and_numero (serie,numero) UNIQUE
#  index_nfcoms_on_status           (status)
#
class NfcomNota < ApplicationRecord
  belongs_to :fatura
  
  # Status state machine
  STATUSES = %w[pending authorized rejected cancelled].freeze
  
  validates :numero, presence: true, uniqueness: { scope: :serie }
  validates :status, inclusion: { in: STATUSES }
  validates :chave_acesso, uniqueness: true, allow_nil: true
  validate :fatura_does_not_have_authorized_nota, on: :create

  def fatura_does_not_have_authorized_nota
    if fatura.nfcom_notas.where(status: 'authorized').exists?
      errors.add(:base, 'Não é possível criar outra NFComNota: já existe uma autorizada.')
    end
  end

  # Scopes for common queries
  scope :competencia, ->(mes) { where(competencia: Date.parse("#{mes}-01")) }
  scope :authorized, -> { where(status: 'authorized') }
  scope :pending, -> { where(status: 'pending') }
  
  # Get next numero for a given serie
  def self.proximo_numero(serie = 1)
    where(serie: serie).maximum(:numero).to_i + 1
  end
  
  # Parse XML to extract data if needed
  def parse_xml
    return unless xml_autorizado.present?
    
    @parsed_xml ||= Nokogiri::XML(xml_autorizado)
  end
  
  # Extract specific values from XML (lazy loaded, not stored)
  def valor_servicos_from_xml
    parse_xml&.at_xpath('//xmlns:vProd', 'xmlns' => 'http://www.portalfiscal.inf.br/nfcom')&.text&.to_d
  end
  
  def data_emissao_from_xml
    dhemi = parse_xml&.at_xpath('//xmlns:dhEmi', 'xmlns' => 'http://www.portalfiscal.inf.br/nfcom')&.text
    DateTime.parse(dhemi) if dhemi
  end
  
  # State transitions
  def autorizar!(protocolo:, chave:, xml:)
    update!(
      status: 'authorized',
      protocolo: protocolo,
      chave_acesso: chave,
      xml_autorizado: xml,
      data_autorizacao: Time.current
    )
  end
  
  def rejeitar!(mensagem)
    update!(
      status: 'rejected',
      mensagem_sefaz: mensagem
    )
  end
  
  def cancelar!
    update!(status: 'cancelled')
  end

  def consulta_url
    chave = chave_acesso
    return nil unless chave && chave.length == 44

    tp_amb = Nfcom.configuration.homologacao? ? 2 : 1
    "https://dfe-portal.svrs.rs.gov.br/nfcom/qrcode?chNFCom=#{chave}&tpAmb=#{tp_amb}"
  end
end