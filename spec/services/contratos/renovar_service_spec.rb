# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contratos::RenovarService do
  include ActiveSupport::Testing::TimeHelpers

  let(:plano) { any_plano(mensalidade: 100.0) }

  let(:contrato) do
    any_contrato(
      pessoa: any_pessoa_fisica,
      plano: plano,
      adesao: Date.new(2026, 1, 10),
      prazo_meses: 12,
      valor_personalizado: 150.0,
      parcelas_instalacao: 4,
      valor_instalacao: 400.0,
      primeiro_vencimento: Date.new(2026, 2, 10),
      dia_vencimento: 10,
      pagamento_perfil: any_pagamento_perfil,
      cancelamento: nil
    )
  end

  before { travel_to Date.new(2026, 1, 10) }

  describe '#call' do
    context 'quando o contrato está cancelado' do
      before do
        # rubocop:disable Rails/SkipsModelValidations
        # Usa update_columns para evitar callbacks que processariam o cancelamento
        contrato.update_columns(cancelamento: Date.new(2025, 12, 31))
        # rubocop:enable Rails/SkipsModelValidations
      end

      it 'levanta erro quando o contrato é cancelado' do
        expect do
          described_class.new(contrato: contrato, meses_por_fatura: 1).call
        end.to raise_error(ArgumentError)
      end
    end

    context 'quando não há faturas existentes' do
      before { contrato.faturas.destroy_all }

      it 'gera faturas a partir da adesão' do
        # allow the original service to run, we just want to observe the side effect
        allow(Faturas::GerarService).to receive(:call).and_call_original

        described_class.new(contrato: contrato).call

        primeira_fatura = contrato.faturas.order(:periodo_inicio).first
        expect(primeira_fatura.periodo_inicio).to eq(contrato.adesao + 1.day)
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
        spy_service = class_spy(Faturas::GerarService)
        stub_const('Faturas::GerarService', spy_service)

        described_class.new(contrato: contrato, meses_por_fatura: 3).call

        expect(spy_service).to have_received(:call) do |args|
          expect(args[:meses_por_fatura]).to eq(3)
        end
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
        allow(contrato).to receive(:gerar_faturas_iniciais)
      end

      it 'não chama o GerarService' do
        spy_service = class_spy(Faturas::GerarService)
        stub_const('Faturas::GerarService', spy_service)

        described_class.new(contrato: contrato).call

        expect(spy_service).not_to have_received(:call)
      end

      it 'retorna nil' do
        result = described_class.new(contrato: contrato).call
        expect(result).to be_nil
      end
    end

    context 'para cálculo de months_between' do
      it 'retorna meses corretos entre duas datas' do
        service = described_class.new(contrato: contrato)
        inicio = Date.new(2026, 1, 15)
        fim = Date.new(2026, 4, 14)

        expect(service.send(:months_between, inicio, fim)).to eq(2)
      end
    end
  end
end
