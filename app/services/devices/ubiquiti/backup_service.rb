# frozen_string_literal: true

#
# Realiza backup de configuração de dispositivos Ubiquiti via SSH/SCP.
#
# O arquivo de configuração fica em /tmp/system.cfg no dispositivo.
# Usa Net::SSH para executar o download via cat (evita dependência de SCP binário).
#
# === Credenciais
#
# Tenta cada senha disponível (legacy, ac, gps) até conectar com sucesso.
# Respeita o usuário e senha customizados do device se definidos.
#
module Devices
  module Ubiquiti
    class BackupService < Devices::BackupService
      CONFIG_PATH = '/tmp/system.cfg'
      CONNECT_TIMEOUT = 10
      SSH_TIMEOUT = 30

      # @return [Hash] { success:, backup:, skipped:, error: }
      def call
        config_text = download_config
        backup = DeviceBackup.store(device, config_text)

        { success: true, backup: backup.presence, skipped: backup == false }
      rescue StandardError => e
        { success: false, backup: nil, skipped: false, error: e.message }
      end

      private

      def download_config
        last_error = nil

        credentials_to_try.each do |user, password|
          return ssh_cat(user, password, CONFIG_PATH)
        rescue Net::SSH::AuthenticationFailed, Net::SSH::Exception => e
          last_error = e
          next
        end

        raise last_error || RuntimeError.new("Nenhuma credencial funcionou para #{device.ip}")
      end

      def ssh_cat(user, password, path)
        output = String.new

        Net::SSH.start(
          device.ip,
          user,
          password: password,
          non_interactive: true,
          timeout: CONNECT_TIMEOUT,
          verify_host_key: :never
        ) do |ssh|
          channel = ssh.open_channel do |ch|
            ch.exec("cat #{path}") do |_, success|
              raise "Falha ao executar cat em #{device.ip}" unless success

              ch.on_data { |_, data| output << data }
              ch.on_extended_data { |_, _, data| Rails.logger.debug("SSH stderr: #{data}") }
            end
          end

          channel.wait
          ssh.loop(SSH_TIMEOUT)
        end

        raise "Config vazia em #{device.ip}" if output.blank?

        output
      end

      # Retorna pares [usuario, senha] para tentar, priorizando credenciais customizadas.
      #
      # @return [Array<Array<String>>]
      def credentials_to_try
        # Se o device tem credenciais específicas, tenta só essas
        return [[device.effective_user, device.effective_password]] if device.send(:senha).present?

        # Caso contrário, tenta todas as senhas conhecidas (legacy, ac, gps)
        device.passwords.map { |pwd| [device.effective_user, pwd] }
      end
    end
  end
end
