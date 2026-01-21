# frozen_string_literal: true

# spec/services/faturas/gerar_service_spec.rb
require 'rails_helper'

RSpec.describe Faturas::GerarService do
  let(:pagamento_perfil) { create(:pagamento_perfil) }
  let(:contrato) do
    create(
      :contrato,
      adesao: Date.new(2026, 1, 10),
      valor_personalizado: 100.0,
      parcelas_instalacao: 4,
      valor_instalacao: 400.0,
      primeiro_vencimento: Date.new(2026, 2, 10),
      dia_vencimento: 10,
      pagamento_perfil: pagamento_perfil
    )
  end

  describe '.call' do
    context 'quando gera uma fatura de 1 mês' do
      # let(:inicio_esperado) do
      #   ultima_fatura = contrato.faturas.order(:periodo_fim).last
      #   ultima_fatura ? ultima_fatura.periodo_fim + 1.day : contrato.adesao
      # end

      subject(:faturas) { described_class.call(contrato: contrato, quantidade: 1, meses_por_fatura: 1) }

      it 'cria exatamente 1 fatura' do
        ultima_contagem = contrato.faturas.count
        faturas
        expect(contrato.faturas.count).to eq(ultima_contagem + 1)
      end

      it 'define corretamente o período da fatura' do
        ultima = contrato.faturas.order(:periodo_fim).last
        inicio_esperado = ultima ? ultima.periodo_fim + 1.day : contrato.adesao
        fatura = faturas.first
        expect(fatura.periodo_inicio).to eq(inicio_esperado)
        expect(fatura.periodo_fim).to eq(inicio_esperado.advance(months: 1) - 1.day)
        expect(fatura.vencimento).to eq(fatura.periodo_fim)
      end

      it 'calcula corretamente o valor da fatura' do
        fatura = faturas.first
        valor_esperado = contrato.mensalidade
        expect(fatura.valor).to eq(valor_esperado)
      end

      it 'atribui corretamente parcela e nossonumero' do
        # captura a última fatura antes de gerar novas
        ultima = contrato.faturas.order(:parcela).last
        ultima_parcela = ultima&.parcela || 0
        ultima_nosso   = (ultima&.nossonumero || pagamento_perfil.proximo_nosso_numero).to_i

        fatura = faturas.first

        expect(fatura.parcela).to eq(ultima_parcela + 1)
        expect(fatura.nossonumero.to_i).to eq(ultima_nosso + 1)
      end
    end

    context 'quando gera múltiplas faturas de meses_por_fatura = 2' do
      subject(:faturas) { described_class.call(contrato: contrato, quantidade: 2, meses_por_fatura: 2) }

      it 'cria 2 faturas' do
        ultima_contagem = contrato.faturas.count
        faturas
        expect(contrato.faturas.count).to eq(ultima_contagem + 2)
      end

      it 'define corretamente os períodos das faturas' do
        # captura a última fatura existente antes de gerar novas
        ultima = contrato.faturas.order(:periodo_fim).last
        f1, f2 = faturas

        # início da primeira nova fatura
        inicio_f1 = ultima ? ultima.periodo_fim + 1.day : contrato.adesao

        expect(f1.periodo_inicio).to eq(inicio_f1)
        expect(f1.periodo_fim).to eq(inicio_f1.advance(months: 2) - 1.day)

        expect(f2.periodo_inicio).to eq(f1.periodo_fim + 1.day)
        expect(f2.periodo_fim).to eq(f2.periodo_inicio.advance(months: 2) - 1.day)
      end

      it 'incrementa corretamente parcela e nossonumero' do
        # captura a última fatura existente antes de gerar novas
        ultima = contrato.faturas.order(:parcela).last
        ultima_parcela = ultima&.parcela || 0
        ultima_nosso   = (ultima&.nossonumero || pagamento_perfil.proximo_nosso_numero).to_i

        f1, f2 = faturas

        expect(f1.parcela).to eq(ultima_parcela + 1)
        expect(f2.parcela).to eq(ultima_parcela + 2)

        expect(f1.nossonumero.to_i).to eq(ultima_nosso + 1)
        expect(f2.nossonumero.to_i).to eq(ultima_nosso + 2)
      end

      it 'não gera períodos encurtados quando o mês anterior termina no dia 30 ou 31' do
        contrato.faturas.destroy_all
        contrato.faturas.create!(
          periodo_inicio: Date.new(2026, 1, 1),
          periodo_fim: Date.new(2026, 1, 30),
          valor: 100,
          parcela: 1,
          nossonumero: 1,
          pagamento_perfil: contrato.pagamento_perfil,
          vencimento: Date.new(2026, 1, 30)
        )

        f2 = described_class.call(
          contrato: contrato,
          quantidade: 1,
          meses_por_fatura: 1
        ).first

        expect(f2.periodo_inicio).to eq(Date.new(2026, 1, 31))
        expect(f2.periodo_fim).to eq(Date.new(2026, 2, 28))
      end
    end

    context 'quando contrato já possui faturas' do
      before do
        # Gera 2 faturas iniciais
        described_class.call(contrato: contrato, quantidade: 2)
      end

      it 'gera a próxima fatura a partir do último período' do
        ultima = contrato.faturas.order(:periodo_fim).last
        nova_fatura = described_class.call(contrato: contrato, quantidade: 1).first

        expect(nova_fatura.periodo_inicio).to eq(ultima.periodo_fim + 1.day)
        expect(nova_fatura.periodo_fim).to eq(nova_fatura.periodo_inicio.advance(months: 1) - 1.day)
        expect(nova_fatura.parcela).to eq(ultima.parcela + 1)
        expect(nova_fatura.nossonumero).to eq((ultima.nossonumero.to_i + 1).to_s)
      end
    end

    context 'quando meses_por_fatura é nil' do
      it 'assume 1 mês por padrão' do
        fatura = described_class.call(contrato: contrato, quantidade: 1, meses_por_fatura: nil).first
        expect(fatura.periodo_fim).to eq(fatura.periodo_inicio.advance(months: 1) - 1.day)
      end
    end
  end
end
