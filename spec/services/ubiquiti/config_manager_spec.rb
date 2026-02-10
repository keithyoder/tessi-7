# spec/services/ubiquiti/config_manager_spec.rb
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ubiquiti::ConfigManager do
  subject(:manager) { described_class.new('10.14.0.2', password: 'secret', user: 'ubnt') }

  let(:raw_config) do
    <<~CFG
      snmp.status=disabled
      snmp.community=public
      wireless.1.ssid=test-ssid
      radio.1.freq=5180
    CFG
  end

  let(:parsed_config) do
    {
      'snmp.status' => 'disabled',
      'snmp.community' => 'public',
      'wireless.1.ssid' => 'test-ssid',
      'radio.1.freq' => '5180'
    }
  end

  describe '#initialize' do
    it 'sets host, user, and password' do
      expect(manager.host).to eq('10.14.0.2')
      expect(manager.user).to eq('ubnt')
      expect(manager.password).to eq('secret')
    end

    it 'defaults user to ubnt' do
      mgr = described_class.new('10.0.0.1', password: 'pass')
      expect(mgr.user).to eq('ubnt')
    end
  end

  describe '#download_config' do
    it 'downloads and parses the config into a hash' do
      scp = instance_double(Net::SCP)
      allow(Net::SCP).to receive(:start).and_yield(scp)
      allow(scp).to receive(:download!).with('/tmp/system.cfg').and_return(raw_config)

      config = manager.download_config

      expect(config).to eq(parsed_config)
    end

    it 'skips blank lines and comments' do
      content = "# comment\n\nsnmp.status=enabled\n"

      scp = instance_double(Net::SCP)
      allow(Net::SCP).to receive(:start).and_yield(scp)
      allow(scp).to receive(:download!).and_return(content)

      config = manager.download_config

      expect(config).to eq({ 'snmp.status' => 'enabled' })
    end

    it 'handles values containing equals signs' do
      content = "users.1.password=$1$abc=def=\n"

      scp = instance_double(Net::SCP)
      allow(Net::SCP).to receive(:start).and_yield(scp)
      allow(scp).to receive(:download!).and_return(content)

      config = manager.download_config

      expect(config['users.1.password']).to eq('$1$abc=def=')
    end
  end

  describe '#upload_config' do
    it 'uploads the serialized config, persists, and reboots' do
      ssh = instance_double(Net::SSH::Connection::Session)
      scp = instance_double(Net::SCP)

      allow(Net::SSH).to receive(:start).and_yield(ssh)
      allow(ssh).to receive(:scp).and_return(scp)
      allow(scp).to receive(:upload!)
      allow(ssh).to receive(:exec!).and_return('')

      manager.upload_config(parsed_config)

      expect(scp).to have_received(:upload!) do |io, path|
        expect(path).to eq('/tmp/system.cfg')
        content = io.read
        expect(content).to include("snmp.status=disabled\n")
        expect(content).to include("wireless.1.ssid=test-ssid\n")
      end

      expect(ssh).to have_received(:exec!).with('cfgmtd -w')
      expect(ssh).to have_received(:exec!).with('reboot')
    end
  end

  describe '#upload_config ssh options' do
    it 'passes verify_host_key: :never' do
      ssh = instance_double(Net::SSH::Connection::Session)
      scp = instance_double(Net::SCP)

      allow(ssh).to receive(:scp).and_return(scp)
      allow(scp).to receive(:upload!)
      allow(ssh).to receive(:exec!).and_return('')

      allow(Net::SSH).to receive(:start).and_yield(ssh)

      manager.upload_config(parsed_config)

      expect(Net::SSH).to have_received(:start).with(
        '10.14.0.2',
        'ubnt',
        hash_including(verify_host_key: :never, password: 'secret')
      )
    end
  end

  describe '.package_for_restore' do
    it 'creates a gzipped tarball containing system.cfg' do
      config_text = "snmp.status=enabled\n"
      package = described_class.package_for_restore(config_text)

      # Decompress and extract
      io = StringIO.new(package)
      Zlib::GzipReader.wrap(io) do |gz|
        Gem::Package::TarReader.new(gz) do |tar|
          entry = tar.first
          expect(entry.full_name).to eq('system.cfg')
          expect(entry.read).to eq(config_text)
        end
      end
    end
  end
end
