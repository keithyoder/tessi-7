# spec/services/contratos/renovar_service_spec.rb
require 'rails_helper'

RSpec.describe Contratos::RenovarService do
  include ActiveSupport::Testing::TimeHelpers

  let(:plano) { any_plano(mensalidade: 100.0) }
  let(:pagamento_perfil) { any_pagamento_perfil }
  let(:pessoa) { any_pessoa_fisica }

  let(:contrato) do
    any_contrato(
      pessoa: pessoa,
      plano: plano,
      adesao: Date.new(2026, 1, 10),
      prazo_meses: 12,
      valor_personalizado: 150.0,
      parcelas_instalacao: 4,
      valor_instalacao: 400.0,
      primeiro_vencimento: Date.new(2026, 2, 10),
      dia_vencimento: 10,
      pagamento_perfil: pagamento_perfil
    )
  end

  before do
    travel_to Date.new(2026, 1, 10)
  end

  after do
    travel_back
  end

  describe '#call' do
    context 'quando não há faturas existentes' do
      before do
        contrato.faturas.destroy_all
      end

      it 'gera faturas a partir da adesão' do
        expect(Faturas::GerarService).to receive(:call).with(
          contrato: contrato,
          quantidade: anything,
          meses_por_fatura: 1
        ).and_call_original

        described_class.new(contrato: contrato).call

        primeira_fatura = contrato.faturas.order(:periodo_inicio).first
        expect(primeira_fatura.periodo_inicio).to eq(contrato.adesao)
      end
    end

    context 'quando já existem faturas' do
      before do
        # Mantém apenas as primeiras 6 faturas para teste de renovação
        contrato.faturas.order(:periodo_inicio).last(6).each(&:destroy)
      end

      it 'gera faturas a partir da última fatura existente' do
        ultima_fatura = contrato.faturas.order(:periodo_fim).last

        described_class.new(contrato: contrato, meses_por_fatura: 2).call

        nova_fatura = contrato.faturas.order(:periodo_inicio).last
        expect(nova_fatura.periodo_fim).to eq(ultima_fatura.periodo_fim + 6.months)
      end

      it 'respeita o meses_por_fatura ao calcular a quantidade' do
        expect(Faturas::GerarService).to receive(:call) do |args|
          expect(args[:meses_por_fatura]).to eq(3)
        end

        described_class.new(contrato: contrato, meses_por_fatura: 3).call
      end
    end

    context 'quando meses_por_fatura não é informado' do
      it 'usa 1 mês por padrão' do
        service = described_class.new(contrato: contrato, meses_por_fatura: nil)
        expect(service.meses_por_fatura).to eq(1)
      end
    end

    context 'quando não restam meses para gerar faturas' do
      before do
        allow_any_instance_of(Contrato).to receive(:gerar_faturas_iniciais)
        contrato
      end

      it 'não chama o GerarService' do
        expect(Faturas::GerarService).not_to receive(:call)

        described_class.new(contrato: contrato).call
      end
    end

    context 'cálculo de months_between' do
      it 'retorna meses corretos entre duas datas' do
        service = described_class.new(contrato: contrato)
        inicio = Date.new(2026, 1, 15)
        fim = Date.new(2026, 4, 14)
        expect(service.send(:months_between, inicio, fim)).to eq(2) # jan 15 → mar 14 = 2 meses
      end
    end
  end
end
