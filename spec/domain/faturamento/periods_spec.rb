# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Faturamento::Periods do
  describe '.ano_range' do
    it 'retorna range completo para anos passados' do
      range = described_class.ano_range(2023)

      expect(range.first).to eq(Date.new(2023, 1, 1))
      expect(range.last).to eq(Date.new(2023, 12, 31))
    end

    it 'limita até data_limite (ontem) para o ano atual' do
      travel_to Date.new(2026, 6, 15) do
        range = described_class.ano_range(2026)

        expect(range.first).to eq(Date.new(2026, 1, 1))
        expect(range.last).to eq(Date.new(2026, 6, 14)) # data_limite = yesterday
      end
    end

    it 'limita até data_limite (ontem) para anos futuros' do
      travel_to Date.new(2026, 3, 10) do
        range = described_class.ano_range(2027)

        expect(range.first).to eq(Date.new(2027, 1, 1))
        expect(range.last).to eq(Date.new(2026, 3, 9)) # data_limite = yesterday
      end
    end
  end

  describe '.mes_range' do
    it 'retorna range completo para meses passados' do
      travel_to Date.new(2026, 3, 15) do
        range = described_class.mes_range(2026, 1)

        expect(range.first).to eq(Date.new(2026, 1, 1))
        expect(range.last).to eq(Date.new(2026, 1, 31))
      end
    end

    it 'limita até data_limite (ontem) para o mês atual' do
      travel_to Date.new(2026, 3, 15) do
        range = described_class.mes_range(2026, 3)

        expect(range.first).to eq(Date.new(2026, 3, 1))
        expect(range.last).to eq(Date.new(2026, 3, 14)) # data_limite = yesterday
      end
    end

    it 'trata fevereiro corretamente' do
      range = described_class.mes_range(2024, 2) # leap year

      expect(range.first).to eq(Date.new(2024, 2, 1))
      expect(range.last).to eq(Date.new(2024, 2, 29))
    end
  end

  describe '.ultimo_dia_disponivel' do
    it 'retorna último dia do mês para meses passados' do
      travel_to Date.new(2026, 3, 15) do
        resultado = described_class.ultimo_dia_disponivel(2026, 1)

        expect(resultado).to eq(Date.new(2026, 1, 31))
      end
    end

    it 'retorna data_limite (ontem) para o mês atual' do
      travel_to Date.new(2026, 3, 15) do
        resultado = described_class.ultimo_dia_disponivel(2026, 3)

        expect(resultado).to eq(Date.new(2026, 3, 14)) # data_limite = yesterday
      end
    end

    it 'trata meses com 30 dias corretamente' do
      travel_to Date.new(2026, 5, 15) do
        resultado = described_class.ultimo_dia_disponivel(2026, 4)

        expect(resultado).to eq(Date.new(2026, 4, 30))
      end
    end
  end

  describe '.mes_atual?' do
    it 'retorna true para ano e mês atuais' do
      travel_to Date.new(2026, 3, 15) do
        expect(described_class.mes_atual?(2026, 3)).to be true
      end
    end

    it 'retorna false para meses passados' do
      travel_to Date.new(2026, 3, 15) do
        expect(described_class.mes_atual?(2026, 2)).to be false
      end
    end

    it 'retorna false para meses futuros' do
      travel_to Date.new(2026, 3, 15) do
        expect(described_class.mes_atual?(2026, 4)).to be false
      end
    end

    it 'retorna false para ano diferente' do
      travel_to Date.new(2026, 3, 15) do
        expect(described_class.mes_atual?(2025, 3)).to be false
      end
    end
  end

  describe '.ano_valido?' do
    it 'retorna true para anos dentro do range' do
      travel_to Date.new(2026, 1, 1) do
        expect(described_class.ano_valido?(2020)).to be true
        expect(described_class.ano_valido?(2026)).to be true
        expect(described_class.ano_valido?(2027)).to be true
      end
    end

    it 'retorna false para anos antes do mínimo' do
      expect(described_class.ano_valido?(2019)).to be false
    end

    it 'retorna false para anos muito distantes no futuro' do
      travel_to Date.new(2026, 1, 1) do
        expect(described_class.ano_valido?(2028)).to be false
      end
    end

    it 'aceita ano mínimo customizado' do
      expect(described_class.ano_valido?(2018, ano_minimo: 2015)).to be true
      expect(described_class.ano_valido?(2014, ano_minimo: 2015)).to be false
    end
  end

  describe '.mes_valido?' do
    it 'retorna true para meses válidos' do
      expect(described_class.mes_valido?(1)).to be true
      expect(described_class.mes_valido?(12)).to be true
    end

    it 'retorna false para meses inválidos' do
      expect(described_class.mes_valido?(0)).to be false
      expect(described_class.mes_valido?(13)).to be false
    end
  end

  describe '.data_valida?' do
    it 'retorna true para datas passadas' do
      travel_to Date.new(2026, 3, 15) do
        expect(described_class.data_valida?(Date.new(2026, 1, 1))).to be true
      end
    end

    it 'retorna true para data_limite (ontem)' do
      travel_to Date.new(2026, 3, 15) do
        expect(described_class.data_valida?(Date.yesterday)).to be true
      end
    end

    it 'retorna false para hoje (dados ainda incompletos)' do
      travel_to Date.new(2026, 3, 15) do
        expect(described_class.data_valida?(Date.current)).to be false
      end
    end

    it 'retorna false para datas futuras' do
      travel_to Date.new(2026, 3, 15) do
        expect(described_class.data_valida?(Date.new(2026, 4, 1))).to be false
      end
    end
  end

  describe '.meses_entre' do
    it 'calcula meses entre datas no mesmo ano' do
      inicio = Date.new(2026, 1, 1)
      fim = Date.new(2026, 3, 31)

      expect(described_class.meses_entre(inicio, fim)).to eq(3)
    end

    it 'calcula meses entre datas de anos diferentes' do
      inicio = Date.new(2025, 10, 1)
      fim = Date.new(2026, 3, 31)

      expect(described_class.meses_entre(inicio, fim)).to eq(6)
    end

    it 'retorna 1 para o mesmo mês' do
      inicio = Date.new(2026, 3, 1)
      fim = Date.new(2026, 3, 31)

      expect(described_class.meses_entre(inicio, fim)).to eq(1)
    end

    it 'conta apenas meses completos' do
      inicio = Date.new(2026, 1, 15)
      fim = Date.new(2026, 12, 31)

      expect(described_class.meses_entre(inicio, fim)).to eq(12)
    end
  end

  describe '.periodo_parcial_historico' do
    it 'retorna range limitado até dia_limite' do
      range = described_class.periodo_parcial_historico(2025, 3, 15)

      expect(range.first).to eq(Date.new(2025, 3, 1))
      expect(range.last).to eq(Date.new(2025, 3, 15))
    end

    it 'trata dia_limite maior que dias no mês' do
      range = described_class.periodo_parcial_historico(2025, 2, 31)

      expect(range.first).to eq(Date.new(2025, 2, 1))
      expect(range.last).to eq(Date.new(2025, 2, 28))
    end

    it 'trata fevereiro de ano bissexto' do
      range = described_class.periodo_parcial_historico(2024, 2, 29)

      expect(range.first).to eq(Date.new(2024, 2, 1))
      expect(range.last).to eq(Date.new(2024, 2, 29))
    end

    it 'trata primeiro dia do mês' do
      range = described_class.periodo_parcial_historico(2025, 3, 1)

      expect(range.first).to eq(Date.new(2025, 3, 1))
      expect(range.last).to eq(Date.new(2025, 3, 1))
    end
  end
end
