# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contratos::CancelamentoService, type: :service do
  let(:pagamento_perfil) { any_pagamento_perfil }

  let(:contrato) do
    build(
      :contrato,
      pagamento_perfil: pagamento_perfil,
      plano: any_plano
    ).tap do |c|
      c.save!
      c.faturas.destroy_all
    end
  end

  describe '.call' do
    context 'quando há faturas futuras não registradas' do
      let!(:fatura_futura) do
        create(
          :fatura,
          contrato: contrato,
          periodo_inicio: Date.new(2026, 4, 11),
          periodo_fim: Date.new(2026, 5, 10),
          vencimento: Date.new(2026, 5, 10),
          valor: 100.00,
          pagamento_perfil: pagamento_perfil,
          nossonumero: '10001',
          parcela: 1,
          registro_id: nil
        )
      end

      it 'remove as faturas futuras não registradas' do
        # Garante que a fatura futura existe antes do teste
        expect(fatura_futura).to be_persisted

        expect do
          described_class.call(
            contrato: contrato,
            data_cancelamento: Date.new(2026, 4, 1)
          )
        end.to change { contrato.faturas.count }.by(-1)
      end

      it 'não remove faturas anteriores ao cancelamento' do
        fatura_anterior = create(
          :fatura,
          contrato: contrato,
          periodo_inicio: Date.new(2026, 2, 11),
          periodo_fim: Date.new(2026, 3, 10),
          vencimento: Date.new(2026, 3, 10),
          valor: 100.00,
          pagamento_perfil: pagamento_perfil,
          nossonumero: '10002',
          parcela: 2
        )

        described_class.call(
          contrato: contrato,
          data_cancelamento: Date.new(2026, 4, 1)
        )

        expect(fatura_anterior.reload).to be_persisted
      end
    end

    context 'quando há faturas futuras já registradas' do
      let!(:retorno) { create(:retorno, pagamento_perfil: pagamento_perfil) }

      let!(:fatura_registrada) do
        create(
          :fatura,
          contrato: contrato,
          periodo_inicio: Date.new(2026, 4, 11),
          periodo_fim: Date.new(2026, 5, 10),
          vencimento: Date.new(2026, 5, 10),
          valor: 100.00,
          pagamento_perfil: pagamento_perfil,
          nossonumero: '10001',
          parcela: 1
        ).tap do |f|
          # rubocop:disable Rails/SkipsModelValidations
          # Necessário para simular fatura registrada sem callbacks/validações
          f.update_columns(registro_id: retorno.id)
          # rubocop:enable Rails/SkipsModelValidations
        end
      end

      it 'marca as faturas registradas como canceladas' do
        freeze_time do
          described_class.call(
            contrato: contrato,
            data_cancelamento: Date.new(2026, 4, 1)
          )

          expect(fatura_registrada.reload.cancelamento).to eq(Time.current)
        end
      end

      it 'não remove as faturas registradas do banco' do
        expect do
          described_class.call(
            contrato: contrato,
            data_cancelamento: Date.new(2026, 4, 1)
          )
        end.not_to(change { contrato.faturas.count })
      end
    end

    context 'quando há fatura parcial (período engloba o cancelamento)' do
      let!(:fatura_parcial) do
        create(
          :fatura,
          contrato: contrato,
          periodo_inicio: Date.new(2026, 3, 11),
          periodo_fim: Date.new(2026, 4, 10),
          vencimento: Date.new(2026, 4, 10),
          valor: 100.00,
          valor_original: 100.00,
          pagamento_perfil: pagamento_perfil,
          nossonumero: '10001',
          parcela: 1,
          registro_id: nil
        )
      end

      it 'ajusta o valor proporcionalmente ao período utilizado' do
        # Cancelamento em 25/03 significa último dia de serviço foi 24/03
        # Período cobrado: 11/03 a 24/03 = 14 dias
        described_class.call(
          contrato: contrato,
          data_cancelamento: Date.new(2026, 3, 25)
        )

        fatura_parcial.reload

        # ~14 dias de 31 dias = ~45%
        expect(fatura_parcial.valor).to be < 100.00
        expect(fatura_parcial.valor).to be > 0
      end

      it 'mantém o valor_original intacto' do
        described_class.call(
          contrato: contrato,
          data_cancelamento: Date.new(2026, 3, 25)
        )

        expect(fatura_parcial.reload.valor_original).to eq(100.00)
      end

      it 'não ajusta faturas já pagas' do
        fatura_parcial.update!(liquidacao: Date.new(2026, 3, 20))

        expect do
          described_class.call(
            contrato: contrato,
            data_cancelamento: Date.new(2026, 3, 25)
          )
        end.not_to(change { fatura_parcial.reload.valor })
      end

      it 'não ajusta faturas já registradas' do
        retorno = create(:retorno, pagamento_perfil: pagamento_perfil)
        # rubocop:disable Rails/SkipsModelValidations
        # Necessário para simular fatura registrada sem callbacks
        fatura_parcial.update_columns(registro_id: retorno.id)
        # rubocop:enable Rails/SkipsModelValidations

        expect do
          described_class.call(
            contrato: contrato,
            data_cancelamento: Date.new(2026, 3, 25)
          )
        end.not_to(change { fatura_parcial.reload.valor })
      end
    end

    context 'quando há múltiplas faturas de diferentes tipos' do
      let!(:retorno) { create(:retorno, pagamento_perfil: pagamento_perfil) }

      let!(:fatura_anterior) do
        create(
          :fatura,
          contrato: contrato,
          periodo_inicio: Date.new(2026, 2, 11),
          periodo_fim: Date.new(2026, 3, 10),
          vencimento: Date.new(2026, 3, 10),
          valor: 100.00,
          pagamento_perfil: pagamento_perfil,
          nossonumero: '10001',
          parcela: 1
        )
      end

      let!(:fatura_parcial) do
        create(
          :fatura,
          contrato: contrato,
          periodo_inicio: Date.new(2026, 3, 11),
          periodo_fim: Date.new(2026, 4, 10),
          vencimento: Date.new(2026, 4, 10),
          valor: 100.00,
          valor_original: 100.00,
          pagamento_perfil: pagamento_perfil,
          nossonumero: '10002',
          parcela: 2,
          registro_id: nil
        )
      end

      let!(:fatura_futura_nao_registrada) do
        create(
          :fatura,
          contrato: contrato,
          periodo_inicio: Date.new(2026, 4, 11),
          periodo_fim: Date.new(2026, 5, 10),
          vencimento: Date.new(2026, 5, 10),
          valor: 100.00,
          pagamento_perfil: pagamento_perfil,
          nossonumero: '10003',
          parcela: 3,
          registro_id: nil
        )
      end

      let!(:fatura_futura_registrada) do
        create(
          :fatura,
          contrato: contrato,
          periodo_inicio: Date.new(2026, 5, 11),
          periodo_fim: Date.new(2026, 6, 10),
          vencimento: Date.new(2026, 6, 10),
          valor: 100.00,
          pagamento_perfil: pagamento_perfil,
          nossonumero: '10004',
          parcela: 4
        ).tap do |f|
          # rubocop:disable Rails/SkipsModelValidations
          # Necessário para simular fatura registrada sem callbacks
          f.update_columns(registro_id: retorno.id)
          # rubocop:enable Rails/SkipsModelValidations
        end
      end

      it 'não toca em faturas anteriores' do
        freeze_time do
          described_class.call(
            contrato: contrato,
            data_cancelamento: Date.new(2026, 3, 25)
          )

          expect(fatura_anterior.reload.valor).to eq(100.00)
          expect(fatura_anterior.cancelamento).to be_nil
        end
      end

      it 'ajusta valor de faturas parciais' do
        freeze_time do
          described_class.call(
            contrato: contrato,
            data_cancelamento: Date.new(2026, 3, 25)
          )

          expect(fatura_parcial.reload.valor).to be < 100.00
          expect(fatura_parcial.cancelamento).to be_nil
        end
      end

      it 'remove faturas futuras não registradas' do
        freeze_time do
          described_class.call(
            contrato: contrato,
            data_cancelamento: Date.new(2026, 3, 25)
          )

          expect { fatura_futura_nao_registrada.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      it 'cancela faturas futuras registradas' do
        freeze_time do
          described_class.call(
            contrato: contrato,
            data_cancelamento: Date.new(2026, 3, 25)
          )

          expect(fatura_futura_registrada.reload.cancelamento).to eq(Time.current)
        end
      end
    end

    context 'quando o cancelamento é no primeiro dia do período' do
      let!(:fatura) do
        create(
          :fatura,
          contrato: contrato,
          periodo_inicio: Date.new(2026, 3, 11),
          periodo_fim: Date.new(2026, 4, 10),
          vencimento: Date.new(2026, 4, 10),
          valor: 100.00,
          valor_original: 100.00,
          pagamento_perfil: pagamento_perfil,
          nossonumero: '10001',
          parcela: 1,
          registro_id: nil
        )
      end

      it 'remove a fatura completamente' do
        expect do
          described_class.call(
            contrato: contrato,
            data_cancelamento: Date.new(2026, 3, 11)
          )
        end.to change { contrato.faturas.count }.by(-1)

        # Confirma que a fatura foi deletada
        expect { fatura.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'quando o cancelamento é no segundo dia do período' do
      let!(:fatura) do
        create(
          :fatura,
          contrato: contrato,
          periodo_inicio: Date.new(2026, 3, 11),
          periodo_fim: Date.new(2026, 4, 10),
          vencimento: Date.new(2026, 4, 10),
          valor: 100.00,
          valor_original: 100.00,
          pagamento_perfil: pagamento_perfil,
          nossonumero: '10001',
          parcela: 1,
          registro_id: nil
        )
      end

      it 'ajusta para valor proporcional (1 dia de 31)' do
        # Cancelamento em 12/03 significa que o último dia de serviço foi 11/03
        # Período cobrado: 11/03 apenas = 1 dia
        described_class.call(
          contrato: contrato,
          data_cancelamento: Date.new(2026, 3, 12)
        )

        # 1 dia de 31 dias = 3.23
        expect(fatura.reload.valor).to be_within(0.50).of(3.23)
      end
    end

    context 'quando o cancelamento é no último dia do período' do
      let!(:fatura) do
        create(
          :fatura,
          contrato: contrato,
          periodo_inicio: Date.new(2026, 3, 11),
          periodo_fim: Date.new(2026, 4, 10),
          vencimento: Date.new(2026, 4, 10),
          valor: 100.00,
          valor_original: 100.00,
          pagamento_perfil: pagamento_perfil,
          nossonumero: '10001',
          parcela: 1,
          registro_id: nil
        )
      end

      it 'cobra até o dia anterior ao cancelamento (30 de 31 dias)' do
        described_class.call(
          contrato: contrato,
          data_cancelamento: Date.new(2026, 4, 10)
        )

        # Cancelamento em 10/04 significa último dia de serviço foi 09/04
        # Período: 11/03 a 09/04 = 30 dias
        # 100 * (30/31) = 96.77
        expect(fatura.reload.valor).to be_within(0.50).of(96.77)
      end
    end

    context 'quando o cancelamento é após o período completo' do
      let!(:fatura) do
        create(
          :fatura,
          contrato: contrato,
          periodo_inicio: Date.new(2026, 3, 11),
          periodo_fim: Date.new(2026, 4, 10),
          vencimento: Date.new(2026, 4, 10),
          valor: 100.00,
          valor_original: 100.00,
          pagamento_perfil: pagamento_perfil,
          nossonumero: '10001',
          parcela: 1,
          registro_id: nil
        )
      end

      it 'não remove a fatura (período já foi utilizado completamente)' do
        expect do
          described_class.call(
            contrato: contrato,
            data_cancelamento: Date.new(2026, 4, 11)
          )
        end.not_to(change { contrato.faturas.count })

        # Fatura permanece (deve ser cobrada normalmente)
        expect(fatura.reload).to be_persisted
        expect(fatura.valor).to eq(100.00)
      end
    end

    context 'quando ocorre erro durante a transação' do
      let!(:fatura_parcial) do
        create(
          :fatura,
          contrato: contrato,
          periodo_inicio: Date.new(2026, 3, 11),
          periodo_fim: Date.new(2026, 4, 10),
          vencimento: Date.new(2026, 4, 10),
          valor: 100.00,
          valor_original: 100.00,
          pagamento_perfil: pagamento_perfil,
          nossonumero: '10001',
          parcela: 1
        )
      end

      it 'executa todas as operações em uma transação' do
        # Mock para forçar erro durante ajuste de fatura parcial
        # Necessário usar any_instance pois o serviço carrega novas instâncias via query
        allow_any_instance_of(Fatura).to receive(:update!).and_raise(ActiveRecord::RecordInvalid) # rubocop:disable RSpec/AnyInstance

        expect do
          described_class.call(
            contrato: contrato,
            data_cancelamento: Date.new(2026, 3, 25)
          )
        end.to raise_error(ActiveRecord::RecordInvalid)

        # Nenhuma operação deve ter sido persistida
        expect(fatura_parcial.reload.valor).to eq(100.00)
      end
    end
  end
end
