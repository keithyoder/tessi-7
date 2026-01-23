# spec/services/faturas/gerar_service_spec.rb
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Faturas::GerarService do
  let(:pagamento_perfil) { any_pagamento_perfil }
  let(:contrato) do
    build(
      :contrato,
      adesao: Date.new(2026, 1, 10),
      valor_personalizado: 100.0,
      parcelas_instalacao: 4,
      valor_instalacao: 400.0,
      primeiro_vencimento: Date.new(2026, 2, 10),
      dia_vencimento: 10,
      pagamento_perfil: pagamento_perfil
    ).tap do |c|
      c.save!
      c.faturas.delete_all
    end
  end

  describe '.call' do
    context 'quando gera fatura de 1 mês' do
      it 'cria exatamente 1 fatura com período correto' do
        fatura = described_class.call(contrato: contrato, quantidade: 1, meses_por_fatura: 1).first

        aggregate_failures do
          expect(fatura.periodo_inicio).to eq(contrato.adesao + 1.day)
          expect(fatura.periodo_fim).to eq(contrato.primeiro_vencimento)
          expect(fatura.vencimento).to eq(contrato.primeiro_vencimento)
          expect(fatura.parcela).to eq(1)
          expect(fatura.valor).to eq(contrato.mensalidade + contrato.valor_instalacao / contrato.parcelas_instalacao)
        end
      end
    end

    context 'quando gera múltiplas faturas de 2 meses cada' do
      it 'cria faturas consecutivas de 2 meses' do
        faturas = described_class.call(contrato: contrato, quantidade: 2, meses_por_fatura: 2)

        aggregate_failures do
          expect(faturas[0].periodo_inicio).to eq(contrato.adesao + 1.day)
          expect(faturas[0].periodo_fim).to eq(faturas[0].periodo_inicio.advance(months: 2) - 1.day)

          expect(faturas[1].periodo_inicio).to eq(faturas[0].periodo_fim + 1.day)
          expect(faturas[1].periodo_fim).to eq(faturas[1].periodo_inicio.advance(months: 2) - 1.day)

          expect(faturas[1].parcela).to eq(faturas[0].parcela + 1)
          expect(faturas[1].nossonumero.to_i).to eq(faturas[0].nossonumero.to_i + 1)
        end
      end
    end

    context 'quando meses_por_fatura é nil' do
      it 'assume 1 mês por padrão' do
        fatura = described_class.call(contrato: contrato, quantidade: 1, meses_por_fatura: nil).first

        aggregate_failures do
          expect(fatura.periodo_fim).to eq(fatura.periodo_inicio.advance(months: 1) - 1.day)
          expect(fatura.parcela).to eq(1)
        end
      end
    end

    context 'quando contrato já possui faturas' do
      before do
        # Create initial faturas manually
        described_class.call(contrato: contrato, quantidade: 2)
      end

      it 'gera a próxima fatura a partir do último período' do
        ultima = contrato.faturas.order(:periodo_fim).last
        nova_fatura = described_class.call(contrato: contrato, quantidade: 1).first

        aggregate_failures do
          expect(nova_fatura.periodo_inicio).to eq(ultima.periodo_fim + 1.day)
          expect(nova_fatura.periodo_fim).to eq(nova_fatura.periodo_inicio.advance(months: 1) - 1.day)
          expect(nova_fatura.parcela).to eq(ultima.parcela + 1)
          expect(nova_fatura.nossonumero.to_i).to eq(ultima.nossonumero.to_i + 1)
        end
      end
    end

    context 'quando contrato tem cancelamento no meio do período' do
      it 'calcula valor proporcional usando PeriodoUtilizado' do
        fatura = described_class.call(contrato: contrato, quantidade: 1, meses_por_fatura: 1).first

        # simula cancelamento no meio da fatura
        cancelamento = fatura.periodo_inicio + 10.days
        tempo_utilizado = Faturas::PeriodoUtilizado.call(
          inicio: fatura.periodo_inicio,
          fim: cancelamento
        )

        valor_proporcional = (fatura.valor * tempo_utilizado).round(2)

        aggregate_failures do
          expect(tempo_utilizado).to be > 0
          expect(tempo_utilizado).to be <= 1
          expect(valor_proporcional).to be <= fatura.valor
        end
      end
    end
  end
end
