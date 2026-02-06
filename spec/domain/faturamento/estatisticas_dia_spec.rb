# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Faturamento::EstatisticasDia do
  let!(:pagamento_perfil) { any_pagamento_perfil }
  let!(:pessoa_fisica) { any_pessoa_fisica }
  let!(:pessoa_juridica) { create(:pessoa, :juridica) }
  let!(:contrato_pf) { create(:contrato, pessoa: pessoa_fisica, pagamento_perfil: pagamento_perfil) }
  let!(:contrato_pj) { create(:contrato, pessoa: pessoa_juridica, pagamento_perfil: pagamento_perfil) }

  describe '#call' do
    let(:data) { Date.new(2026, 3, 15) }

    context 'com faturas no dia' do
      before do
        travel_to Date.new(2026, 3, 16) # Dia seguinte

        # Faturas do dia em questão
        create(:fatura,
               contrato: contrato_pf,
               liquidacao: data,
               valor_liquidacao: 100.00,
               meio_liquidacao: :Dinheiro)

        create(:fatura,
               contrato: contrato_pj,
               liquidacao: data,
               valor_liquidacao: 200.00,
               meio_liquidacao: :CartaoCredito)

        # Dados históricos para comparação (dia 15 de meses anteriores)
        # Período histórico: 01/03/2025 até 28/02/2026 (12 meses excluindo março/2026)
        create(:fatura, contrato: contrato_pf, liquidacao: Date.new(2025, 3, 15), valor_liquidacao: 150)
        create(:fatura, contrato: contrato_pf, liquidacao: Date.new(2025, 4, 15), valor_liquidacao: 150)
      end

      it 'retorna resumo com dados corretos' do
        resultado = described_class.new(data: data).call

        expect(resultado[:resumo][:data]).to eq(data)
        expect(resultado[:resumo][:total_faturas]).to eq(2)
        expect(resultado[:resumo][:total_recebido]).to eq(300.00)
        expect(resultado[:resumo][:ticket_medio]).to eq(150.00)
      end

      it 'inclui breakdown por meio de liquidação' do
        resultado = described_class.new(data: data).call

        por_meio = resultado[:resumo][:por_meio]
        expect(por_meio['Dinheiro']).to eq(100.00)
        expect(por_meio['CartaoCredito']).to eq(200.00)
      end

      it 'calcula comparação com média histórica' do
        resultado = described_class.new(data: data).call
        comparacao = resultado[:comparacao]

        # Média histórica para dia 15: (150 + 150) / 12 meses = 25.0
        expect(comparacao[:media_historica]).to eq(25.0)
        expect(comparacao[:diferenca]).to eq(275.0)
        expect(comparacao[:percentual]).to be > 0
        expect(comparacao[:performance]).to eq(:acima)
      end

      it 'inclui detalhamento por tipo de pessoa' do
        resultado = described_class.new(data: data).call
        detalhamento = resultado[:detalhamento]

        expect(detalhamento[:por_tipo_pessoa]['Pessoa Física']).to eq(1)
        expect(detalhamento[:por_tipo_pessoa]['Pessoa Jurídica']).to eq(1)
      end

      it 'inclui navegação com dias anterior e seguinte' do
        resultado = described_class.new(data: data).call
        navegacao = resultado[:navegacao]

        expect(navegacao[:dia_anterior]).to eq(Date.new(2026, 3, 14))
        expect(navegacao[:dia_seguinte]).to eq(Date.new(2026, 3, 16))
        expect(navegacao[:mes_atual]).to eq({ ano: 2026, mes: 3 })
      end
    end

    context 'sem faturas no dia' do
      before do
        travel_to Date.new(2026, 3, 16)
      end

      it 'retorna zeros para totais' do
        resultado = described_class.new(data: data).call

        expect(resultado[:resumo][:total_faturas]).to eq(0)
        expect(resultado[:resumo][:total_recebido]).to eq(0.0)
        expect(resultado[:resumo][:ticket_medio]).to eq(0.0)
      end

      it 'retorna hash vazio para por_meio' do
        resultado = described_class.new(data: data).call

        expect(resultado[:resumo][:por_meio]).to be_empty
      end
    end

    context 'quando é dia atual (hoje)' do
      before do
        travel_to Date.new(2026, 3, 15)

        create(:fatura,
               contrato: contrato_pf,
               liquidacao: Date.current,
               valor_liquidacao: 100.00)
      end

      it 'não inclui dia seguinte na navegação' do
        resultado = described_class.new(data: Date.current).call

        expect(resultado[:navegacao][:dia_seguinte]).to be_nil
      end

      it 'inclui dia anterior na navegação' do
        resultado = described_class.new(data: Date.current).call

        expect(resultado[:navegacao][:dia_anterior]).to eq(Date.new(2026, 3, 14))
      end
    end

    context 'quando performance está abaixo da média' do
      before do
        travel_to Date.new(2026, 3, 16)

        # Fatura pequena no dia
        create(:fatura,
               contrato: contrato_pf,
               liquidacao: data,
               valor_liquidacao: 10.00)

        # Histórico forte para gerar média alta
        12.times do |i|
          create(:fatura,
                 contrato: contrato_pf,
                 liquidacao: Date.new(2025, i + 1, 15),
                 valor_liquidacao: 100.00)
        end
      end

      it 'identifica performance abaixo' do
        resultado = described_class.new(data: data).call
        comparacao = resultado[:comparacao]

        expect(comparacao[:performance]).to eq(:abaixo)
        expect(comparacao[:diferenca]).to be < 0
        expect(comparacao[:percentual]).to be < 0
      end
    end

    context 'com múltiplos perfis de pagamento' do
      let(:perfil_2) { create(:pagamento_perfil, nome: 'PIX') }
      let(:contrato_pix) { create(:contrato, pessoa: pessoa_fisica, pagamento_perfil: perfil_2) }

      before do
        travel_to Date.new(2026, 3, 16)

        create(:fatura,
               contrato: contrato_pf,
               liquidacao: data,
               valor_liquidacao: 100.00,
               pagamento_perfil: pagamento_perfil)

        create(:fatura,
               contrato: contrato_pix,
               liquidacao: data,
               valor_liquidacao: 200.00,
               pagamento_perfil: perfil_2)
      end

      it 'agrupa por perfil de pagamento no detalhamento' do
        resultado = described_class.new(data: data).call
        por_perfil = resultado[:detalhamento][:por_perfil]

        expect(por_perfil[pagamento_perfil.nome]).to eq(100.00)
        expect(por_perfil['PIX']).to eq(200.00)
      end
    end

    context 'com data passada como string' do
      it 'converte string para Date' do
        travel_to Date.new(2026, 3, 16)

        create(:fatura,
               contrato: contrato_pf,
               liquidacao: Date.new(2026, 3, 15),
               valor_liquidacao: 100.00)

        resultado = described_class.new(data: '2026-03-15').call

        expect(resultado[:resumo][:data]).to eq(Date.new(2026, 3, 15))
        expect(resultado[:resumo][:total_recebido]).to eq(100.00)

        travel_back
      end
    end
  end
end
