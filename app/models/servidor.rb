# frozen_string_literal: true

class Servidor < ApplicationRecord
  require 'csv'
  require 'cgi'
  has_many :pontos, dependent: :restrict_with_exception
  has_many :conexoes, through: :pontos
  has_many :autenticacoes, through: :pontos
  has_one_attached :backup

  scope :ativo, -> { where('ativo') }

  def self.to_csv
    attributes = %w[id nome ip ativo api_porta ssh_porta snmp_porta snmp_comunidade]
    CSV.generate(headers: true) do |csv|
      csv << attributes

      all.find_each do |servidor|
        csv << attributes.map { |attr| servidor.send(attr) }
      end
    end
  end

  def mk_command(command)
    return unless usuario.present? && senha.present?

    MTik.command(
      host: ip.to_s,
      user: usuario,
      pass: senha,
      use_ssl: true,
      unencrypted_plaintext: true,
      command: command
    )
  end

  def desconectar_hotspot(usuario)
    id = mk_command(
      [
        '/ip/hotspot/active/print',
        "?user=#{usuario}"
      ]
    )[0][0]['.id']
    mk_command(['/ip/hotspot/active/remove', "=.id=#{id}"])
  rescue MTik::Error, Errno::ECONNREFUSED, Errno::EHOSTUNREACH => e
    Rails.logger.info e.message
  end

  def desconectar_pppoe(usuario)
    id = mk_command(
      [
        '/ppp/active/print',
        '=.proplist=.id',
        "?name=#{usuario}"
      ]
    )[0][0]['.id']
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
  rescue StandardError => e
    nil
  end

  def ping?
    check = Net::Ping::External.new(ip.to_s)
    check.ping?
  end

  def autenticando?
    autenticacoes.where('authdate > ?', 12.hours.ago).count.positive?
  end

  def copiar_backup
    login = "#{CGI.escape(usuario)}:#{CGI.escape(senha)}"
    filename = ERB::Util.url_encode(nome)
    fi = open("ftp://#{login}@#{ip}/#{filename}-backup.rsc")
    backup.attach(io: fi, filename: "#{nome}-backup.rsc")
  end

  def backup_status
    return unless backup.attached?

    if backup.created_at > 1.week.ago
      'primary'
    elsif backup.created_at > 2.weeks.ago
      'warning'
    else
      'danger'
    end
  end
end
