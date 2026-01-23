# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contratos::RenovacaoEmLoteService do
  let!(:pagamento_perfil) { any_pagamento_perfil }

  let!(:contrato_elegivel) do
    build(
      :contrato,
      adesao: Date.new(2026, 1, 10),
      prazo_meses: 12,
      pagamento_perfil: pagamento_perfil,
      primeiro_vencimento: Date.new(2026, 2, 10),
      dia_vencimento: 10,
      pessoa: any_pessoa_fisica,
      plano: any_plano,
      cancelamento: nil
    ).tap do |c|
      c.save!
      c.faturas.delete_all
    end
  end

  before do
    create(
      :fatura,
      contrato: contrato_elegivel,
      vencimento: 10.days.from_now,
      periodo_fim: 10.days.from_now,
      periodo_inicio: 20.days.ago,
      pagamento_perfil: pagamento_perfil,
      nossonumero: '10001',
      parcela: 1,
      liquidacao: nil,
      cancelamento: nil
    )
  end

  describe '#call' do
    it 'renova contratos elegíveis e retorna resultado estruturado' do
      renovar_service = instance_double(Contratos::RenovarService, call: [double])
      allow(Contratos::RenovarService).to receive(:new).and_return(renovar_service)

      resultado = described_class.new(
        pagamento_perfil_id: pagamento_perfil.id,
        meses_por_fatura: 1
      ).call

      expect(resultado).to be_a(Contratos::RenovacaoEmLoteService::Resultado)
      expect(resultado.sucesso).to include(contrato_elegivel.pessoa.nome)
      expect(resultado.total_renovados).to eq(1)
      expect(resultado.total_ignorados).to eq(0)
      expect(resultado.total_erros).to eq(0)
    end

    context 'quando contrato não é elegível' do
      before do
        create(
          :fatura,
          contrato: contrato_elegivel,
          vencimento: 15.days.ago,
          periodo_fim: 15.days.ago,
          periodo_inicio: 45.days.ago,
          pagamento_perfil: pagamento_perfil,
          nossonumero: '10002',
          parcela: 2,
          liquidacao: nil,
          cancelamento: nil
        )

        create(
          :fatura,
          contrato: contrato_elegivel,
          vencimento: 20.days.ago,
          periodo_fim: 20.days.ago,
          periodo_inicio: 50.days.ago,
          pagamento_perfil: pagamento_perfil,
          nossonumero: '10003',
          parcela: 3,
          liquidacao: nil,
          cancelamento: nil
        )
      end

      it 'ignora o contrato e não chama RenovarService' do
        allow(Contratos::RenovarService).to receive(:new)

        resultado = described_class.new(
          pagamento_perfil_id: pagamento_perfil.id
        ).call

        expect(Contratos::RenovarService).not_to have_received(:new)
        expect(resultado.ignorados).to include(contrato_elegivel.pessoa.nome)
        expect(resultado.total_ignorados).to eq(1)
        expect(resultado.total_renovados).to eq(0)
      end
    end

    context 'quando ocorre erro na renovação' do
      it 'captura o erro e continua processando' do
        allow(Contratos::RenovarService).to receive(:new).and_raise(StandardError, 'Erro de teste')

        resultado = described_class.new(
          pagamento_perfil_id: pagamento_perfil.id
        ).call

        expect(resultado.erros).to have_key(contrato_elegivel.pessoa.nome)
        expect(resultado.erros[contrato_elegivel.pessoa.nome]).to eq('Erro de teste')
        expect(resultado.total_erros).to eq(1)
      end
    end

    context 'quando há múltiplos contratos' do
      let!(:outro_contrato) do
        build(
          :contrato,
          adesao: Date.new(2026, 1, 10),
          prazo_meses: 12,
          pagamento_perfil: pagamento_perfil,
          primeiro_vencimento: Date.new(2026, 2, 10),
          dia_vencimento: 10,
          pessoa: any_pessoa_fisica,
          plano: any_plano,
          cancelamento: nil
        ).tap do |c|
          c.save!
          c.faturas.delete_all
        end
      end

      before do
        create(
          :fatura,
          contrato: outro_contrato,
          vencimento: 12.days.from_now,
          periodo_fim: 12.days.from_now,
          periodo_inicio: 18.days.ago,
          pagamento_perfil: pagamento_perfil,
          nossonumero: '10004',
          parcela: 1,
          liquidacao: nil,
          cancelamento: nil
        )
      end

      it 'processa todos os contratos elegíveis' do
        renovar_service = instance_double(Contratos::RenovarService, call: [double])
        allow(Contratos::RenovarService).to receive(:new).and_return(renovar_service)

        resultado = described_class.new(
          pagamento_perfil_id: pagamento_perfil.id
        ).call

        expect(resultado.total_renovados).to eq(2)
        expect(resultado.sucesso).to include(contrato_elegivel.pessoa.nome)
        expect(resultado.sucesso).to include(outro_contrato.pessoa.nome)
      end
    end

    context 'quando passa meses_por_fatura customizado' do
      it 'passa o parâmetro para RenovarService' do
        renovar_service = instance_double(Contratos::RenovarService, call: [double])
        allow(Contratos::RenovarService).to receive(:new).and_return(renovar_service)

        described_class.new(
          pagamento_perfil_id: pagamento_perfil.id,
          meses_por_fatura: 3
        ).call

        expect(Contratos::RenovarService).to have_received(:new).with(
          contrato: an_instance_of(Contrato),
          meses_por_fatura: 3
        )
      end
    end
  end
end
