# frozen_string_literal: true

module Deviceable
  extend ActiveSupport::Concern

  included do
    has_one :device, as: :deviceable, dependent: :destroy
  end

  def device_id
    device&.id
  end

  def device_id=(id)
    new_id = id.presence&.to_i
    return if device&.id == new_id
    return if new_id.blank?

    Device.find(new_id).update!(deviceable: self)
    reload_device
  end
end
