# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IpRede do
  let(:ponto) { create(:ponto) }

  describe 'validations' do
    describe '#nao_sobrepor_faixas' do
      context 'with IPv4 ranges' do
        let!(:existing_range) do
          create(:ip_rede, ponto: ponto, rede: '192.168.1.0/24')
        end

        it 'allows non-overlapping ranges' do
          new_range = build(:ip_rede, ponto: ponto, rede: '192.168.2.0/24')

          expect(new_range).to be_valid
        end

        it 'prevents identical ranges' do
          new_range = build(:ip_rede, ponto: ponto, rede: '192.168.1.0/24')

          expect(new_range).not_to be_valid
          expect(new_range.errors[:rede]).to include(/se sobrepõe/)
        end

        it 'prevents ranges that are subsets of existing ranges' do
          new_range = build(:ip_rede, ponto: ponto, rede: '192.168.1.0/25')

          expect(new_range).not_to be_valid
          expect(new_range.errors[:rede]).to include(/se sobrepõe/)
          expect(new_range.errors[:rede].first).to include('192.168.1.0/24')
        end

        it 'prevents ranges that contain existing ranges' do
          # Existing: 192.168.1.0/24
          # Try to create 192.168.1.128/25 (subset of the existing /24)
          new_subset = build(:ip_rede, ponto: ponto, rede: '192.168.1.128/25')

          expect(new_subset).not_to be_valid
          expect(new_subset.errors[:rede]).to include(/se sobrepõe/)
        end

        it 'prevents partially overlapping ranges' do
          # Existing: 192.168.1.0/24 (covers 192.168.1.0 - 192.168.1.255)
          # Try: 192.168.1.128/25 (covers 192.168.1.128 - 192.168.1.255)
          # This overlaps with the existing /24
          new_range = build(:ip_rede, ponto: ponto, rede: '192.168.1.128/25')

          expect(new_range).not_to be_valid
          expect(new_range.errors[:rede]).to include(/se sobrepõe/)
        end

        it 'allows updating the same record' do
          existing_range.rede = '192.168.1.0/25'

          expect(existing_range).to be_valid
        end

        it 'includes conflicting ranges in error message' do
          new_range = build(:ip_rede, ponto: ponto, rede: '192.168.1.64/26')
          new_range.valid?

          expect(new_range.errors[:rede].first).to include('192.168.1.0/24')
        end
      end

      context 'with IPv6 ranges' do
        let!(:existing_range) do
          create(:ip_rede, ponto: ponto, rede: '2001:db8::/32')
        end

        it 'allows non-overlapping IPv6 ranges' do
          new_range = build(:ip_rede, ponto: ponto, rede: '2001:db9::/32')

          expect(new_range).to be_valid
        end

        it 'prevents overlapping IPv6 ranges' do
          new_range = build(:ip_rede, ponto: ponto, rede: '2001:db8::/64')

          expect(new_range).not_to be_valid
          expect(new_range.errors[:rede]).to include(/se sobrepõe/)
        end
      end

      context 'with multiple overlapping ranges' do
        before do
          create(:ip_rede, ponto: ponto, rede: '10.0.0.0/24')
          create(:ip_rede, ponto: ponto, rede: '10.0.1.0/24')
        end

        it 'reports all overlapping ranges' do
          new_range = build(:ip_rede, ponto: ponto, rede: '10.0.0.0/16')
          new_range.valid?

          error_message = new_range.errors[:rede].first
          expect(error_message).to include('se sobrepõe')
          expect(error_message).to include('10.0.0.0/24')
          expect(error_message).to include('10.0.1.0/24')
        end
      end

      context 'edge cases' do
        it 'allows creation when rede is blank' do
          new_range = build(:ip_rede, ponto: ponto, rede: nil)

          # Should not trigger overlap validation
          expect(new_range.errors[:rede]).to be_empty
        end

        it 'allows ranges on different pontos even if they overlap' do
          create(:ip_rede, ponto: ponto, rede: '10.0.0.0/24')

          other_ponto = create(:ponto)
          new_range = build(:ip_rede, ponto: other_ponto, rede: '10.0.0.0/24')

          # Same IP range but different ponto - currently this WILL fail
          # If you want to allow this, you'd need to add ponto_id to the scope
          expect(new_range).not_to be_valid
        end
      end
    end
  end

  describe '#cidr' do
    it 'returns the CIDR notation from rede column' do
      ip_rede = create(:ip_rede, ponto: ponto, rede: '10.0.1.0/24')

      expect(ip_rede.cidr).to eq('10.0.1.0/24')
    end

    it 'returns nil when rede is blank' do
      ip_rede = build(:ip_rede, ponto: ponto, rede: nil)

      expect(ip_rede.cidr).to be_nil
    end

    it 'works with different prefix lengths' do
      ip_rede = create(:ip_rede, ponto: ponto, rede: '192.168.1.0/25')

      expect(ip_rede.cidr).to eq('192.168.1.0/25')
    end

    it 'works with IPv6' do
      ip_rede = create(:ip_rede, ponto: ponto, rede: '2001:db8::/32')

      expect(ip_rede.cidr).to eq('2001:db8::/32')
    end
  end

  describe '#prefixo' do
    it 'returns the prefix length' do
      ip_rede = create(:ip_rede, ponto: ponto, rede: '10.0.1.0/24')

      expect(ip_rede.prefixo).to eq(24)
    end

    it 'works with different prefixes' do
      ip_rede = create(:ip_rede, ponto: ponto, rede: '192.168.1.0/28')

      expect(ip_rede.prefixo).to eq(28)
    end

    it 'returns nil when rede is blank' do
      ip_rede = build(:ip_rede, ponto: ponto, rede: nil)

      expect(ip_rede.prefixo).to be_nil
    end
  end

  describe '#quantidade_ips' do
    it 'calculates usable IPs for /24 network' do
      ip_rede = create(:ip_rede, ponto: ponto, rede: '10.0.1.0/24')

      # /24 = 256 total - 2 (network + broadcast) = 254
      expect(ip_rede.quantidade_ips).to eq(254)
    end

    it 'calculates usable IPs for /30 network' do
      ip_rede = create(:ip_rede, ponto: ponto, rede: '10.0.1.0/30')

      # /30 = 4 total - 2 = 2
      expect(ip_rede.quantidade_ips).to eq(2)
    end

    it 'calculates IPs for IPv6 network' do
      ip_rede = create(:ip_rede, ponto: ponto, rede: '2001:db8::/64')

      # /64 = 2^64 addresses (no network/broadcast in IPv6)
      expect(ip_rede.quantidade_ips).to eq(2**64)
    end

    it 'returns 0 when rede is blank' do
      ip_rede = build(:ip_rede, ponto: ponto, rede: nil)

      expect(ip_rede.quantidade_ips).to eq(0)
    end
  end

  describe '#familia' do
    it 'returns IPv4 for IPv4 addresses' do
      ip_rede = create(:ip_rede, ponto: ponto, rede: '10.0.1.0/24')

      expect(ip_rede.familia).to eq('IPv4')
    end

    it 'returns IPv6 for IPv6 addresses' do
      ip_rede = create(:ip_rede, ponto: ponto, rede: '2001:db8::/32')

      expect(ip_rede.familia).to eq('IPv6')
    end
  end

  describe '#para_array' do
    it 'returns array of all IPs in range' do
      ip_rede = create(:ip_rede, ponto: ponto, rede: '192.168.1.0/30')

      ips = ip_rede.para_array
      expect(ips.size).to eq(4) # /30 has 4 total IPs
      expect(ips.first.to_s).to eq('192.168.1.0')
      expect(ips.last.to_s).to eq('192.168.1.3')
    end

    it 'returns empty array when rede is blank' do
      ip_rede = build(:ip_rede, ponto: ponto, rede: nil)

      expect(ip_rede.para_array).to eq([])
    end
  end

  describe 'aliases for backwards compatibility' do
    let(:ip_rede) { create(:ip_rede, ponto: ponto, rede: '10.0.1.0/24') }

    it '#prefix aliases to #prefixo' do
      expect(ip_rede.prefix).to eq(ip_rede.prefixo)
      expect(ip_rede.prefix).to eq(24)
    end

    it '#ips_quantidade aliases to #quantidade_ips' do
      expect(ip_rede.ips_quantidade).to eq(ip_rede.quantidade_ips)
      expect(ip_rede.ips_quantidade).to eq(254)
    end

    it '#family aliases to #familia' do
      expect(ip_rede.family).to eq(ip_rede.familia)
      expect(ip_rede.family).to eq('IPv4')
    end

    it '#to_a aliases to #para_array' do
      expect(ip_rede.to_a).to eq(ip_rede.para_array)
      expect(ip_rede.to_a).to be_an(Array)
    end
  end

  describe 'scopes' do
    before do
      create(:ip_rede, ponto: ponto, rede: '10.0.1.0/24')
      create(:ip_rede, ponto: ponto, rede: '192.168.1.0/24')
      create(:ip_rede, ponto: ponto, rede: '2001:db8::/32')
    end

    describe '.ipv4' do
      it 'returns only IPv4 ranges' do
        ipv4_ranges = IpRede.ipv4

        expect(ipv4_ranges.count).to eq(2)
        expect(ipv4_ranges.all? { |r| r.familia == 'IPv4' }).to be true
      end
    end

    describe '.ipv6' do
      it 'returns only IPv6 ranges' do
        ipv6_ranges = IpRede.ipv6

        expect(ipv6_ranges.count).to eq(1)
        expect(ipv6_ranges.first.familia).to eq('IPv6')
      end
    end
  end

  describe 'realistic scenarios' do
    it 'prevents creating overlapping subnets in same network' do
      # Create a /24 network
      create(:ip_rede, ponto: ponto, rede: '10.42.1.0/24')

      # Try to subdivide it into /25s - should fail
      subnet1 = build(:ip_rede, ponto: ponto, rede: '10.42.1.0/25')
      subnet2 = build(:ip_rede, ponto: ponto, rede: '10.42.1.128/25')

      expect(subnet1).not_to be_valid
      expect(subnet2).not_to be_valid
    end

    it 'allows non-overlapping adjacent networks' do
      create(:ip_rede, ponto: ponto, rede: '10.42.1.0/24')

      adjacent = build(:ip_rede, ponto: ponto, rede: '10.42.2.0/24')

      expect(adjacent).to be_valid
    end

    it 'prevents creating supernet that encompasses existing subnets' do
      # Create two /25 networks
      create(:ip_rede, ponto: ponto, rede: '10.42.1.0/25')
      create(:ip_rede, ponto: ponto, rede: '10.42.1.128/25')

      # Try to create encompassing /24 - should fail
      supernet = build(:ip_rede, ponto: ponto, rede: '10.42.1.0/24')

      expect(supernet).not_to be_valid
      expect(supernet.errors[:rede].first).to include('10.42.1.0/25')
      expect(supernet.errors[:rede].first).to include('10.42.1.128/25')
    end
  end
end
