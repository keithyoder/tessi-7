# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Faturamento::Queries do
  let!(:contrato_pf) do
    create(:contrato, pessoa: create(:pessoa, :fisica))
  end

  let!(:contrato_pj) do
    create(:contrato, pessoa: create(:pessoa, :juridica))
  end

  describe '.faturamento_por_dia' do
    context 'com faturas em múltiplos dias' do
      before do
        create(:fatura,
               contrato: contrato_pf,
               liquidacao: Date.new(2026, 1, 1),
               valor_liquidacao: 100.00)

        create(:fatura,
               contrato: contrato_pf,
               liquidacao: Date.new(2026, 1, 5),
               valor_liquidacao: 150.00)

        create(:fatura,
               contrato: contrato_pj,
               liquidacao: Date.new(2026, 1, 5),
               valor_liquidacao: 50.00)
      end

      it 'agrupa por dia corretamente' do
        resultado = described_class.faturamento_por_dia(
          Date.new(2026, 1, 1),
          Date.new(2026, 1, 31)
        )

        expect(resultado[1].quantidade).to eq(1)
        expect(resultado[1].total).to eq(100.00)

        expect(resultado[5].quantidade).to eq(2)
        expect(resultado[5].total).to eq(200.00)
      end

      it 'não inclui dias fora do período' do
        resultado = described_class.faturamento_por_dia(
          Date.new(2026, 1, 2),
          Date.new(2026, 1, 4)
        )

        expect(resultado[1]).to be_nil
        expect(resultado[5]).to be_nil
      end

      it 'retorna hash vazio quando não há dados' do
        resultado = described_class.faturamento_por_dia(
          Date.new(2026, 2, 1),
          Date.new(2026, 2, 28)
        )

        expect(resultado).to be_empty
      end
    end

    context 'com período de um dia' do
      before do
        create(:fatura,
               contrato: contrato_pf,
               liquidacao: Date.new(2026, 1, 15),
               valor_liquidacao: 75.00)
      end

      it 'retorna dados corretos' do
        resultado = described_class.faturamento_por_dia(
          Date.new(2026, 1, 15),
          Date.new(2026, 1, 15)
        )

        expect(resultado[15].quantidade).to eq(1)
        expect(resultado[15].total).to eq(75.00)
      end
    end
  end

  describe '.faturamento_por_mes' do
    context 'com faturas em múltiplos meses' do
      before do
        create(:fatura,
               contrato: contrato_pf,
               liquidacao: Date.new(2026, 1, 15),
               valor_liquidacao: 100.00)

        create(:fatura,
               contrato: contrato_pj,
               liquidacao: Date.new(2026, 1, 20),
               valor_liquidacao: 150.00)

        create(:fatura,
               contrato: contrato_pf,
               liquidacao: Date.new(2026, 2, 10),
               valor_liquidacao: 200.00)
      end

      it 'agrupa por mês corretamente' do
        resultado = described_class.faturamento_por_mes(
          Date.new(2026, 1, 1),
          Date.new(2026, 12, 31)
        )

        expect(resultado[1].quantidade).to eq(2)
        expect(resultado[1].total).to eq(250.00)

        expect(resultado[2].quantidade).to eq(1)
        expect(resultado[2].total).to eq(200.00)
      end

      it 'respeita o período especificado' do
        resultado = described_class.faturamento_por_mes(
          Date.new(2026, 1, 1),
          Date.new(2026, 1, 31)
        )

        expect(resultado[1]).to be_present
        expect(resultado[2]).to be_nil
      end
    end
  end

  describe '.faturamento_total' do
    context 'com múltiplas faturas' do
      before do
        travel_to Date.new(2026, 1, 10)
        create(:fatura,
               contrato: contrato_pf,
               vencimento: Date.new(2026, 1, 10),
               liquidacao: Date.new(2026, 1, 10),
               valor_liquidacao: 100.00)
        create(:fatura,
               contrato: contrato_pj,
               vencimento: Date.new(2026, 1, 15),
               liquidacao: Date.new(2026, 1, 15),
               valor_liquidacao: 150.00)
      end

      it 'retorna quantidade e total corretos' do
        resultado = described_class.faturamento_total(
          Date.new(2026, 1, 1),
          Date.new(2026, 1, 31)
        )

        expect(resultado[:quantidade]).to eq(2)
        expect(resultado[:total]).to eq(250.00)
      end
    end

    context 'sem faturas no período' do
      it 'retorna zeros' do
        resultado = described_class.faturamento_total(
          Date.new(2026, 2, 1),
          Date.new(2026, 2, 28)
        )

        expect(resultado[:quantidade]).to eq(0)
        expect(resultado[:total]).to eq(0.0)
      end
    end

    context 'com período de um dia' do
      before do
        create(:fatura,
               contrato: contrato_pf,
               liquidacao: Date.new(2026, 1, 15),
               valor_liquidacao: 75.00)
      end

      it 'retorna dados corretos' do
        resultado = described_class.faturamento_total(
          Date.new(2026, 1, 15),
          Date.new(2026, 1, 15)
        )

        expect(resultado[:quantidade]).to eq(1)
        expect(resultado[:total]).to eq(75.00)
      end
    end
  end

  describe '.faturamento_por_meio' do
    before do
      travel_to Date.new(2026, 1, 10)
      create(:fatura,
             contrato: contrato_pf,
             vencimento: Date.new(2026, 1, 10),
             liquidacao: Date.new(2026, 1, 10),
             valor_liquidacao: 100.00,
             meio_liquidacao: :Dinheiro)

      create(:fatura,
             contrato: contrato_pj,
             vencimento: Date.new(2026, 1, 15),
             liquidacao: Date.new(2026, 1, 15),
             valor_liquidacao: 200.00,
             meio_liquidacao: :CartaoCredito)

      create(:fatura,
             contrato: contrato_pf,
             vencimento: Date.new(2026, 1, 20),
             liquidacao: Date.new(2026, 1, 20),
             valor_liquidacao: 150.00,
             meio_liquidacao: :RetornoBancario)
    end

    it 'agrupa por meio de liquidação' do
      resultado = described_class.faturamento_por_meio(
        Date.new(2026, 1, 1),
        Date.new(2026, 1, 31)
      )
      expect(resultado['Dinheiro']).to eq(100.00)
      expect(resultado['CartaoCredito']).to eq(200.00)
      expect(resultado['RetornoBancario']).to eq(150.00)
    end

    it 'não inclui meios sem faturas' do
      resultado = described_class.faturamento_por_meio(
        Date.new(2026, 1, 1),
        Date.new(2026, 1, 31)
      )

      expect(resultado.key?('Cheque')).to be false
    end

    it 'retorna hash vazio quando não há dados' do
      resultado = described_class.faturamento_por_meio(
        Date.new(2026, 2, 1),
        Date.new(2026, 2, 28)
      )

      expect(resultado).to be_empty
    end
  end

  describe '.faturamento_historico_por_ano_mes' do
    before do
      create(:fatura,
             contrato: contrato_pf,
             liquidacao: Date.new(2024, 1, 15),
             valor_liquidacao: 100.00)

      create(:fatura,
             contrato: contrato_pf,
             liquidacao: Date.new(2024, 2, 10),
             valor_liquidacao: 150.00)

      create(:fatura,
             contrato: contrato_pj,
             liquidacao: Date.new(2025, 1, 20),
             valor_liquidacao: 200.00)
    end

    it 'retorna dados agrupados por ano e mês' do
      resultado = described_class.faturamento_historico_por_ano_mes([2024, 2025])

      expect(resultado[2024][1]).to eq(100.00)
      expect(resultado[2024][2]).to eq(150.00)
      expect(resultado[2025][1]).to eq(200.00)
    end

    it 'retorna hash vazio para anos sem dados' do
      resultado = described_class.faturamento_historico_por_ano_mes([2020])

      expect(resultado).to be_empty
    end

    it 'retorna hash vazio para lista vazia de anos' do
      resultado = described_class.faturamento_historico_por_ano_mes([])

      expect(resultado).to be_empty
    end

    it 'não inclui meses sem faturas' do
      resultado = described_class.faturamento_historico_por_ano_mes([2024])

      expect(resultado[2024][3]).to be_nil
      expect(resultado[2025]).to be_nil
    end
  end

  describe '.faturamento_por_tipo_pessoa' do
    before do
      create(:fatura,
             contrato: contrato_pf,
             liquidacao: Date.new(2026, 1, 10))

      create(:fatura,
             contrato: contrato_pf,
             liquidacao: Date.new(2026, 1, 15))

      create(:fatura,
             contrato: contrato_pj,
             liquidacao: Date.new(2026, 1, 20))
    end

    it 'agrupa por tipo de pessoa' do
      resultado = described_class.faturamento_por_tipo_pessoa(
        Date.new(2026, 1, 1),
        Date.new(2026, 1, 31)
      )

      expect(resultado['Pessoa Física']).to eq(2)
      expect(resultado['Pessoa Jurídica']).to eq(1)
    end

    it 'retorna hash vazio quando não há dados' do
      resultado = described_class.faturamento_por_tipo_pessoa(
        Date.new(2026, 2, 1),
        Date.new(2026, 2, 28)
      )

      expect(resultado).to be_empty
    end
  end

  describe '.faturamento_por_perfil' do
    let(:perfil_boleto) { create(:pagamento_perfil, nome: 'Boleto Banco do Brasil') }
    let(:perfil_pix) { create(:pagamento_perfil, nome: 'PIX Gerencianet') }

    let!(:contrato_boleto) do
      create(:contrato, pessoa: create(:pessoa, :fisica), pagamento_perfil: perfil_boleto)
    end

    let!(:contrato_pix) do
      create(:contrato, pessoa: create(:pessoa, :juridica), pagamento_perfil: perfil_pix)
    end

    before do
      create(:fatura,
             contrato: contrato_boleto,
             pagamento_perfil: perfil_boleto,
             liquidacao: Date.new(2026, 1, 10),
             valor_liquidacao: 100.00)

      create(:fatura,
             contrato: contrato_pix,
             pagamento_perfil: perfil_pix,
             liquidacao: Date.new(2026, 1, 15),
             valor_liquidacao: 200.00)
    end

    it 'agrupa por perfil de pagamento' do
      resultado = described_class.faturamento_por_perfil(
        Date.new(2026, 1, 1),
        Date.new(2026, 1, 31)
      )

      expect(resultado['Boleto Banco do Brasil']).to eq(100.00)
      expect(resultado['PIX Gerencianet']).to eq(200.00)
    end

    it 'retorna hash vazio quando não há dados' do
      resultado = described_class.faturamento_por_perfil(
        Date.new(2026, 2, 1),
        Date.new(2026, 2, 28)
      )

      expect(resultado).to be_empty
    end
  end
end
