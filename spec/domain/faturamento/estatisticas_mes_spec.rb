# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Faturamento::EstatisticasMes do
  let!(:pagamento_perfil) { any_pagamento_perfil }
  let!(:contrato) { create(:contrato, pagamento_perfil: pagamento_perfil) }

  describe '#call' do
    context 'com faturas distribuídas ao longo do mês' do
      before do
        travel_to Date.new(2026, 1, 31)

        # Dia 5
        create(:fatura, contrato: contrato, liquidacao: Date.new(2026, 1, 5), valor_liquidacao: 100)
        # Dia 10
        create(:fatura, contrato: contrato, liquidacao: Date.new(2026, 1, 10), valor_liquidacao: 150)
        create(:fatura, contrato: contrato, liquidacao: Date.new(2026, 1, 10), valor_liquidacao: 50)
        # Dia 20
        create(:fatura, contrato: contrato, liquidacao: Date.new(2026, 1, 20), valor_liquidacao: 200)

        # Dados históricos para médias (últimos 12 meses)
        12.times do |i|
          mes = 12 - i
          create(:fatura, contrato: contrato, liquidacao: Date.new(2025, mes, 5), valor_liquidacao: 50)
          create(:fatura, contrato: contrato, liquidacao: Date.new(2025, mes, 10), valor_liquidacao: 75)
          create(:fatura, contrato: contrato, liquidacao: Date.new(2025, mes, 20), valor_liquidacao: 100)
        end
      end

      it 'calcula totais acumulados corretamente' do
        resultado = described_class.new(ano: 2026, mes: 1).call
        dias = resultado[:dias]

        dia_5 = dias.find { |d| d[:dia] == 5 }
        expect(dia_5[:acumulado_real]).to eq(100.0)

        dia_10 = dias.find { |d| d[:dia] == 10 }
        expect(dia_10[:acumulado_real]).to eq(300.0) # 100 + 150 + 50

        dia_20 = dias.find { |d| d[:dia] == 20 }
        expect(dia_20[:acumulado_real]).to eq(500.0) # 300 + 200
      end

      it 'calcula totais esperados com base em médias históricas' do
        resultado = described_class.new(ano: 2026, mes: 1).call
        dias = resultado[:dias]

        dia_5 = dias.find { |d| d[:dia] == 5 }
        # Média histórica dia 5: 50 * 12 / 13 meses = ~46.15
        expect(dia_5[:acumulado_esperado]).to be_within(1).of(46)

        dia_10 = dias.find { |d| d[:dia] == 10 }
        # Acumulado até dia 10: média_dia_5 + média_dia_10
        expect(dia_10[:acumulado_esperado]).to be > dia_5[:acumulado_esperado]
      end

      it 'calcula diferença entre real e esperado' do
        resultado = described_class.new(ano: 2026, mes: 1).call
        dias = resultado[:dias]

        dia_10 = dias.find { |d| d[:dia] == 10 }
        diferenca = dia_10[:acumulado_real] - dia_10[:acumulado_esperado]

        expect(dia_10[:diferenca]).to eq(diferenca)
        expect(dia_10[:diferenca_percentual]).to be_a(Float)
      end

      it 'identifica performance acima quando real > esperado' do
        resultado = described_class.new(ano: 2026, mes: 1).call
        dias = resultado[:dias]

        # Com valores do setup, real deve estar acima do esperado
        dia_10 = dias.find { |d| d[:dia] == 10 }
        expect(dia_10[:performance]).to eq(:acima)
      end

      it 'retorna resumo do mês completo' do
        resultado = described_class.new(ano: 2026, mes: 1).call
        resumo = resultado[:resumo]

        expect(resumo[:total_recebido]).to eq(500.0)
        expect(resumo[:total_faturas]).to eq(4)
        expect(resumo[:ticket_medio]).to eq(125.0) # 500 / 4
        expect(resumo[:dias_decorridos]).to eq(31)
      end
    end

    context 'para mês parcial (mês atual)' do
      before do
        travel_to Date.new(2026, 1, 15)

        # Faturas até o dia 15
        create(:fatura, contrato: contrato, liquidacao: Date.new(2026, 1, 5), valor_liquidacao: 100)
        create(:fatura, contrato: contrato, liquidacao: Date.new(2026, 1, 10), valor_liquidacao: 150)
        create(:fatura, contrato: contrato, liquidacao: Date.new(2026, 1, 15), valor_liquidacao: 200)

        # Dados históricos
        12.times do |i|
          mes = 12 - i
          (1..31).each do |dia|
            next unless Date.valid_date?(2025, mes, dia)

            create(:fatura, contrato: contrato, liquidacao: Date.new(2025, mes, dia), valor_liquidacao: 10)
          end
        end
      end

      it 'inclui apenas dias até hoje' do
        resultado = described_class.new(ano: 2026, mes: 1).call
        dias = resultado[:dias]

        expect(dias.length).to eq(15)
        expect(dias.last[:dia]).to eq(15)
      end

      it 'calcula projeção para o mês completo' do
        resultado = described_class.new(ano: 2026, mes: 1).call
        projecao = resultado[:projecao]

        # Projeção = acumulado até hoje + médias dos dias restantes
        # Real até dia 15: 450, mais projeção para dias 16-31
        expect(projecao).to be > 300.0 # At least the acumulado atual
        expect(projecao).to be < 600.0 # Reasonable upper bound
        expect(projecao).to be_a(Numeric)
      end

      it 'usa dias_decorridos correto no resumo' do
        resultado = described_class.new(ano: 2026, mes: 1).call
        resumo = resultado[:resumo]

        expect(resumo[:dias_decorridos]).to eq(15)
      end
    end

    context 'quando mês está no futuro' do
      before do
        travel_to Date.new(2026, 1, 15)
      end

      it 'não retorna nenhum dia (período vazio)' do
        resultado = described_class.new(ano: 2026, mes: 3).call
        dias = resultado[:dias]

        # Mês futuro não tem dias disponíveis
        expect(dias).to be_empty
      end
    end

    context 'sem dados históricos' do
      before do
        travel_to Date.new(2026, 1, 31)

        create(:fatura, contrato: contrato, liquidacao: Date.new(2026, 1, 10), valor_liquidacao: 100)
      end

      it 'usa zero como média histórica' do
        resultado = described_class.new(ano: 2026, mes: 1).call
        dias = resultado[:dias]

        dia_10 = dias.find { |d| d[:dia] == 10 }
        expect(dia_10[:acumulado_esperado]).to eq(0.0)
      end

      it 'retorna médias históricas vazias' do
        resultado = described_class.new(ano: 2026, mes: 1).call

        expect(resultado[:medias_historicas]).to eq({})
      end
    end

    context 'sem faturas no mês' do
      before do
        travel_to Date.new(2026, 1, 31)
      end

      it 'retorna resumo com zeros' do
        resultado = described_class.new(ano: 2026, mes: 1).call
        resumo = resultado[:resumo]

        expect(resumo[:total_recebido]).to eq(0.0)
        expect(resumo[:total_faturas]).to eq(0)
        # dias_decorridos still shows 31 (all days of January)
        expect(resumo[:dias_decorridos]).to eq(31)
      end

      it 'retorna dias com valores zerados' do
        resultado = described_class.new(ano: 2026, mes: 1).call
        dias = resultado[:dias]

        # Returns all 31 days with zero values
        expect(dias).not_to be_empty
        expect(dias.length).to eq(31)

        # First day should have zero values
        expect(dias.first[:faturamento_dia]).to eq(0.0)
        expect(dias.first[:faturas_count]).to eq(0)
      end
    end

    context 'com performance abaixo do esperado' do
      before do
        travel_to Date.new(2026, 1, 31)

        # Valor baixo no mês atual
        create(:fatura, contrato: contrato, liquidacao: Date.new(2026, 1, 10), valor_liquidacao: 10)

        # Histórico forte
        12.times do |i|
          mes = 12 - i
          (1..31).each do |dia|
            next unless Date.valid_date?(2025, mes, dia)

            create(:fatura, contrato: contrato, liquidacao: Date.new(2025, mes, dia), valor_liquidacao: 50)
          end
        end
      end

      it 'identifica performance abaixo' do
        resultado = described_class.new(ano: 2026, mes: 1).call
        dias = resultado[:dias]

        dia_10 = dias.find { |d| d[:dia] == 10 }
        expect(dia_10[:performance]).to eq(:abaixo)
        expect(dia_10[:diferenca]).to be < 0
        expect(dia_10[:diferenca_percentual]).to be < 0
      end
    end

    context 'com múltiplas faturas no mesmo dia' do
      before do
        travel_to Date.new(2026, 1, 31)

        # 5 faturas no dia 10
        5.times do
          create(:fatura, contrato: contrato, liquidacao: Date.new(2026, 1, 10), valor_liquidacao: 20)
        end
      end

      it 'soma todas as faturas do dia' do
        resultado = described_class.new(ano: 2026, mes: 1).call
        dias = resultado[:dias]

        dia_10 = dias.find { |d| d[:dia] == 10 }
        expect(dia_10[:faturas_count]).to eq(5)
        expect(dia_10[:faturamento_dia]).to eq(100.0)
      end

      it 'acumula corretamente no total do mês' do
        resultado = described_class.new(ano: 2026, mes: 1).call
        resumo = resultado[:resumo]

        expect(resumo[:total_faturas]).to eq(5)
        expect(resumo[:total_recebido]).to eq(100.0)
      end
    end

    context 'para projeção com dias restantes' do
      before do
        travel_to Date.new(2026, 2, 10) # Fevereiro tem 28 dias

        # Faturas até dia 10
        create(:fatura, contrato: contrato, liquidacao: Date.new(2026, 2, 5), valor_liquidacao: 100)
        create(:fatura, contrato: contrato, liquidacao: Date.new(2026, 2, 10), valor_liquidacao: 150)

        # Histórico: cada dia vale 10
        12.times do |i|
          mes = i + 1
          (1..28).each do |dia|
            next unless Date.valid_date?(2025, mes, dia)

            create(:fatura, contrato: contrato, liquidacao: Date.new(2025, mes, dia), valor_liquidacao: 10)
          end
        end
      end

      it 'adiciona médias históricas para dias restantes na projeção' do
        resultado = described_class.new(ano: 2026, mes: 2).call

        # Acumulado até dia 10: 250
        # Dias restantes (11-28): 18 dias
        # Média histórica por dia: ~10 (após divisão por 13 meses)
        # Projeção: 250 + (18 * média_dia)

        expect(resultado[:projecao]).to be > 250.0
        expect(resultado[:projecao]).to be < 450.0
      end
    end

    context 'com valores decimais' do
      before do
        travel_to Date.new(2026, 1, 15)

        create(:fatura, contrato: contrato, liquidacao: Date.new(2026, 1, 5), valor_liquidacao: 99.99)
        create(:fatura, contrato: contrato, liquidacao: Date.new(2026, 1, 10), valor_liquidacao: 150.50)
      end

      it 'mantém precisão decimal nos cálculos' do
        resultado = described_class.new(ano: 2026, mes: 1).call
        dias = resultado[:dias]

        dia_10 = dias.find { |d| d[:dia] == 10 }
        expect(dia_10[:acumulado_real]).to eq(250.49)
      end
    end
  end
end
