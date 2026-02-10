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

    def initialize(host, user: 'ubnt', password: 'ubnt')
      @host = host
      @user = user
      @password = password
    end

    # Download and return config as a Hash
    def download_config
      content = Net::SCP.start(host, user, ssh_options) do |scp|
        scp.download!(CONFIG_PATH)
      end
      parse_config(content)
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
        ssh.exec!('reboot')
      end
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
