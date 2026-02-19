# frozen_string_literal: true

# == Schema Information
#
# Table name: equipamentos
#
#  id         :bigint           not null, primary key
#  fabricante :string
#  modelo     :string
#  tipo       :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Equipamento < ApplicationRecord
  has_many :conexoes, dependent: :restrict_with_exception
  has_many :devices, dependent: :restrict_with_exception

  enum :tipo, {
    ONU: 1,
    Radio: 2,
    OLT: 3,
    Radio_PtP: 4,
    Roteador: 5,
    Switch: 6
  }

  has_one_attached :imagem

  scope :cpe, -> { where(tipo: %i[ONU Radio]) }

  attr_accessor :imagem_url

  before_validation :attach_imagem_from_url, if: -> { imagem_url.present? }
  before_validation :resize_imagem, if: -> { imagem.attached? && imagem.blob.previously_new_record? }

  def descricao
    "#{fabricante} #{modelo}"
  end

  private

  def attach_imagem_from_url
    uri = URI.parse(imagem_url)
    response = Net::HTTP.get_response(uri)
    return unless response.is_a?(Net::HTTPSuccess)

    content_type = response['content-type']
    return errors.add(:imagem_url, 'não é uma imagem válida') unless content_type&.start_with?('image/')

    filename = File.basename(uri.path).presence || 'imagem'

    resized = ImageProcessing::MiniMagick
      .source(StringIO.new(response.body))
      .resize_to_limit(400, 400)
      .convert('webp')
      .call

    imagem.attach(io: resized, filename: "#{File.basename(filename, '.*')}.webp", content_type: 'image/webp')
  rescue URI::InvalidURIError, SocketError
    errors.add(:imagem_url, 'URL inválida')
  end

  def resize_imagem
    return unless imagem.blob.content_type.start_with?('image/')

    resized = ImageProcessing::MiniMagick
      .source(StringIO.new(imagem.blob.download))
      .resize_to_limit(400, 400)
      .convert('webp')
      .call

    imagem.attach(io: resized, filename: "#{File.basename(imagem.blob.filename.to_s, '.*')}.webp",
                  content_type: 'image/webp')
  end
end
