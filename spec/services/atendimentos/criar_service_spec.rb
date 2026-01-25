# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Atendimentos::CriarService do
  let(:atendente) { create(:user, role: :financeiro_n1, email: 'atendente@example.com') }
  let(:responsavel) { create(:user, role: :financeiro_n1, email: 'responsavel@example.com') }
  let(:pessoa) { any_pessoa_fisica }
  let(:classificacao) { create(:classificacao) }

  let(:valid_atendimento_params) do
    {
      pessoa_id: pessoa.id,
      classificacao_id: classificacao.id,
      responsavel_id: responsavel.id
    }
  end

  let(:detalhe_tipo) { 'Presencial' }
  let(:detalhe_descricao) { 'Cliente relatou problema na conexão' }

  describe '.call' do
    context 'com parâmetros válidos' do
      it 'cria o atendimento e o detalhe inicial' do
        expect do
          described_class.call(
            atendimento_params: valid_atendimento_params,
            detalhe_tipo: detalhe_tipo,
            detalhe_descricao: detalhe_descricao,
            atendente: atendente
          )
        end.to change(Atendimento, :count).by(1)
          .and change(AtendimentoDetalhe, :count).by(1)
      end

      it 'retorna success: true' do
        result = described_class.call(
          atendimento_params: valid_atendimento_params,
          detalhe_tipo: detalhe_tipo,
          detalhe_descricao: detalhe_descricao,
          atendente: atendente
        )

        expect(result[:success]).to be true
      end

      it 'retorna o atendimento persistido' do
        result = described_class.call(
          atendimento_params: valid_atendimento_params,
          detalhe_tipo: detalhe_tipo,
          detalhe_descricao: detalhe_descricao,
          atendente: atendente
        )

        expect(result[:atendimento]).to be_persisted
        expect(result[:atendimento].pessoa).to eq(pessoa)
        expect(result[:atendimento].classificacao).to eq(classificacao)
        expect(result[:atendimento].responsavel).to eq(responsavel)
      end

      it 'retorna o detalhe persistido com os dados corretos' do
        result = described_class.call(
          atendimento_params: valid_atendimento_params,
          detalhe_tipo: detalhe_tipo,
          detalhe_descricao: detalhe_descricao,
          atendente: atendente
        )

        detalhe = result[:detalhe]
        expect(detalhe).to be_persisted
        expect(detalhe.atendimento).to eq(result[:atendimento])
        expect(detalhe.atendente).to eq(atendente)
        expect(detalhe.tipo).to eq(detalhe_tipo)
        expect(detalhe.descricao).to eq(detalhe_descricao)
      end

      it 'associa o detalhe ao atendimento' do
        result = described_class.call(
          atendimento_params: valid_atendimento_params,
          detalhe_tipo: detalhe_tipo,
          detalhe_descricao: detalhe_descricao,
          atendente: atendente
        )

        expect(result[:atendimento].detalhes).to include(result[:detalhe])
      end
    end

    context 'com detalhe_tipo como inteiro (do enum)' do
      it 'converte corretamente para o tipo do enum' do
        # Assumindo que AtendimentoDetalhe.tipos = { Presencial: 0, Telefone: 1, Email: 2 }
        tipo_integer = AtendimentoDetalhe.tipos[:Presencial]

        result = described_class.call(
          atendimento_params: valid_atendimento_params,
          detalhe_tipo: tipo_integer,
          detalhe_descricao: detalhe_descricao,
          atendente: atendente
        )

        expect(result[:success]).to be true
        expect(result[:detalhe].tipo).to eq('Presencial')
      end
    end

    context 'com parâmetros inválidos no atendimento' do
      let(:invalid_atendimento_params) do
        {
          pessoa_id: nil, # pessoa_id é obrigatório
          classificacao_id: classificacao.id,
          responsavel_id: responsavel.id
        }
      end

      it 'não cria o atendimento nem o detalhe' do
        expect do
          described_class.call(
            atendimento_params: invalid_atendimento_params,
            detalhe_tipo: detalhe_tipo,
            detalhe_descricao: detalhe_descricao,
            atendente: atendente
          )
        end.not_to change(Atendimento, :count)

        expect(AtendimentoDetalhe.count).to eq(0)
      end

      it 'retorna success: false' do
        result = described_class.call(
          atendimento_params: invalid_atendimento_params,
          detalhe_tipo: detalhe_tipo,
          detalhe_descricao: detalhe_descricao,
          atendente: atendente
        )

        expect(result[:success]).to be false
      end

      it 'retorna o atendimento com erros de validação' do
        result = described_class.call(
          atendimento_params: invalid_atendimento_params,
          detalhe_tipo: detalhe_tipo,
          detalhe_descricao: detalhe_descricao,
          atendente: atendente
        )

        expect(result[:atendimento]).to be_present
        expect(result[:atendimento].errors).to be_present
        expect(result[:atendimento]).not_to be_persisted
      end
    end

    context 'com parâmetros inválidos no detalhe' do
      let(:invalid_detalhe_descricao) { nil } # descrição é obrigatória

      it 'não cria nem o atendimento nem o detalhe (rollback)' do
        expect do
          described_class.call(
            atendimento_params: valid_atendimento_params,
            detalhe_tipo: detalhe_tipo,
            detalhe_descricao: invalid_detalhe_descricao,
            atendente: atendente
          )
        end.not_to change(Atendimento, :count)

        expect(AtendimentoDetalhe.count).to eq(0)
      end

      it 'retorna success: false' do
        result = described_class.call(
          atendimento_params: valid_atendimento_params,
          detalhe_tipo: detalhe_tipo,
          detalhe_descricao: invalid_detalhe_descricao,
          atendente: atendente
        )

        expect(result[:success]).to be false
      end

      it 'retorna o detalhe com erros de validação' do
        result = described_class.call(
          atendimento_params: valid_atendimento_params,
          detalhe_tipo: detalhe_tipo,
          detalhe_descricao: invalid_detalhe_descricao,
          atendente: atendente
        )

        expect(result[:detalhe]).to be_present
        expect(result[:detalhe].errors).to be_present
        expect(result[:detalhe]).not_to be_persisted
      end
    end

    context 'com transação (atomicidade)' do
      it 'garante que ambos são criados ou nenhum é criado' do
        # Instead of stubbing, use actual validation failures
        # Add a validation that will fail after atendimento is created
        allow(AtendimentoDetalhe).to receive(:create!).and_raise(
          ActiveRecord::RecordInvalid.new(
            AtendimentoDetalhe.new(descricao: nil)
          )
        )

        expect do
          described_class.call(
            atendimento_params: valid_atendimento_params,
            detalhe_tipo: detalhe_tipo,
            detalhe_descricao: detalhe_descricao,
            atendente: atendente
          )
        end.not_to change(Atendimento, :count)
      end

      # Alternative: test with actual data that fails validation
      it 'garante rollback quando detalhe tem dados inválidos' do
        # This relies on the actual validation logic
        # Assumes AtendimentoDetalhe validates presence of descricao
        expect do
          described_class.call(
            atendimento_params: valid_atendimento_params,
            detalhe_tipo: detalhe_tipo,
            detalhe_descricao: '', # inválido
            atendente: atendente
          )
        end.not_to change(Atendimento, :count)

        expect(AtendimentoDetalhe.count).to eq(0)
      end

      # Even better: test with credit card validation
      it 'garante rollback quando detalhe contém dados de cartão' do
        # Assumes the credit card validation is in place
        descricao_com_cartao = 'Pagamento com cartão 4111111111111111'

        expect do
          described_class.call(
            atendimento_params: valid_atendimento_params,
            detalhe_tipo: detalhe_tipo,
            detalhe_descricao: descricao_com_cartao,
            atendente: atendente
          )
        end.not_to change(Atendimento, :count)

        expect(AtendimentoDetalhe.count).to eq(0)
      end
    end
  end
end
