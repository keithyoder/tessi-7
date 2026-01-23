# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Faturas::Calendario do
  describe '.proximo_vencimento' do
    subject(:vencimento) do
      described_class.proximo_vencimento(data_base, dia_vencimento)
    end

    context 'quando o dia de vencimento existe no próximo mês' do
      let(:data_base) { Date.new(2026, 1, 10) }
      let(:dia_vencimento) { 10 }

      it 'mantém o mesmo dia no mês seguinte' do
        expect(vencimento).to eq(Date.new(2026, 2, 10))
      end
    end

    context 'quando o dia de vencimento não existe no próximo mês' do
      let(:data_base) { Date.new(2026, 1, 31) }
      let(:dia_vencimento) { 31 }

      it 'ajusta para o último dia do mês' do
        expect(vencimento).to eq(Date.new(2026, 2, 28))
      end
    end

    context 'para proteção contra ciclos curtos (regra histórica)' do
      let(:data_base) { Date.new(2026, 1, 30) }
      let(:dia_vencimento) { 1 }

      it 'pula um mês adicional quando o intervalo é muito curto' do
        # Jan 30 -> Feb 1 = 2 dias → inválido
        # Deve ir para Mar 1
        expect(vencimento).to eq(Date.new(2026, 3, 1))
      end
    end
  end

  describe '.avancar_meses' do
    subject(:vencimento) do
      described_class.avancar_meses(
        vencimento_atual,
        dia_vencimento,
        meses: meses
      )
    end

    let(:vencimento_atual) { Date.new(2026, 1, 31) }
    let(:dia_vencimento)   { 31 }

    context 'quando meses = 1' do
      let(:meses) { 1 }

      it 'equivale a um único próximo vencimento' do
        expect(vencimento).to eq(Date.new(2026, 2, 28))
      end
    end

    context 'quando meses > 1' do
      let(:meses) { 3 }

      it 'avança corretamente respeitando ajuste de fim de mês' do
        # Jan 31 -> Feb 28 -> Mar 31 -> Apr 30
        expect(vencimento).to eq(Date.new(2026, 4, 30))
      end
    end

    context 'quando meses é inválido' do
      let(:meses) { 0 }

      it 'lança erro' do
        expect do
          vencimento
        end.to raise_error(ArgumentError, /meses deve ser >= 1/)
      end
    end
  end

  describe '.periodo' do
    subject(:periodo) do
      described_class.periodo(vencimento_anterior, vencimento_atual)
    end

    let(:vencimento_anterior) { Date.new(2026, 1, 31) }
    let(:vencimento_atual)    { Date.new(2026, 2, 28) }

    it 'inicia no dia seguinte ao vencimento anterior' do
      expect(periodo[:inicio]).to eq(Date.new(2026, 2, 1))
    end

    it 'termina exatamente no vencimento atual' do
      expect(periodo[:fim]).to eq(vencimento_atual)
    end
  end

  describe '.primeiro_periodo' do
    subject(:periodo) do
      described_class.primeiro_periodo(adesao, vencimento)
    end

    let(:adesao)     { Date.new(2026, 1, 10) }
    let(:vencimento) { Date.new(2026, 2, 10) }

    it 'inicia na data de adesão' do
      expect(periodo[:inicio]).to eq(adesao)
    end

    it 'termina no primeiro vencimento' do
      expect(periodo[:fim]).to eq(vencimento)
    end
  end
end
