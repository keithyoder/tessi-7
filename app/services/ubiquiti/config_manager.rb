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
      ConfigParser.to_hash(content)
    end

    def upload_config(config_hash)
      config_content = ConfigParser.to_text(config_hash)

      Net::SSH.start(host, user, ssh_options) do |ssh|
        ssh.scp.upload!(StringIO.new(config_content), CONFIG_PATH)
        result = ssh.exec!('cfgmtd -w')
        Rails.logger.info "cfgmtd result: #{result}"
        ssh.exec!('reboot')
      end
    end

    private

    def ssh_options
      SSH_OPTIONS.merge(password: password)
    end
  end
end
