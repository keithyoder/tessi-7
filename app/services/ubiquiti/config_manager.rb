# frozen_string_literal: true

require 'net/ssh'
require 'net/scp'

module Ubiquiti
  class ConfigManager
    CONFIG_PATH = '/tmp/system.cfg'

    SSH_OPTIONS = {
      verify_host_key: :never,
      timeout: 10,
      non_interactive: true
    }.freeze

    attr_reader :host, :user, :password

    def initialize(host, password:, user: 'ubnt')
      @host = host
      @user = user
      @password = password
    end

    def download_config
      content = nil
      Net::SCP.start(host, user, ssh_options) do |scp|
        content = scp.download!(CONFIG_PATH)
      end
      parse_config(content)
    end

    def upload_config(config_hash)
      config_content = serialize_config(config_hash)

      Net::SSH.start(host, user, ssh_options) do |ssh|
        ssh.scp.upload!(StringIO.new(config_content), CONFIG_PATH)
        result = ssh.exec!('cfgmtd -w')
        Rails.logger.info "cfgmtd result: #{result}"
        ssh.exec!('reboot')
      end
    end

    def self.package_for_restore(config_text)
      io = StringIO.new
      Zlib::GzipWriter.wrap(io) do |gz|
        Gem::Package::TarWriter.new(gz) do |tar|
          tar.add_file_simple('system.cfg', 0o644, config_text.bytesize) do |f|
            f.write(config_text)
          end
        end
      end
      io.string
    end

    private

    def ssh_options
      SSH_OPTIONS.merge(password: password)
    end

    def parse_config(content)
      config = {}
      content.each_line do |line|
        line.strip!
        next if line.empty? || line.start_with?('#')

        key, value = line.split('=', 2)
        config[key] = value
      end
      config
    end

    def serialize_config(config_hash)
      config_hash.map { |k, v| "#{k}=#{v}" }.join("\n") + "\n"
    end
  end
end
