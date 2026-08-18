# frozen_string_literal: true

module Devices
  class Provisioner
    def initialize(deviceable)
      @deviceable = deviceable
    end

    # Atualiza (ou cria/reaproveita, se necessário) o Device via SNMP,
    # sem nunca aplicar configuração — não reinicia o equipamento.
    # Seguro para rodar em lote/periodicamente contra toda a base.
    def atualizar!
      device, = localizar_ou_criar_device
      device
    end

    # Igual a atualizar!, mas também aplica a configuração desejada
    # (push via SSH, pode reiniciar o equipamento) — só quando um
    # device novo é criado, trocado ou reaproveitado. Não reconfigura
    # um device que já existia e continua sendo o mesmo (mac
    # inalterado desde a última execução).
    def provisionar!
      device, novo = localizar_ou_criar_device
      return device if device.nil?

      configurar(device) if novo

      device
    end

    private

    attr_reader :deviceable

    def localizar_ou_criar_device
      device_class = Devices::Detector.resolve(deviceable.ip)
      return [nil, false] if device_class.nil?

      mac_atual = device_class::SnmpReader.new(deviceable).coletar_informacoes[:mac]
      return [nil, false] if mac_atual.blank?

      device_existente = deviceable.device
      novo = !(device_existente.present? && device_existente.mac == mac_atual)

      device = if novo
                 device_reaproveitado = Device.unlinked.find_by(mac: mac_atual)
                 device_existente&.update!(deviceable: nil)
                 device_reaproveitado || device_class.new
               else
                 device_existente
               end

      device.deviceable = deviceable
      herdar_credenciais_do_deviceable(device) if novo
      device.atualizar_snmp!
      [device, novo]
    end

    def herdar_credenciais_do_deviceable(device)
      return unless device.usuario.blank? && device.senha.blank?
      return unless deviceable.respond_to?(:usuario) && deviceable.respond_to?(:senha)

      device.usuario = deviceable.usuario if deviceable.usuario.present?
      device.senha = deviceable.senha if deviceable.senha.present?
    end

    def configurar(device); end
  end
end
