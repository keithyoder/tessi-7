# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Faturas::PeriodoUtilizado do
  describe '.call' do
    subject(:resultado) do
      described_class.call(inicio: inicio, fim: fim)
    end

    context 'quando o fim é igual ao início' do
      let(:inicio) { Date.new(2026, 1, 10) }
      let(:fim)    { Date.new(2026, 1, 10) }

      it 'retorna 0' do
        expect(resultado).to eq(0.to_d)
      end
    end

    context 'quando o fim está dentro do período mensal' do
      let(:inicio) { Date.new(2026, 1, 10) }
      let(:fim)    { Date.new(2026, 1, 25) }

      it 'retorna a fração correta do período' do
        # Jan 10 -> Feb 10 = 31 dias
        # Jan 10 -> Jan 25 = 15 dias
        expect(resultado).to eq(15.to_d / 31)
      end
    end

    context 'quando o fim é o último dia faturado do período' do
      let(:inicio) { Date.new(2026, 1, 10) }
      let(:fim)    { Date.new(2026, 2, 9) }

      it 'não retorna 1, pois o fim é exclusivo' do
        # Jan 10 -> Feb 10 = 31 dias
        # Jan 10 -> Feb 9  = 30 dias
        expect(resultado).to eq(30.to_d / 31)
      end
    end

    context 'quando o fim é igual ao término do período' do
      let(:inicio) { Date.new(2026, 1, 10) }
      let(:fim)    { Date.new(2026, 2, 10) }

      it 'retorna 1' do
        expect(resultado).to eq(1.to_d)
      end
    end

    context 'quando o fim ultrapassa o período mensal' do
      let(:inicio) { Date.new(2026, 1, 10) }
      let(:fim)    { Date.new(2026, 3, 1) }

      it 'retorna no máximo 1' do
        expect(resultado).to eq(1.to_d)
      end
    end

    context 'quando o período cruza fevereiro' do
      let(:inicio) { Date.new(2026, 1, 31) }
      let(:fim)    { Date.new(2026, 2, 10) }

      it 'calcula corretamente considerando a duração real do mês' do
        # Jan 31 -> Feb 28 (2026 não é bissexto) = 28 dias
        # Jan 31 -> Feb 10 = 10 dias
        expect(resultado).to eq(10.to_d / 28)
      end
    end

    context 'quando o período cruza fevereiro em ano bissexto' do
      let(:inicio) { Date.new(2024, 1, 31) }
      let(:fim)    { Date.new(2024, 2, 10) }

      it 'considera fevereiro com 29 dias' do
        # Jan 31 -> Feb 29 = 29 dias
        # Jan 31 -> Feb 10 = 10 dias
        expect(resultado).to eq(10.to_d / 29)
      end
    end

    context 'quando o fim é anterior ao início' do
      let(:inicio) { Date.new(2026, 1, 10) }
      let(:fim)    { Date.new(2026, 1, 9) }

      it 'lança um erro claro' do
        expect do
          resultado
        end.to raise_error(ArgumentError, /Data final não pode ser anterior/)
      end
    end

    context 'para garantias numéricas' do
      let(:inicio) { Date.new(2026, 1, 10) }

      it 'nunca retorna valor negativo' do
        fim = Date.new(2026, 1, 10)
        valor = described_class.call(inicio: inicio, fim: fim)
        expect(valor).to be >= 0.to_d
      end

      it 'nunca retorna valor maior que 1' do
        fim = Date.new(2030, 1, 1)
        valor = described_class.call(inicio: inicio, fim: fim)
        expect(valor).to be <= 1.to_d
      end
    end
  end
end
