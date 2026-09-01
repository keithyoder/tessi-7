# frozen_string_literal: true

module Devices
  class Mikrotik < Device
    store_accessor :properties,
                   :board_name, :serial_number, :uptime, :cpu_load,
                   :ppp_users_count, :hotspot_users_count

    def mk_command(command)
      return unless effective_user.present? && effective_password.present?

      MTik.command(
        host: ip,
        user: effective_user,
        pass: effective_password,
        use_ssl: true,
        unencrypted_plaintext: true,
        command:
      )
    end

    def desconectar_hotspot(usuario)
      id = mk_command(['/ip/hotspot/active/print', "?user=#{usuario}"])[0][0]['.id']
      mk_command(['/ip/hotspot/active/remove', "=.id=#{id}"])
    rescue MTik::Error, Errno::ECONNREFUSED, Errno::EHOSTUNREACH => e
      Rails.logger.info e.message
    end

    def desconectar_pppoe(usuario)
      id = mk_command(['/ppp/active/print', '=.proplist=.id', "?name=#{usuario}"])[0][0]['.id']
      mk_command(['/ppp/active/remove', "=.id=#{id}"])
    rescue MTik::Error, Errno::ECONNREFUSED, Errno::EHOSTUNREACH => e
      Rails.logger.info e.message
    end

    def ppp_users
      users = mk_command('/ppp/active/print')
      (users[0].count - 1).to_s
    rescue StandardError => e
      e.message
    end

    def hotspot_users
      users = mk_command('/ip/hotspot/active/print')
      (users[0].count - 1).to_s
    rescue StandardError => e
      e.message
    end

    def system_info
      result = mk_command('/system/resource/print')[0][0]
      result.slice('uptime', 'version', 'cpu-load', 'board-name')
    rescue StandardError
      nil
    end

    def routerboard_info
      result = mk_command('/system/routerboard/print')[0][0]
      result&.slice('model', 'serial-number')
    rescue StandardError
      nil
    end

    def ping?
      Net::Ping::External.new(ip).ping?
    end

    def atualizar!
      attrs = { last_seen_at: Time.current }

      if (info = system_info)
        attrs[:firmware]   = info['version']
        attrs[:board_name] = info['board-name']
        attrs[:uptime]     = info['uptime']
        attrs[:cpu_load]   = info['cpu-load'].to_s.to_i

        if (board = info['board-name']).present?
          equipamento = Equipamento.find_by(fabricante: 'Mikrotik', modelo: board)
          attrs[:equipamento_id] = equipamento.id if equipamento
          Rails.logger.warn("Board Mikrotik desconhecido: #{board}") if equipamento.nil?
        end
      end

      novo_serial = routerboard_info&.dig('serial-number')
      if novo_serial.present? && serial_number.present? && novo_serial != serial_number
        return substituir_hardware!(novo_serial)
      end

      attrs[:serial_number]       = novo_serial if novo_serial.present?
      attrs[:ppp_users_count]     = ppp_users.to_i
      attrs[:hotspot_users_count] = hotspot_users.to_i

      update!(attrs.compact)
    rescue MTik::Error, Errno::ECONNREFUSED, Errno::EHOSTUNREACH => e
      Rails.logger.warn("Falha ao atualizar Mikrotik device #{id} (#{ip}): #{e.message}")
      false
    end

    private

    def default_user     = deviceable&.usuario
    def default_password = deviceable&.senha

    # Serial mudou => hardware físico foi trocado. Desassocia o device antigo
    # (preservando seu histórico) e cria um device novo para o mesmo deviceable.
    def substituir_hardware!(novo_serial)
      alvo = deviceable
      Rails.logger.warn(
        "Serial mudou em #{alvo.class.name} ##{alvo.id} (#{alvo.nome}): " \
        "#{serial_number} -> #{novo_serial}. Substituindo device."
      )

      update!(deviceable: nil)

      novo = Devices::Mikrotik.create!(deviceable: alvo, serial_number: novo_serial)
      novo.atualizar!
    end
  end
end
