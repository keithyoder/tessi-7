# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Faturamento::Periods do
  describe '.ano_range' do
    it 'returns full year range for past years' do
      range = described_class.ano_range(2023)

      expect(range.first).to eq(Date.new(2023, 1, 1))
      expect(range.last).to eq(Date.new(2023, 12, 31))
    end

    it 'caps at current date for current year' do
      travel_to Date.new(2026, 6, 15) do
        range = described_class.ano_range(2026)

        expect(range.first).to eq(Date.new(2026, 1, 1))
        expect(range.last).to eq(Date.new(2026, 6, 15))
      end
    end

    it 'caps at current date for future years' do
      travel_to Date.new(2026, 3, 10) do
        range = described_class.ano_range(2027)

        expect(range.first).to eq(Date.new(2027, 1, 1))
        expect(range.last).to eq(Date.new(2026, 3, 10))
      end
    end
  end

  describe '.mes_range' do
    it 'returns full month range for past months' do
      travel_to Date.new(2026, 3, 15) do
        range = described_class.mes_range(2026, 1)

        expect(range.first).to eq(Date.new(2026, 1, 1))
        expect(range.last).to eq(Date.new(2026, 1, 31))
      end
    end

    it 'caps at current date for current month' do
      travel_to Date.new(2026, 3, 15) do
        range = described_class.mes_range(2026, 3)

        expect(range.first).to eq(Date.new(2026, 3, 1))
        expect(range.last).to eq(Date.new(2026, 3, 15))
      end
    end

    it 'handles February correctly' do
      range = described_class.mes_range(2024, 2) # leap year

      expect(range.first).to eq(Date.new(2024, 2, 1))
      expect(range.last).to eq(Date.new(2024, 2, 29))
    end
  end

  describe '.ultimo_dia_disponivel' do
    it 'returns last day of month for past months' do
      travel_to Date.new(2026, 3, 15) do
        resultado = described_class.ultimo_dia_disponivel(2026, 1)

        expect(resultado).to eq(Date.new(2026, 1, 31))
      end
    end

    it 'returns current date for current month' do
      travel_to Date.new(2026, 3, 15) do
        resultado = described_class.ultimo_dia_disponivel(2026, 3)

        expect(resultado).to eq(Date.new(2026, 3, 15))
      end
    end

    it 'handles months with 30 days' do
      travel_to Date.new(2026, 5, 15) do
        resultado = described_class.ultimo_dia_disponivel(2026, 4)

        expect(resultado).to eq(Date.new(2026, 4, 30))
      end
    end
  end

  describe '.mes_atual?' do
    it 'returns true for current year and month' do
      travel_to Date.new(2026, 3, 15) do
        expect(described_class.mes_atual?(2026, 3)).to be true
      end
    end

    it 'returns false for past months' do
      travel_to Date.new(2026, 3, 15) do
        expect(described_class.mes_atual?(2026, 2)).to be false
      end
    end

    it 'returns false for future months' do
      travel_to Date.new(2026, 3, 15) do
        expect(described_class.mes_atual?(2026, 4)).to be false
      end
    end

    it 'returns false for different year' do
      travel_to Date.new(2026, 3, 15) do
        expect(described_class.mes_atual?(2025, 3)).to be false
      end
    end
  end

  describe '.ano_valido?' do
    it 'returns true for years within range' do
      travel_to Date.new(2026, 1, 1) do
        expect(described_class.ano_valido?(2020)).to be true
        expect(described_class.ano_valido?(2026)).to be true
        expect(described_class.ano_valido?(2027)).to be true
      end
    end

    it 'returns false for years before minimum' do
      expect(described_class.ano_valido?(2019)).to be false
    end

    it 'returns false for years too far in future' do
      travel_to Date.new(2026, 1, 1) do
        expect(described_class.ano_valido?(2028)).to be false
      end
    end

    it 'accepts custom minimum year' do
      expect(described_class.ano_valido?(2018, ano_minimo: 2015)).to be true
      expect(described_class.ano_valido?(2014, ano_minimo: 2015)).to be false
    end
  end

  describe '.mes_valido?' do
    it 'returns true for valid months' do
      expect(described_class.mes_valido?(1)).to be true
      expect(described_class.mes_valido?(12)).to be true
    end

    it 'returns false for invalid months' do
      expect(described_class.mes_valido?(0)).to be false
      expect(described_class.mes_valido?(13)).to be false
    end
  end

  describe '.data_valida?' do
    it 'returns true for past dates' do
      travel_to Date.new(2026, 3, 15) do
        expect(described_class.data_valida?(Date.new(2026, 1, 1))).to be true
      end
    end

    it 'returns true for current date' do
      travel_to Date.new(2026, 3, 15) do
        expect(described_class.data_valida?(Date.current)).to be true
      end
    end

    it 'returns false for future dates' do
      travel_to Date.new(2026, 3, 15) do
        expect(described_class.data_valida?(Date.new(2026, 4, 1))).to be false
      end
    end
  end

  describe '.meses_entre' do
    it 'calculates months between dates in same year' do
      inicio = Date.new(2026, 1, 1)
      fim = Date.new(2026, 3, 31)

      expect(described_class.meses_entre(inicio, fim)).to eq(3)
    end

    it 'calculates months between dates across years' do
      inicio = Date.new(2025, 10, 1)
      fim = Date.new(2026, 3, 31)

      expect(described_class.meses_entre(inicio, fim)).to eq(6)
    end

    it 'returns 1 for same month' do
      inicio = Date.new(2026, 3, 1)
      fim = Date.new(2026, 3, 31)

      expect(described_class.meses_entre(inicio, fim)).to eq(1)
    end

    it 'counts complete months only' do
      inicio = Date.new(2026, 1, 15)
      fim = Date.new(2026, 12, 31)

      expect(described_class.meses_entre(inicio, fim)).to eq(12)
    end
  end

  describe '.periodo_parcial_historico' do
    it 'returns range capped at dia_limite' do
      range = described_class.periodo_parcial_historico(2025, 3, 15)

      expect(range.first).to eq(Date.new(2025, 3, 1))
      expect(range.last).to eq(Date.new(2025, 3, 15))
    end

    it 'handles dia_limite greater than month days' do
      range = described_class.periodo_parcial_historico(2025, 2, 31)

      expect(range.first).to eq(Date.new(2025, 2, 1))
      expect(range.last).to eq(Date.new(2025, 2, 28))
    end

    it 'handles leap year February' do
      range = described_class.periodo_parcial_historico(2024, 2, 29)

      expect(range.first).to eq(Date.new(2024, 2, 1))
      expect(range.last).to eq(Date.new(2024, 2, 29))
    end

    it 'handles first day of month' do
      range = described_class.periodo_parcial_historico(2025, 3, 1)

      expect(range.first).to eq(Date.new(2025, 3, 1))
      expect(range.last).to eq(Date.new(2025, 3, 1))
    end
  end
end
