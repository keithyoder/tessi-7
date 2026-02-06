# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Faturamento::EstatisticasAno do
  let!(:pagamento_perfil) { any_pagamento_perfil }
  let!(:contrato) { create(:contrato, pagamento_perfil: pagamento_perfil) }

  describe '#call' do
    context 'com ano completo de dados' do
      before do
        travel_to Date.new(2026, 12, 31)

        # 2026 - dados atuais
        (1..12).each do |mes|
          create(:fatura,
                 contrato: contrato,
                 liquidacao: Date.new(2026, mes, 15),
                 valor_liquidacao: 100 * mes) # Janeiro: 100, Fevereiro: 200, etc.
        end

        # 2025, 2024, 2023 - histórico
        [2025, 2024, 2023].each do |ano|
          (1..12).each do |mes|
            create(:fatura,
                   contrato: contrato,
                   liquidacao: Date.new(ano, mes, 15),
                   valor_liquidacao: 80 * mes) # Valores menores que 2026
          end
        end
      end

      it 'retorna dados para todos os 12 meses' do
        resultado = described_class.new(ano: 2026).call
        meses = resultado[:meses]

        expect(meses.length).to eq(12)
        expect(meses.pluck(:mes)).to eq((1..12).to_a)
      end

      it 'calcula totais mensais corretamente' do
        resultado = described_class.new(ano: 2026).call
        meses = resultado[:meses]

        janeiro = meses.find { |m| m[:mes] == 1 }
        expect(janeiro[:total_recebido]).to eq(100.0)

        dezembro = meses.find { |m| m[:mes] == 12 }
        expect(dezembro[:total_recebido]).to eq(1200.0)
      end

      it 'calcula média histórica para cada mês' do
        resultado = described_class.new(ano: 2026).call
        meses = resultado[:meses]

        janeiro = meses.find { |m| m[:mes] == 1 }
        # Média de 2025, 2024, 2023 para janeiro: (80 + 80 + 80) / 3 = 80
        expect(janeiro[:total_esperado]).to eq(80.0)
      end

      it 'calcula diferença e percentual para cada mês' do
        resultado = described_class.new(ano: 2026).call
        meses = resultado[:meses]

        janeiro = meses.find { |m| m[:mes] == 1 }
        # Real: 100, Esperado: 80, Diferença: 20, Percentual: 25%
        expect(janeiro[:diferenca]).to eq(20.0)
        expect(janeiro[:percentual_diferenca]).to eq(25.0)
      end

      it 'retorna resumo do ano' do
        resultado = described_class.new(ano: 2026).call
        resumo = resultado[:resumo]

        # Total ano: 100+200+300+...+1200 = 7800
        expect(resumo[:total_recebido]).to eq(7800.0)
        expect(resumo[:total_faturas]).to eq(12)
        expect(resumo[:meses_processados]).to eq(12)
      end

      it 'calcula comparação com ano anterior' do
        resultado = described_class.new(ano: 2026).call
        ano_anterior = resultado[:ano_anterior]

        expect(ano_anterior[:ano]).to eq(2025)
        # Total 2025: 80+160+240+...+960 = 6240
        expect(ano_anterior[:total]).to eq(6240.0)
        # Diferença: 7800 - 6240 = 1560
        expect(ano_anterior[:diferenca]).to eq(1560.0)
        expect(ano_anterior[:percentual]).to eq(25.0)
      end
    end

    context 'com ano parcial (ano atual)' do
      before do
        travel_to Date.new(2026, 3, 15)

        # Janeiro e Fevereiro completos
        create(:fatura, contrato: contrato, liquidacao: Date.new(2026, 1, 10), valor_liquidacao: 100)
        create(:fatura, contrato: contrato, liquidacao: Date.new(2026, 2, 10), valor_liquidacao: 200)

        # Março parcial (até dia 15)
        create(:fatura, contrato: contrato, liquidacao: Date.new(2026, 3, 5), valor_liquidacao: 150)
        create(:fatura, contrato: contrato, liquidacao: Date.new(2026, 3, 10), valor_liquidacao: 150)

        # Histórico
        [2025, 2024, 2023].each do |ano|
          (1..12).each do |mes|
            create(:fatura, contrato: contrato, liquidacao: Date.new(ano, mes, 10), valor_liquidacao: 100)
          end
        end
      end

      it 'inclui apenas meses até o mês atual' do
        resultado = described_class.new(ano: 2026).call
        meses = resultado[:meses]

        expect(meses.length).to eq(3)
        expect(meses.pluck(:mes)).to eq([1, 2, 3])
      end

      it 'compara mês parcial com média histórica parcial' do
        resultado = described_class.new(ano: 2026).call
        meses = resultado[:meses]

        marco = meses.find { |m| m[:mes] == 3 }
        # Março atual tem faturas até dia 15
        # Média histórica deve ser calculada também até dia 15
        expect(marco[:total_esperado]).to be > 0
        expect(marco[:total_recebido]).to eq(300.0)
      end

      it 'calcula resumo apenas para meses processados' do
        resultado = described_class.new(ano: 2026).call
        resumo = resultado[:resumo]

        expect(resumo[:meses_processados]).to eq(3)
        # Janeiro: 100, Fevereiro: 200, Março: 300 = 600
        expect(resumo[:total_recebido]).to eq(600.0)
      end

      it 'calcula média mensal ponderada com projeção do mês parcial' do
        resultado = described_class.new(ano: 2026).call
        resumo = resultado[:resumo]

        # Média mensal deve projetar março completo
        # Janeiro: 100, Fevereiro: 200
        # Março parcial (300 em 15 dias) projeta para ~620 no mês completo
        # Média: (100 + 200 + 620) / 3 ≈ 306.67
        expect(resumo[:media_mensal]).to be > 250
        expect(resumo[:media_mensal]).to be < 400
      end
    end

    context 'sem dados históricos (primeiro ano)' do
      before do
        travel_to Date.new(2020, 12, 31)

        (1..12).each do |mes|
          create(:fatura,
                 contrato: contrato,
                 liquidacao: Date.new(2020, mes, 15),
                 valor_liquidacao: 100)
        end
      end

      it 'usa zero como média histórica' do
        resultado = described_class.new(ano: 2020).call
        meses = resultado[:meses]

        janeiro = meses.find { |m| m[:mes] == 1 }
        expect(janeiro[:total_esperado]).to eq(0.0)
      end

      it 'não retorna comparação com ano anterior' do
        resultado = described_class.new(ano: 2020).call

        expect(resultado[:ano_anterior]).to be_nil
      end
    end

    context 'sem faturas no ano' do
      before do
        travel_to Date.new(2026, 12, 31)
      end

      it 'retorna meses com valores zerados' do
        resultado = described_class.new(ano: 2026).call
        meses = resultado[:meses]

        # Returns all 12 months with zero values
        expect(meses).not_to be_empty
        expect(meses.length).to eq(12)

        # Each month should have zero values
        meses.each do |mes_data|
          expect(mes_data[:total_recebido]).to eq(0.0)
          expect(mes_data[:total_faturas]).to eq(0)
        end
      end

      it 'retorna resumo com zeros' do
        resultado = described_class.new(ano: 2026).call
        resumo = resultado[:resumo]

        expect(resumo[:total_recebido]).to eq(0.0)
        expect(resumo[:total_faturas]).to eq(0)
        # meses_processados still shows 12 (all months)
        expect(resumo[:meses_processados]).to eq(12)
        expect(resumo[:media_mensal]).to eq(0.0)
      end
    end

    context 'com múltiplas faturas no mesmo mês' do
      before do
        travel_to Date.new(2026, 12, 31)

        # 10 faturas em janeiro
        10.times do
          create(:fatura,
                 contrato: contrato,
                 liquidacao: Date.new(2026, 1, 15),
                 valor_liquidacao: 10)
        end
      end

      it 'soma todas as faturas do mês' do
        resultado = described_class.new(ano: 2026).call
        meses = resultado[:meses]

        janeiro = meses.find { |m| m[:mes] == 1 }
        expect(janeiro[:total_faturas]).to eq(10)
        expect(janeiro[:total_recebido]).to eq(100.0)
      end

      it 'calcula ticket médio corretamente' do
        resultado = described_class.new(ano: 2026).call
        meses = resultado[:meses]

        janeiro = meses.find { |m| m[:mes] == 1 }
        expect(janeiro[:ticket_medio]).to eq(10.0)
      end
    end

    context 'para comparação ano anterior com mês parcial' do
      before do
        travel_to Date.new(2026, 2, 15)

        # 2026: Janeiro completo, Fevereiro até dia 15
        create(:fatura, contrato: contrato, liquidacao: Date.new(2026, 1, 10), valor_liquidacao: 100)
        create(:fatura, contrato: contrato, liquidacao: Date.new(2026, 2, 5), valor_liquidacao: 50)
        create(:fatura, contrato: contrato, liquidacao: Date.new(2026, 2, 10), valor_liquidacao: 50)

        # 2025: dados completos para todos os meses
        (1..12).each do |mes|
          create(:fatura, contrato: contrato, liquidacao: Date.new(2025, mes, 10), valor_liquidacao: 80)
        end
      end

      it 'compara com período equivalente do ano anterior' do
        resultado = described_class.new(ano: 2026).call
        ano_anterior = resultado[:ano_anterior]

        expect(ano_anterior[:ano]).to eq(2025)
        # 2025 até 15 de Fevereiro: Janeiro completo (80) + Fevereiro parcial
        # Total deve ser próximo de 160-170 dependendo da projeção parcial
        expect(ano_anterior[:total]).to be > 80
        expect(ano_anterior[:total]).to be < 200
      end
    end

    context 'com performance consistentemente acima' do
      before do
        travel_to Date.new(2026, 6, 30)

        # 2026: valores altos
        (1..6).each do |mes|
          create(:fatura, contrato: contrato, liquidacao: Date.new(2026, mes, 15), valor_liquidacao: 200)
        end

        # Histórico: valores baixos
        [2025, 2024, 2023].each do |ano|
          (1..12).each do |mes|
            create(:fatura, contrato: contrato, liquidacao: Date.new(ano, mes, 15), valor_liquidacao: 50)
          end
        end
      end

      it 'mostra diferença positiva em todos os meses' do
        resultado = described_class.new(ano: 2026).call
        meses = resultado[:meses]

        meses.each do |mes_data|
          expect(mes_data[:diferenca]).to be > 0
          expect(mes_data[:percentual_diferenca]).to be > 0
        end
      end

      it 'mostra performance geral positiva no resumo' do
        resultado = described_class.new(ano: 2026).call
        resumo = resultado[:resumo]

        expect(resumo[:diferenca]).to be > 0
        expect(resumo[:percentual_diferenca]).to be > 0
        expect(resumo[:performance]).to eq(:acima)
      end
    end

    context 'com valores decimais' do
      before do
        travel_to Date.new(2026, 3, 31)

        create(:fatura, contrato: contrato, liquidacao: Date.new(2026, 1, 10), valor_liquidacao: 99.99)
        create(:fatura, contrato: contrato, liquidacao: Date.new(2026, 2, 10), valor_liquidacao: 150.50)
        create(:fatura, contrato: contrato, liquidacao: Date.new(2026, 3, 10), valor_liquidacao: 75.25)

        [2025, 2024, 2023].each do |ano|
          (1..12).each do |mes|
            create(:fatura, contrato: contrato, liquidacao: Date.new(ano, mes, 10), valor_liquidacao: 88.88)
          end
        end
      end

      it 'mantém precisão decimal nos cálculos' do
        resultado = described_class.new(ano: 2026).call
        resumo = resultado[:resumo]

        # Total: 99.99 + 150.50 + 75.25 = 325.74
        expect(resumo[:total_recebido]).to eq(325.74)
      end
    end

    context 'para edge case de fevereiro em ano bissexto' do
      before do
        travel_to Date.new(2024, 3, 1) # Day after Feb 29

        # Fevereiro 2024 (bissexto) - dia 29
        create(:fatura, contrato: contrato, liquidacao: Date.new(2024, 2, 29), valor_liquidacao: 100)

        # Fevereiro 2023 (não bissexto) - não tem dia 29
        create(:fatura, contrato: contrato, liquidacao: Date.new(2023, 2, 28), valor_liquidacao: 80)
      end

      it 'processa fevereiro de ano bissexto corretamente' do
        resultado = described_class.new(ano: 2024).call
        meses = resultado[:meses]

        fevereiro = meses.find { |m| m[:mes] == 2 }
        expect(fevereiro).to be_present
        # data_limite is Feb 29, so this should be included
        expect(fevereiro[:total_recebido]).to eq(100.0)
      end
    end

    context 'quando não há dados para meses específicos' do
      before do
        travel_to Date.new(2026, 12, 31)

        # Apenas janeiro e dezembro
        create(:fatura, contrato: contrato, liquidacao: Date.new(2026, 1, 10), valor_liquidacao: 100)
        create(:fatura, contrato: contrato, liquidacao: Date.new(2026, 12, 10), valor_liquidacao: 200)
      end

      it 'retorna todos os 12 meses, mas só 2 têm valores' do
        resultado = described_class.new(ano: 2026).call
        meses = resultado[:meses]

        # Returns all 12 months
        expect(meses.length).to eq(12)

        # Only Janeiro and Dezembro have values
        meses_com_dados = meses.select { |m| m[:total_recebido] > 0 }
        expect(meses_com_dados.length).to eq(2)
        expect(meses_com_dados.pluck(:mes)).to contain_exactly(1, 12)

        # Other months have zero
        fevereiro = meses.find { |m| m[:mes] == 2 }
        expect(fevereiro[:total_recebido]).to eq(0.0)
      end
    end
  end
end
