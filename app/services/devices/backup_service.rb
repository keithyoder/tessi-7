# frozen_string_literal: true

# app/services/devices/backup_service.rb
#
# Interface base para serviços de backup de dispositivos.
# Cada tipo de device implementa sua própria subclasse.
#
# === Uso
#
#   service = Devices::BackupService.for(device)
#   result  = service.call
#   # => { success: true, backup: #<DeviceBackup>, skipped: false }
#   # => { success: false, error: "Connection refused" }
#
module Devices
  class BackupService
    # Retorna a implementação correta para o tipo de device.
    #
    # @param device [Device]
    # @return [BackupService subclass]
    def self.for(device)
      case device
      when Devices::Ubiquiti
        Devices::Ubiquiti::BackupService.new(device)
      else
        raise NotImplementedError, "Nenhum BackupService implementado para #{device.class}"
      end
    end

    def initialize(device)
      @device = device
    end

    # Executa o backup. Deve ser implementado pela subclasse.
    #
    # @return [Hash] { success: Boolean, backup: DeviceBackup|nil,
    #                  skipped: Boolean, error: String|nil }
    def call
      raise NotImplementedError
    end

    private

    attr_reader :device
  end
end
