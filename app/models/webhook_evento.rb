# frozen_string_literal: true

# == Schema Information
#
# Table name: webhook_eventos
#
#  id           :bigint           not null, primary key
#  body         :jsonb
#  headers      :jsonb
#  processed_at :datetime
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  webhook_id   :bigint
#
# Indexes
#
#  index_webhook_eventos_on_webhook_id  (webhook_id)
#
# Foreign Keys
#
#  fk_rails_...  (webhook_id => webhooks.id)
#
class WebhookEvento < ApplicationRecord
  belongs_to :webhook

  def notificacao
    body['notification']
  end
end
