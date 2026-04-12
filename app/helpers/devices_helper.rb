# frozen_string_literal: true

# == Schema Information
#
# Table name: devices
#
#  id              :bigint           not null, primary key
#  deviceable_type :string           not null
#  firmware        :string
#  last_seen_at    :datetime
#  mac             :string
#  properties      :jsonb
#  senha           :string
#  type            :string           not null
#  usuario         :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  deviceable_id   :bigint           not null
#  equipamento_id  :bigint
#
# Indexes
#
#  index_devices_on_deviceable                         (deviceable_type,deviceable_id)
#  index_devices_on_deviceable_type_and_deviceable_id  (deviceable_type,deviceable_id) UNIQUE
#  index_devices_on_equipamento_id                     (equipamento_id)
#  index_devices_on_mac                                (mac)
#  index_devices_on_properties                         (properties) USING gin
#  index_devices_on_type                               (type)
#
# Foreign Keys
#
#  fk_rails_...  (equipamento_id => equipamentos.id)
#
module DevicesHelper
  # Returns firmware up to vMAJOR.MINOR.PATCH
  # e.g. "WA.ar934x.v8.7.11.46972.220614.0420" → "WA.ar934x.v8.7.11"
  def format_firmware(firmware)
    return if firmware.blank?

    firmware[/\A.*?v\d+\.\d+\.\d+/] || firmware
  end
end
