# frozen_string_literal: true

class Webhook < ApplicationRecord
  has_secure_token
  has_many :webhook_eventos, as: :eventos, dependent: :destroy
  enum tipo: {
    banco_do_brasil: 101,
    gerencianet: 102,
    autentique: 103
  }
end
