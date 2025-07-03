# frozen_string_literal: true

# == Schema Information
#
# Table name: webhooks
#
#  id         :bigint           not null, primary key
#  tipo       :integer
#  token      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Webhook < ApplicationRecord
  has_secure_token
  has_many :eventos, class_name: 'WebhookEvento', dependent: :destroy
  enum tipo: {
    banco_do_brasil: 101,
    gerencianet: 102,
    autentique: 103,
    efi_pix: 104
  }

  def url
    "/webhooks/#{token}"
  end
end
