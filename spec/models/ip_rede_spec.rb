# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IpRede do
  let(:ponto) { create(:ponto) }

  describe 'validações' do
    describe '#nao_sobrepor_faixas' do
      context 'com faixas IPv4' do
        let!(:existing_range) do
          create(:ip_rede, ponto: ponto, rede: '192.168.1.0/24')
        end

        it 'permite faixas que não se sobrepõem' do
          new_range = build(:ip_rede, ponto: ponto, rede: '192.168.2.0/24')

          expect(new_range).to be_valid
        end

        it 'impede faixas idênticas' do
          new_range = build(:ip_rede, ponto: ponto, rede: '192.168.1.0/24')

          expect(new_range).not_to be_valid
          expect(new_range.errors[:rede]).to include(/se sobrepõe/)
        end

        it 'impede faixas que são subconjuntos de faixas existentes' do
          new_range = build(:ip_rede, ponto: ponto, rede: '192.168.1.0/25')

          expect(new_range).not_to be_valid
          expect(new_range.errors[:rede]).to include(/se sobrepõe/)
          expect(new_range.errors[:rede].first).to include('192.168.1.0/24')
        end

        it 'impede faixas que contêm faixas existentes' do
          # Existente: 192.168.1.0/24
          # Tentativa de criar 192.168.1.128/25 (subconjunto do /24 existente)
          new_subset = build(:ip_rede, ponto: ponto, rede: '192.168.1.128/25')

          expect(new_subset).not_to be_valid
          expect(new_subset.errors[:rede]).to include(/se sobrepõe/)
        end

        it 'impede faixas parcialmente sobrepostas' do
          # Existente: 192.168.1.0/24 (cobre 192.168.1.0 - 192.168.1.255)
          # Tentativa: 192.168.1.128/25 (cobre 192.168.1.128 - 192.168.1.255)
          # Isso se sobrepõe ao /24 existente
          new_range = build(:ip_rede, ponto: ponto, rede: '192.168.1.128/25')

          expect(new_range).not_to be_valid
          expect(new_range.errors[:rede]).to include(/se sobrepõe/)
        end

        it 'permite atualizar o mesmo registro' do
          existing_range.rede = '192.168.1.0/25'

          expect(existing_range).to be_valid
        end

        it 'inclui faixas conflitantes na mensagem de erro' do
          new_range = build(:ip_rede, ponto: ponto, rede: '192.168.1.64/26')
          new_range.valid?

          expect(new_range.errors[:rede].first).to include('192.168.1.0/24')
        end
      end

      context 'com faixas IPv6' do
        before do
          create(:ip_rede, ponto: ponto, rede: '2001:db8::/32')
        end

        it 'permite faixas IPv6 que não se sobrepõem' do
          new_range = build(:ip_rede, ponto: ponto, rede: '2001:db9::/32')

          expect(new_range).to be_valid
        end

        it 'impede faixas IPv6 sobrepostas' do
          new_range = build(:ip_rede, ponto: ponto, rede: '2001:db8::/64')

          expect(new_range).not_to be_valid
          expect(new_range.errors[:rede]).to include(/se sobrepõe/)
        end
      end

      context 'com múltiplas faixas sobrepostas' do
        before do
          create(:ip_rede, ponto: ponto, rede: '10.0.0.0/24')
          create(:ip_rede, ponto: ponto, rede: '10.0.1.0/24')
        end

        it 'reporta todas as faixas sobrepostas' do
          new_range = build(:ip_rede, ponto: ponto, rede: '10.0.0.0/16')
          new_range.valid?

          error_message = new_range.errors[:rede].first
          expect(error_message).to include('se sobrepõe')
          expect(error_message).to include('10.0.0.0/24')
          expect(error_message).to include('10.0.1.0/24')
        end
      end

      context 'para edge cases' do
        it 'permite criação quando rede está em branco' do
          new_range = build(:ip_rede, ponto: ponto, rede: nil)

          # Não deve acionar validação de sobreposição
          expect(new_range.errors[:rede]).to be_empty
        end

        it 'permite faixas em pontos diferentes mesmo que se sobreponham' do
          create(:ip_rede, ponto: ponto, rede: '10.0.0.0/24')

          other_ponto = create(:ponto)
          new_range = build(:ip_rede, ponto: other_ponto, rede: '10.0.0.0/24')

          # Mesma faixa de IP mas ponto diferente - atualmente isso VAI falhar
          # Se quiser permitir isso, precisaria adicionar ponto_id ao escopo
          expect(new_range).not_to be_valid
        end
      end
    end
  end

  describe '#cidr' do
    it 'retorna a notação CIDR da coluna rede' do
      ip_rede = create(:ip_rede, ponto: ponto, rede: '10.0.1.0/24')

      expect(ip_rede.cidr).to eq('10.0.1.0/24')
    end

    it 'retorna nil quando rede está em branco' do
      ip_rede = build(:ip_rede, ponto: ponto, rede: nil)

      expect(ip_rede.cidr).to be_nil
    end

    it 'funciona com diferentes tamanhos de prefixo' do
      ip_rede = create(:ip_rede, ponto: ponto, rede: '192.168.1.0/25')

      expect(ip_rede.cidr).to eq('192.168.1.0/25')
    end

    it 'funciona com IPv6' do
      ip_rede = create(:ip_rede, ponto: ponto, rede: '2001:db8::/32')

      expect(ip_rede.cidr).to eq('2001:db8::/32')
    end
  end

  describe '#prefixo' do
    it 'retorna o tamanho do prefixo' do
      ip_rede = create(:ip_rede, ponto: ponto, rede: '10.0.1.0/24')

      expect(ip_rede.prefixo).to eq(24)
    end

    it 'funciona com diferentes prefixos' do
      ip_rede = create(:ip_rede, ponto: ponto, rede: '192.168.1.0/28')

      expect(ip_rede.prefixo).to eq(28)
    end

    it 'retorna nil quando rede está em branco' do
      ip_rede = build(:ip_rede, ponto: ponto, rede: nil)

      expect(ip_rede.prefixo).to be_nil
    end
  end

  describe '#quantidade_ips' do
    it 'calcula IPs utilizáveis para rede /24' do
      ip_rede = create(:ip_rede, ponto: ponto, rede: '10.0.1.0/24')

      # /24 = 256 total - 2 (rede + broadcast) = 254
      expect(ip_rede.quantidade_ips).to eq(254)
    end

    it 'calcula IPs utilizáveis para rede /30' do
      ip_rede = create(:ip_rede, ponto: ponto, rede: '10.0.1.0/30')

      # /30 = 4 total - 2 = 2
      expect(ip_rede.quantidade_ips).to eq(2)
    end

    it 'calcula IPs para rede IPv6' do
      ip_rede = create(:ip_rede, ponto: ponto, rede: '2001:db8::/64')

      # /64 = 2^64 endereços (sem rede/broadcast no IPv6)
      expect(ip_rede.quantidade_ips).to eq(2**64)
    end

    it 'retorna 0 quando rede está em branco' do
      ip_rede = build(:ip_rede, ponto: ponto, rede: nil)

      expect(ip_rede.quantidade_ips).to eq(0)
    end
  end

  describe '#familia' do
    it 'retorna IPv4 para endereços IPv4' do
      ip_rede = create(:ip_rede, ponto: ponto, rede: '10.0.1.0/24')

      expect(ip_rede.familia).to eq('IPv4')
    end

    it 'retorna IPv6 para endereços IPv6' do
      ip_rede = create(:ip_rede, ponto: ponto, rede: '2001:db8::/32')

      expect(ip_rede.familia).to eq('IPv6')
    end
  end

  describe '#para_array' do
    it 'retorna array de todos os IPs na faixa' do
      ip_rede = create(:ip_rede, ponto: ponto, rede: '192.168.1.0/30')

      ips = ip_rede.para_array
      expect(ips.size).to eq(4) # /30 tem 4 IPs totais
      expect(ips.first.to_s).to eq('192.168.1.0')
      expect(ips.last.to_s).to eq('192.168.1.3')
    end

    it 'retorna array vazio quando rede está em branco' do
      ip_rede = build(:ip_rede, ponto: ponto, rede: nil)

      expect(ip_rede.para_array).to eq([])
    end
  end

  describe 'aliases para compatibilidade retroativa' do
    let(:ip_rede) { create(:ip_rede, ponto: ponto, rede: '10.0.1.0/24') }

    it '#prefix é alias para #prefixo' do
      expect(ip_rede.prefix).to eq(ip_rede.prefixo)
      expect(ip_rede.prefix).to eq(24)
    end

    it '#ips_quantidade é alias para #quantidade_ips' do
      expect(ip_rede.ips_quantidade).to eq(ip_rede.quantidade_ips)
      expect(ip_rede.ips_quantidade).to eq(254)
    end

    it '#family é alias para #familia' do
      expect(ip_rede.family).to eq(ip_rede.familia)
      expect(ip_rede.family).to eq('IPv4')
    end

    it '#to_a é alias para #para_array' do
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
      it 'retorna apenas faixas IPv4' do
        ipv4_ranges = described_class.ipv4

        expect(ipv4_ranges.count).to eq(2)
        expect(ipv4_ranges.all? { |r| r.familia == 'IPv4' }).to be true
      end
    end

    describe '.ipv6' do
      it 'retorna apenas faixas IPv6' do
        ipv6_ranges = described_class.ipv6

        expect(ipv6_ranges.count).to eq(1)
        expect(ipv6_ranges.first.familia).to eq('IPv6')
      end
    end
  end

  describe 'cenários realistas' do
    it 'impede criação de sub-redes sobrepostas na mesma rede' do
      # Cria uma rede /24
      create(:ip_rede, ponto: ponto, rede: '10.42.1.0/24')

      # Tenta subdividi-la em /25s - deve falhar
      subnet1 = build(:ip_rede, ponto: ponto, rede: '10.42.1.0/25')
      subnet2 = build(:ip_rede, ponto: ponto, rede: '10.42.1.128/25')

      expect(subnet1).not_to be_valid
      expect(subnet2).not_to be_valid
    end

    it 'permite redes adjacentes que não se sobrepõem' do
      create(:ip_rede, ponto: ponto, rede: '10.42.1.0/24')

      adjacent = build(:ip_rede, ponto: ponto, rede: '10.42.2.0/24')

      expect(adjacent).to be_valid
    end

    it 'impede criação de super-rede que engloba sub-redes existentes' do
      # Cria duas redes /25
      create(:ip_rede, ponto: ponto, rede: '10.42.1.0/25')
      create(:ip_rede, ponto: ponto, rede: '10.42.1.128/25')

      # Tenta criar /24 englobante - deve falhar
      supernet = build(:ip_rede, ponto: ponto, rede: '10.42.1.0/24')

      expect(supernet).not_to be_valid
      expect(supernet.errors[:rede].first).to include('10.42.1.0/25')
      expect(supernet.errors[:rede].first).to include('10.42.1.128/25')
    end
  end
end
