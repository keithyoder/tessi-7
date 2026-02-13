# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ubiquiti::SnmpReader do
  let(:ponto) { create(:ponto, :radio, sistema: :Ubnt) }
  let(:device) { create(:ubiquiti_device, deviceable: ponto) }
  let(:reader) { described_class.new(device) }
  let(:manager) { instance_double(SNMP::Manager) }

  let(:raw_mac_bytes) { "\x00\x15\x6D\x9C\x5F\x90".dup.force_encoding('BINARY') }

  def build_varbind(oid_key, value)
    oid_string = described_class::OIDS[oid_key]
    name = double('OID', to_s: oid_string) # rubocop:disable RSpec/VerifiedDoubles
    double('VarBind', name: name, value: value) # rubocop:disable RSpec/VerifiedDoubles
  end

  def build_response(overrides = {})
    defaults = {
      uptime: snmp_string('00:05:30.00'),
      ssid: snmp_string('Tessi-5G'),
      frequencia: snmp_string('5500'),
      canal_tamanho: snmp_string('20'),
      conectados: snmp_string('12'),
      qualidade_airmax: snmp_string('80'),
      station_ccq: snmp_string('95'),
      modelo: snmp_string('NanoStation Loco M5'),
      firmware: snmp_string('XW.ar934x.v6.3.6.12345'),
      sys_descr: snmp_string('Linux 2.6.32 mips'),
      mac: snmp_octet(raw_mac_bytes),
      mac_ubnt: snmp_octet(raw_mac_bytes)
    }.merge(overrides)

    varbinds = defaults.map { |key, value| build_varbind(key, value) }
    response = double('Response') # rubocop:disable RSpec/VerifiedDoubles
    allow(response).to receive(:each_varbind) do |&block|
      varbinds.each { |vb| block.call(vb) }
    end
    response
  end

  def snmp_string(value)
    double('SNMP::OctetString', to_s: value) # rubocop:disable RSpec/VerifiedDoubles
  end

  def snmp_octet(bytes)
    double('SNMP::OctetString', to_s: bytes) # rubocop:disable RSpec/VerifiedDoubles
  end

  def snmp_null
    snmp_string('Null')
  end

  before do
    allow(SNMP::Manager).to receive(:open).and_yield(manager)
  end

  describe '#coletar_informacoes' do
    context 'when all OIDs return valid values' do
      before do
        allow(manager).to receive(:get).and_return(build_response)
      end

      it 'returns parsed SNMP data', :aggregate_failures do
        result = reader.coletar_informacoes

        expect(result[:ssid]).to eq('Tessi-5G')
        expect(result[:frequencia]).to eq('5500')
        expect(result[:canal_tamanho]).to eq('20')
        expect(result[:conectados]).to eq('12')
        expect(result[:qualidade_airmax]).to eq('80')
        expect(result[:station_ccq]).to eq('95')
      end

      it 'returns the modelo' do
        result = reader.coletar_informacoes

        expect(result[:modelo]).to eq('NanoStation Loco M5')
      end

      it 'returns the firmware' do
        result = reader.coletar_informacoes

        expect(result[:firmware]).to eq('XW.ar934x.v6.3.6.12345')
      end

      it 'returns a formatted MAC address' do
        result = reader.coletar_informacoes

        expect(result[:mac]).to eq('00:15:6D:9C:5F:90')
      end
    end

    context 'when modelo returns Null' do
      before do
        response = build_response(modelo: snmp_null)
        allow(manager).to receive(:get).and_return(response)
      end

      it 'falls back to walking the parent OID' do
        walk_vb = double('VarBind', # rubocop:disable RSpec/VerifiedDoubles
                         name: double(to_s: '1.2.840.10036.3.1.2.1.3.7'),
                         value: double(to_s: 'LiteAP AC'))

        allow(manager).to receive(:walk).with('1.2.840.10036.3.1.2.1.3').and_yield(walk_vb)

        result = reader.coletar_informacoes

        expect(result[:modelo]).to eq('LiteAP AC')
      end

      it 'returns nil when walk also finds nothing' do
        allow(manager).to receive(:walk).with('1.2.840.10036.3.1.2.1.3')

        result = reader.coletar_informacoes

        expect(result[:modelo]).to be_nil
      end
    end

    context 'when firmware returns Null' do
      before do
        response = build_response(firmware: snmp_null)
        allow(manager).to receive(:get).and_return(response)
      end

      it 'falls back to walking the parent OID' do
        walk_vb = double('VarBind', # rubocop:disable RSpec/VerifiedDoubles
                         name: double(to_s: '1.2.840.10036.3.1.2.1.4.7'),
                         value: double(to_s: 'WA.ar934x.v8.7.4.45112'))

        allow(manager).to receive(:walk).with('1.2.840.10036.3.1.2.1.4').and_yield(walk_vb)

        result = reader.coletar_informacoes

        expect(result[:firmware]).to eq('WA.ar934x.v8.7.4.45112')
      end

      it 'returns nil when walk also finds nothing' do
        allow(manager).to receive(:walk).with('1.2.840.10036.3.1.2.1.4')

        result = reader.coletar_informacoes

        expect(result[:firmware]).to be_nil
      end
    end

    context 'when primary MAC returns invalid data' do
      it 'falls back to mac_ubnt' do
        ubnt_mac = "\x18\xE8\x29\x7E\xCD\xAE".dup.force_encoding('BINARY')
        bad_mac = "\x00\x00\x00\x00\x00\x00".dup.force_encoding('BINARY')
        response = build_response(
          mac: snmp_octet(bad_mac),
          mac_ubnt: snmp_octet(ubnt_mac)
        )
        allow(manager).to receive(:get).and_return(response)

        result = reader.coletar_informacoes

        expect(result[:mac]).to eq('18:E8:29:7E:CD:AE')
      end
    end

    context 'when device is unreachable' do
      it 'raises SNMP::RequestTimeout' do
        allow(manager).to receive(:get).and_raise(SNMP::RequestTimeout)

        expect { reader.coletar_informacoes }.to raise_error(SNMP::RequestTimeout)
      end
    end
  end

  describe '#acessivel?' do
    it 'returns true when device responds' do
      allow(manager).to receive(:get).and_return(double)

      expect(reader.acessivel?).to be true
    end

    it 'returns false on timeout' do
      allow(manager).to receive(:get).and_raise(SNMP::RequestTimeout)

      expect(reader.acessivel?).to be false
    end

    it 'returns false when host is unreachable' do
      allow(manager).to receive(:get).and_raise(Errno::EHOSTUNREACH)

      expect(reader.acessivel?).to be false
    end
  end

  describe '#estatisticas_conexao' do
    it 'returns connection statistics' do
      allow(manager).to receive(:get).and_return(build_response)

      stats = reader.estatisticas_conexao

      expect(stats[:conectados]).to eq(12)
      expect(stats[:qualidade_airmax]).to eq(80)
      expect(stats[:station_ccq]).to eq(95)
    end

    it 'returns zeros on timeout' do
      allow(manager).to receive(:get).and_raise(SNMP::RequestTimeout)

      stats = reader.estatisticas_conexao

      expect(stats).to eq(conectados: 0, qualidade_airmax: 0, station_ccq: 0)
    end
  end
end
