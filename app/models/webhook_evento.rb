# frozen_string_literal: true

class WebhookEvento < ApplicationRecord
  belongs_to :webhook

  def notificacao
    body['notification']
  end
end
