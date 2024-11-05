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
  has_many :webhook_eventos, as: :eventos, dependent: :destroy
  enum tipo: {
    banco_do_brasil: 101,
    gerencianet: 102,
    autentique: 103
  }
end
