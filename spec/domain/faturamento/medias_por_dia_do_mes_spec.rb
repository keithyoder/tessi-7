# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Faturamento::MediasPorDiaDoMes do
  let!(:pagamento_perfil) { any_pagamento_perfil }
  let!(:contrato) { create(:contrato, pagamento_perfil: pagamento_perfil) }

  describe '#call' do
    context 'com dados históricos de múltiplos meses' do
      before do
        travel_to Date.new(2026, 3, 1)

        # Janeiro 2026 - dia 1
        create(:fatura, contrato: contrato, liquidacao: Date.new(2026, 1, 1), valor_liquidacao: 100)
        # Janeiro 2026 - dia 15
        create(:fatura, contrato: contrato, liquidacao: Date.new(2026, 1, 15), valor_liquidacao: 150)

        # Fevereiro 2026 - dia 1
        create(:fatura, contrato: contrato, liquidacao: Date.new(2026, 2, 1), valor_liquidacao: 200)
        # Fevereiro 2026 - dia 15
        create(:fatura, contrato: contrato, liquidacao: Date.new(2026, 2, 15), valor_liquidacao: 250)
      end

      it 'calcula média dividindo pelo total de meses' do
        # meses_atras: 2 significa Jan e Fev (2 meses completos)
        medias = described_class.new(meses_atras: 2, excluir_mes_atual: true).call

        # Dia 1: (100 + 200) / 2 = 150
        expect(medias[1]).to eq(150.0)

        # Dia 15: (150 + 250) / 2 = 200
        expect(medias[15]).to eq(200.0)
      end

      it 'não retorna médias para dias sem dados' do
        medias = described_class.new(meses_atras: 2, excluir_mes_atual: true).call

        expect(medias[10]).to be_nil
        expect(medias[31]).to be_nil
      end
    end

    context 'com dia 31 (não existe em todos os meses)' do
      before do
        travel_to Date.new(2026, 5, 1)

        # Janeiro tem dia 31
        create(:fatura, contrato: contrato, liquidacao: Date.new(2026, 1, 31), valor_liquidacao: 100)
        # Fevereiro não tem dia 31
        # Março tem dia 31
        create(:fatura, contrato: contrato, liquidacao: Date.new(2026, 3, 31), valor_liquidacao: 200)
        # Abril não tem dia 31
      end

      it 'divide pelo total de meses, não apenas meses que têm esse dia' do
        # 4 meses históricos: Jan, Fev, Mar, Abr
        # Dia 31 soma: 100 + 0 + 200 + 0 = 300
        # Média: 300 / 4 = 75 (não 300 / 2 = 150)
        medias = described_class.new(meses_atras: 4, excluir_mes_atual: true).call

        expect(medias[31]).to eq(75.0)
      end
    end

    context 'quando excluir_mes_atual é true' do
      before do
        travel_to Date.new(2026, 3, 15)

        # Fevereiro
        create(:fatura, contrato: contrato, liquidacao: Date.new(2026, 2, 10), valor_liquidacao: 100)
        # Março (mês atual)
        create(:fatura, contrato: contrato, liquidacao: Date.new(2026, 3, 10), valor_liquidacao: 200)
      end

      it 'não inclui dados do mês atual' do
        medias = described_class.new(meses_atras: 2, excluir_mes_atual: true).call

        # Período: Jan e Fev (2 meses)
        # Apenas Fevereiro tem dados: 100
        # Média: 100 / 2 meses = 50
        expect(medias[10]).to eq(50.0)
      end
    end

    context 'quando excluir_mes_atual é false' do
      before do
        travel_to Date.new(2026, 3, 15)

        # Fevereiro
        create(:fatura, contrato: contrato, liquidacao: Date.new(2026, 2, 10), valor_liquidacao: 100)
        # Março (mês atual)
        create(:fatura, contrato: contrato, liquidacao: Date.new(2026, 3, 10), valor_liquidacao: 200)
      end

      it 'inclui dados do mês atual' do
        medias = described_class.new(meses_atras: 2, excluir_mes_atual: false).call

        # Deve considerar Fev + Mar: (100 + 200) / 2
        expect(medias[10]).to eq(150.0)
      end
    end

    context 'sem dados históricos' do
      it 'retorna hash vazio' do
        travel_to Date.new(2026, 3, 1)

        medias = described_class.new(meses_atras: 2, excluir_mes_atual: true).call

        expect(medias).to eq({})

        travel_back
      end
    end

    context 'com período inválido' do
      it 'retorna hash vazio quando data_inicio >= data_fim' do
        travel_to Date.new(2020, 1, 1)

        # Com meses_atras muito grande, pode criar período inválido
        medias = described_class.new(meses_atras: 100, excluir_mes_atual: true).call

        expect(medias).to eq({})

        travel_back
      end
    end

    context 'com múltiplas faturas no mesmo dia' do
      before do
        travel_to Date.new(2026, 3, 1)

        # Três faturas no dia 15 de Janeiro
        create(:fatura, contrato: contrato, liquidacao: Date.new(2026, 1, 15), valor_liquidacao: 100)
        create(:fatura, contrato: contrato, liquidacao: Date.new(2026, 1, 15), valor_liquidacao: 150)
        create(:fatura, contrato: contrato, liquidacao: Date.new(2026, 1, 15), valor_liquidacao: 50)

        # Duas faturas no dia 15 de Fevereiro
        create(:fatura, contrato: contrato, liquidacao: Date.new(2026, 2, 15), valor_liquidacao: 200)
        create(:fatura, contrato: contrato, liquidacao: Date.new(2026, 2, 15), valor_liquidacao: 100)
      end

      it 'soma todas as faturas do mesmo dia' do
        medias = described_class.new(meses_atras: 2, excluir_mes_atual: true).call

        # Dia 15: (100 + 150 + 50 + 200 + 100) / 2 meses = 300
        expect(medias[15]).to eq(300.0)
      end
    end

    context 'com valores decimais' do
      before do
        travel_to Date.new(2026, 3, 1)

        create(:fatura, contrato: contrato, liquidacao: Date.new(2026, 1, 10), valor_liquidacao: 99.99)
        create(:fatura, contrato: contrato, liquidacao: Date.new(2026, 2, 10), valor_liquidacao: 150.50)
      end

      it 'mantém precisão decimal' do
        medias = described_class.new(meses_atras: 2, excluir_mes_atual: true).call

        # (99.99 + 150.50) / 2 = 125.245
        expect(medias[10]).to eq(125.245)
      end
    end
  end
end
