# frozen_string_literal: true

# spec/controllers/atendimento_detalhes_controller_spec.rb
require 'rails_helper'

RSpec.describe AtendimentoDetalhesController, type: :controller do
  let(:user) { create(:user, :financeiro_n1) }
  let(:atendimento) { create(:atendimento) }
  let(:valid_attributes) do
    {
      atendimento_id: atendimento.id,
      tipo: :Presencial,
      atendente_id: user.id,
      descricao: 'Teste'
    }
  end

  let(:invalid_attributes) do
    { tipo: nil, atendente_id: nil, descricao: '' }
  end

  describe 'Autorização' do
    context 'quando não está logado' do
      it 'redireciona para a página de login' do
        get :new, params: { atendimento_id: atendimento.id }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'quando está logado sem permissão' do
      let(:unauthorized_user) { create(:user) }

      before { sign_in unauthorized_user }

      it 'redireciona para a página inicial' do
        get :new, params: { atendimento_id: atendimento.id }
        expect(response).to redirect_to(root_path)
      end
    end
  end

  context 'quando está logado com permissão' do
    before { sign_in user }

    describe 'GET #new' do
      it 'retorna status de sucesso' do
        get :new, params: { atendimento_id: atendimento.id }
        expect(response).to have_http_status(:success)
      end
    end

    describe 'POST #create' do
      context 'com parâmetros válidos' do
        it 'cria um novo AtendimentoDetalhe' do
          expect do
            post :create, params: { atendimento_id: atendimento.id, atendimento_detalhe: valid_attributes }
          end.to change(AtendimentoDetalhe, :count).by(1)
        end

        it 'redireciona para o atendimento com uma notificação' do
          post :create, params: { atendimento_id: atendimento.id, atendimento_detalhe: valid_attributes }
          expect(response).to redirect_to(atendimento)
          expect(flash[:notice]).to eq(I18n.t('atendimento_detalhes.create.notice'))
        end
      end

      context 'com parâmetros inválidos' do
        it 'não cria um novo AtendimentoDetalhe' do
          expect do
            post :create, params: { atendimento_id: atendimento.id, atendimento_detalhe: invalid_attributes }
          end.not_to change(AtendimentoDetalhe, :count)
        end

        it 'retorna status de unprocessable content' do
          post :create, params: { atendimento_id: atendimento.id, atendimento_detalhe: invalid_attributes }
          expect(response).to have_http_status(:unprocessable_content)
        end
      end
    end
  end
end
