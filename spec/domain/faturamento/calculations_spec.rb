# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Faturamento::Calculations do
  describe '.calcular_percentual' do
    it 'calculates positive percentage correctly' do
      expect(described_class.calcular_percentual(120, 100)).to eq(20.0)
    end

    it 'calculates negative percentage correctly' do
      expect(described_class.calcular_percentual(80, 100)).to eq(-20.0)
    end

    it 'handles zero base gracefully' do
      expect(described_class.calcular_percentual(100, 0)).to eq(0.0)
    end

    it 'handles zero atual value' do
      expect(described_class.calcular_percentual(0, 100)).to eq(-100.0)
    end

    it 'handles both zeros' do
      expect(described_class.calcular_percentual(0, 0)).to eq(0.0)
    end

    it 'rounds to 2 decimal places' do
      expect(described_class.calcular_percentual(123.456, 100)).to eq(23.46)
    end
  end

  describe '.calcular_comparacao' do
    context 'when atual is greater than esperado' do
      it 'returns positive diferenca and performance acima' do
        result = described_class.calcular_comparacao(120, 100)

        expect(result[:diferenca]).to eq(20)
        expect(result[:percentual]).to eq(20.0)
        expect(result[:performance]).to eq(:acima)
      end
    end

    context 'when atual is less than esperado' do
      it 'returns negative diferenca and performance abaixo' do
        result = described_class.calcular_comparacao(80, 100)

        expect(result[:diferenca]).to eq(-20)
        expect(result[:percentual]).to eq(-20.0)
        expect(result[:performance]).to eq(:abaixo)
      end
    end

    context 'when atual equals esperado' do
      it 'returns zero diferenca and performance acima' do
        result = described_class.calcular_comparacao(100, 100)

        expect(result[:diferenca]).to eq(0)
        expect(result[:percentual]).to eq(0.0)
        expect(result[:performance]).to eq(:acima)
      end
    end

    context 'when esperado is zero' do
      it 'handles gracefully with zero percentual' do
        result = described_class.calcular_comparacao(100, 0)

        expect(result[:diferenca]).to eq(100)
        expect(result[:percentual]).to eq(0.0)
        expect(result[:performance]).to eq(:acima)
      end
    end
  end

  describe '.calcular_ticket_medio' do
    it 'calculates ticket medio correctly' do
      expect(described_class.calcular_ticket_medio(1000, 10)).to eq(100.0)
    end

    it 'handles zero quantidade gracefully' do
      expect(described_class.calcular_ticket_medio(1000, 0)).to eq(0.0)
    end

    it 'rounds to 2 decimal places' do
      expect(described_class.calcular_ticket_medio(1000, 3)).to eq(333.33)
    end

    it 'handles fractional results' do
      expect(described_class.calcular_ticket_medio(100.50, 2)).to eq(50.25)
    end
  end

  describe '.build_resumo' do
    it 'builds complete resumo structure' do
      result = described_class.build_resumo(
        total_recebido: 120,
        total_esperado: 100,
        total_faturas: 10
      )

      expect(result).to include(
        total_recebido: 120,
        total_esperado: 100,
        diferenca: 20,
        percentual_diferenca: 20.0,
        performance: :acima,
        total_faturas: 10
      )
    end

    it 'merges extra attributes' do
      result = described_class.build_resumo(
        total_recebido: 100,
        total_esperado: 100,
        total_faturas: 5,
        media_mensal: 50.0,
        dias_decorridos: 15
      )

      expect(result).to include(
        media_mensal: 50.0,
        dias_decorridos: 15
      )
    end

    it 'handles negative performance' do
      result = described_class.build_resumo(
        total_recebido: 80,
        total_esperado: 100,
        total_faturas: 8
      )

      expect(result[:performance]).to eq(:abaixo)
      expect(result[:diferenca]).to eq(-20)
    end
  end

  describe '.resumo_vazio' do
    it 'returns zeros for all standard fields' do
      result = described_class.resumo_vazio

      expect(result).to eq(
        total_recebido: 0.0,
        total_esperado: 0.0,
        diferenca: 0.0,
        percentual_diferenca: 0.0,
        performance: :acima,
        total_faturas: 0
      )
    end

    it 'allows extra attributes' do
      result = described_class.resumo_vazio(
        meses_processados: 0,
        media_mensal: 0.0
      )

      expect(result).to include(
        meses_processados: 0,
        media_mensal: 0.0
      )
    end
  end
end
