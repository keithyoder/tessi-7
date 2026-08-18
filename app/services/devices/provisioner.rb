# frozen_string_literal: true

module Devices
  class Provisioner
    def initialize(deviceable)
      @deviceable = deviceable
    end

    def provisionar!
      device = encontrar_ou_criar_device
      return device if device.nil?

      configurar(device)
      device
    end

    private

    attr_reader :deviceable

    def encontrar_ou_criar_device
      device_class = Devices::Detector.resolve(deviceable.ip)
      return nil if device_class.nil?

      mac_atual = device_class::SnmpReader.new(deviceable).coletar_informacoes[:mac]
      return nil if mac_atual.blank?

      device_existente = deviceable.device
      return device_existente if device_existente.present? && device_existente.mac == mac_atual

      device_reaproveitado = Device.unlinked.find_by(mac: mac_atual)
      device_existente&.update!(deviceable: nil)

      device = device_reaproveitado || device_class.new
      device.deviceable = deviceable
      herdar_credenciais_do_deviceable(device)
      device.atualizar_snmp!
      device
    end

    # Ponte de migração: enquanto usuario/senha ainda vivem em alguns
    # deviceables legados (Ponto), copia para o Device na primeira vez
    # que ele é vinculado — sem sobrescrever credenciais já definidas
    # diretamente no Device (ex.: um device reaproveitado que já tinha
    # senha própria).
    def herdar_credenciais_do_deviceable(device)
      return unless device.usuario.blank? && device.senha.blank?
      return unless deviceable.respond_to?(:usuario) && deviceable.respond_to?(:senha)

      device.usuario = deviceable.usuario if deviceable.usuario.present?
      device.senha = deviceable.senha if deviceable.senha.present?
    end

    def configurar(device); end
  end
end
