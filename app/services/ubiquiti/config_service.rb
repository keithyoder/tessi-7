require 'net/ssh'
require 'net/scp'

module Ubiquiti
  class ConfigService
    CONFIG_PATH = '/tmp/system.cfg'.freeze

    def initialize(host, user: 'ubnt', password: 'ubnt')
      @host = host
      @user = user
      @password = password
    end

    # Download and return config as a Hash
    def download_config
      config_content = nil
      Net::SCP.start(@host, @user, password: @password) do |scp|
        config_content = scp.download!(CONFIG_PATH)
      end
      parse_config(config_content)
    end

    # Upload modified config and persist
    def upload_config(config_hash)
      config_content = serialize_config(config_hash)

      Net::SSH.start(@host, @user, password: @password) do |ssh|
        # Upload via SCP
        ssh.scp.upload!(StringIO.new(config_content), CONFIG_PATH)

        # Persist to flash
        result = ssh.exec!('cfgmtd -w')
        Rails.logger.info "cfgmtd result: #{result}"

        # Apply without full reboot (optional)
        # ssh.exec!('reboot')
      end
    end

    private

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
