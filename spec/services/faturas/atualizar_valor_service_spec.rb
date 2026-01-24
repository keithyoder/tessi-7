# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Faturas::AtualizarValorService, type: :service do
  let!(:pagamento_perfil) { any_pagamento_perfil }
  let!(:contrato) do
    build(
      :contrato,
      adesao: Date.new(2026, 1, 10),
      prazo_meses: 12,
      pagamento_perfil: pagamento_perfil,
      primeiro_vencimento: Date.new(2026, 2, 10),
      dia_vencimento: 10,
      pessoa: any_pessoa_fisica,
      plano: any_plano
    ).tap do |c|
      # Skip the gerar_faturas_iniciais callback
      allow(c).to receive(:gerar_faturas_iniciais)
      c.save!
    end
  end

  describe '.call' do
    context 'quando a fatura não está registrada' do
      let!(:fatura) do
        create(
          :fatura,
          contrato: contrato,
          vencimento: 10.days.from_now,
          vencimento_original: 10.days.from_now,
          valor: 100.00,
          valor_original: 100.00,
          pagamento_perfil: pagamento_perfil,
          nossonumero: '10001',
          parcela: 1,
          periodo_inicio: Date.current,
          periodo_fim: Date.current + 1.month,
          registro_id: nil
        )
      end

      it 'não deleta a fatura' do
        expect do
          described_class.call(fatura: fatura, novo_valor: 150.00)
        end.not_to(change { Fatura.exists?(fatura.id) })
      end

      it 'não cria uma nova fatura' do
        expect do
          described_class.call(fatura: fatura, novo_valor: 150.00)
        end.not_to(change { contrato.faturas.count })
      end

      it 'atualiza o valor da fatura existente' do
        expect do
          described_class.call(fatura: fatura, novo_valor: 150.00)
        end.to change { fatura.reload.valor.to_f }.from(100.00).to(150.00)
      end

      it 'retorna a mesma fatura atualizada' do
        result = described_class.call(fatura: fatura, novo_valor: 150.00)

        expect(result.id).to eq(fatura.id)
        expect(result.valor.to_f).to eq(150.00)
      end

      it 'mantém todos os outros atributos inalterados' do
        described_class.call(fatura: fatura, novo_valor: 150.00)
        fatura.reload

        expect(fatura.periodo_inicio).to eq(Date.current)
        expect(fatura.periodo_fim).to eq(Date.current + 1.month)
        expect(fatura.vencimento).to eq(10.days.from_now.to_date)
        expect(fatura.parcela).to eq(1)
        expect(fatura.nossonumero).to eq('10001')
        expect(fatura.pagamento_perfil).to eq(pagamento_perfil)
      end
    end

    context 'quando a fatura está registrada' do
      let!(:retorno) { create(:retorno, pagamento_perfil: pagamento_perfil) }
      let!(:fatura) do
        create(
          :fatura,
          contrato: contrato,
          vencimento: 10.days.from_now,
          vencimento_original: 10.days.from_now,
          valor: 100.00,
          valor_original: 100.00,
          pagamento_perfil: pagamento_perfil,
          nossonumero: '10001',
          parcela: 1,
          periodo_inicio: Date.current,
          periodo_fim: Date.current + 1.month,
          registro_id: retorno.id
        )
      end

      it 'não deleta a fatura antiga' do
        expect do
          described_class.call(fatura: fatura, novo_valor: 150.00)
        end.not_to(change { Fatura.exists?(fatura.id) })
      end

      it 'marca a fatura antiga como cancelada' do
        expect do
          described_class.call(fatura: fatura, novo_valor: 150.00)
        end.to change { fatura.reload.cancelamento }.from(nil).to(be_present)
      end

      it 'define cancelamento para o momento atual' do
        described_class.call(fatura: fatura, novo_valor: 150.00)

        fatura.reload
        expect(fatura.cancelamento).to be_within(1.second).of(Time.current)
      end

      it 'cria uma nova fatura com o novo valor' do
        expect do
          described_class.call(fatura: fatura, novo_valor: 150.00)
        end.to change { contrato.faturas.count }.by(1)

        nova_fatura = contrato.faturas.reload.order(:created_at).last
        expect(nova_fatura.valor.to_f).to eq(150.00)
        expect(nova_fatura.valor_original.to_f).to eq(100.00) # Mantém o valor original
        expect(nova_fatura.id).not_to eq(fatura.id)
      end

      it 'mantém os mesmos períodos e vencimento' do
        nova_fatura = described_class.call(fatura: fatura, novo_valor: 150.00)

        expect(nova_fatura.periodo_inicio).to eq(fatura.periodo_inicio)
        expect(nova_fatura.periodo_fim).to eq(fatura.periodo_fim)
        expect(nova_fatura.vencimento).to eq(fatura.vencimento)
        expect(nova_fatura.parcela).to eq(fatura.parcela)
      end
    end

    context 'quando ocorre um erro' do
      let!(:fatura) do
        create(
          :fatura,
          contrato: contrato,
          vencimento: 10.days.from_now,
          valor: 100.00,
          valor_original: 100.00,
          pagamento_perfil: pagamento_perfil,
          nossonumero: '10001',
          parcela: 1,
          periodo_inicio: Date.current,
          periodo_fim: Date.current + 1.month
        )
      end

      it 'faz rollback da transação para fatura não registrada' do
        # Mock to fail when updating the fatura
        allow(fatura).to receive(:update!).and_raise(StandardError, 'Erro de teste')

        expect do
          described_class.call(fatura: fatura, novo_valor: 150.00)
        end.to raise_error(StandardError, 'Erro de teste')

        # Fatura original deve manter o valor original
        expect(fatura.reload.valor.to_f).to eq(100.00)
      end

      it 'faz rollback da transação para fatura registrada' do
        retorno = create(:retorno, pagamento_perfil: pagamento_perfil)
        fatura.update!(registro_id: retorno.id)

        # Mock to fail when creating the new fatura
        allow_any_instance_of(ActiveRecord::Associations::CollectionProxy)
          .to receive(:create!).and_raise(StandardError, 'Erro de teste')

        expect do
          described_class.call(fatura: fatura, novo_valor: 150.00)
        end.to raise_error(StandardError, 'Erro de teste')

        # Fatura original não deve estar cancelada
        expect(fatura.reload.cancelamento).to be_nil
      end
    end

    context 'com valores decimais' do
      let!(:fatura) do
        create(
          :fatura,
          contrato: contrato,
          vencimento: 10.days.from_now,
          valor: 99.99,
          valor_original: 99.99,
          pagamento_perfil: pagamento_perfil,
          nossonumero: '10001',
          parcela: 1,
          periodo_inicio: Date.current,
          periodo_fim: Date.current + 1.month
        )
      end

      it 'mantém a precisão decimal' do
        result = described_class.call(fatura: fatura, novo_valor: 239.70)

        expect(result.valor.to_f).to eq(239.70)
      end
    end

    context 'quando vencimento_original está presente' do
      let!(:fatura) do
        create(
          :fatura,
          contrato: contrato,
          vencimento: 10.days.from_now,
          vencimento_original: 5.days.from_now,
          valor: 100.00,
          valor_original: 100.00,
          pagamento_perfil: pagamento_perfil,
          nossonumero: '10001',
          parcela: 1,
          periodo_inicio: Date.current,
          periodo_fim: Date.current + 1.month
        )
      end

      it 'preserva o vencimento_original para fatura não registrada' do
        result = described_class.call(fatura: fatura, novo_valor: 150.00)

        expect(result.vencimento_original).to eq(fatura.vencimento_original)
      end

      it 'preserva o vencimento_original para fatura registrada' do
        retorno = create(:retorno, pagamento_perfil: pagamento_perfil)
        fatura.update!(registro_id: retorno.id)
        
        nova_fatura = described_class.call(fatura: fatura, novo_valor: 150.00)

        expect(nova_fatura.vencimento_original).to eq(fatura.vencimento_original)
      end
    end

    context 'quando vencimento_original está em branco' do
      let!(:retorno) { create(:retorno, pagamento_perfil: pagamento_perfil) }
      let!(:fatura) do
        create(
          :fatura,
          contrato: contrato,
          vencimento: 10.days.from_now,
          vencimento_original: nil,
          valor: 100.00,
          valor_original: 100.00,
          pagamento_perfil: pagamento_perfil,
          nossonumero: '10001',
          parcela: 1,
          periodo_inicio: Date.current,
          periodo_fim: Date.current + 1.month,
          registro_id: retorno.id
        )
      end

      it 'define vencimento_original igual ao vencimento' do
        nova_fatura = described_class.call(fatura: fatura, novo_valor: 150.00)

        expect(nova_fatura.vencimento_original).to eq(fatura.vencimento)
      end
    end
  end
end