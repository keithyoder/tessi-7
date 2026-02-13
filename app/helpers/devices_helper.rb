# frozen_string_literal: true

module DevicesHelper
  # Returns firmware up to vMAJOR.MINOR.PATCH
  # e.g. "WA.ar934x.v8.7.11.46972.220614.0420" → "WA.ar934x.v8.7.11"
  def format_firmware(firmware)
    return if firmware.blank?

    firmware[/\A.*?v\d+\.\d+\.\d+/] || firmware
  end
end
