# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AtendimentosController, type: :controller do
  let!(:user) { create(:user, email: 'test_user@example.com', role: :financeiro_n1) }
  let!(:other_user) { create(:user, email: 'other_user@example.com', role: :financeiro_n1) }
  let!(:pessoa) { any_pessoa_fisica }
  let!(:classificacao) { create(:classificacao) }
  let!(:new_classificacao) { create(:classificacao) }

  let!(:atendimento) do
    create(:atendimento,
           responsavel: user,
           pessoa: pessoa,
           classificacao: classificacao,
           fechamento: nil)
  end

  let!(:other_user_atendimento) do
    create(:atendimento,
           responsavel: other_user,
           pessoa: pessoa,
           classificacao: classificacao)
  end

  before { sign_in user }

  describe 'GET #index' do
    it 'retorna uma resposta bem-sucedida' do
      get :index
      expect(response).to be_successful
    end

    it 'retorna status ok' do
      get :index
      expect(response).to have_http_status(:ok)
    end

    context 'com filtro de abertos' do
      it 'retorna resposta bem-sucedida' do
        get :index, params: { abertos: true }
        expect(response).to be_successful
      end
    end

    context 'com filtro de fechados' do
      it 'retorna resposta bem-sucedida' do
        get :index, params: { fechados: true }
        expect(response).to be_successful
      end
    end

    context 'com filtro meus' do
      it 'retorna resposta bem-sucedida' do
        get :index, params: { meus: true }
        expect(response).to be_successful
      end
    end
  end

  describe 'GET #show' do
    it 'retorna uma resposta bem-sucedida' do
      get :show, params: { id: atendimento.id }
      expect(response).to be_successful
    end

    it 'retorna status ok' do
      get :show, params: { id: atendimento.id }
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET #new' do
    it 'retorna uma resposta bem-sucedida' do
      get :new
      expect(response).to be_successful
    end

    it 'retorna status ok' do
      get :new
      expect(response).to have_http_status(:ok)
    end

    context 'com parâmetro pessoa_id' do
      it 'retorna resposta bem-sucedida com pessoa_id' do
        get :new, params: { pessoa_id: pessoa.id }
        expect(response).to be_successful
      end
    end
  end

  describe 'GET #edit' do
    it 'retorna uma resposta bem-sucedida' do
      get :edit, params: { id: atendimento.id }
      expect(response).to be_successful
    end

    it 'retorna status ok' do
      get :edit, params: { id: atendimento.id }
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST #create' do
    let(:valid_params) do
      {
        atendimento: {
          pessoa_id: pessoa.id,
          classificacao_id: classificacao.id,
          responsavel_id: user.id,
          detalhe_tipo: 'Presencial',
          detalhe_descricao: 'Cliente reportou problema na conexão'
        }
      }
    end

    context 'com parâmetros válidos' do
      it 'cria um novo atendimento' do
        expect do
          post :create, params: valid_params
        end.to change(Atendimento, :count).by(1)
      end

      it 'cria um novo detalhe' do
        expect do
          post :create, params: valid_params
        end.to change(AtendimentoDetalhe, :count).by(1)
      end

      it 'redireciona para o atendimento criado' do
        post :create, params: valid_params
        expect(response).to redirect_to(Atendimento.last)
      end

      it 'define a mensagem de sucesso' do
        post :create, params: valid_params
        expect(flash[:notice]).to eq(I18n.t('atendimentos.create.notice'))
      end
    end

    context 'com parâmetros inválidos do atendimento' do
      let(:invalid_params) do
        {
          atendimento: {
            pessoa_id: nil,
            classificacao_id: classificacao.id,
            responsavel_id: user.id,
            detalhe_tipo: 'Presencial',
            detalhe_descricao: 'Descrição'
          }
        }
      end

      it 'não cria um novo atendimento' do
        expect do
          post :create, params: invalid_params
        end.not_to change(Atendimento, :count)
      end

      it 'retorna status unprocessable_content' do
        post :create, params: invalid_params
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe 'PATCH #update' do
    context 'com parâmetros válidos' do
      it 'atualiza o atendimento' do
        patch :update, params: { id: atendimento.id, atendimento: { classificacao_id: new_classificacao.id } }
        atendimento.reload
        expect(atendimento.classificacao).to eq(new_classificacao)
      end
    end

    context 'com parâmetros inválidos' do
      it 'não atualiza o atendimento' do
        original_pessoa = atendimento.pessoa
        patch :update, params: { id: atendimento.id, atendimento: { pessoa_id: nil } }
        atendimento.reload
        expect(atendimento.pessoa).to eq(original_pessoa)
      end
    end
  end

  describe 'DELETE #destroy' do
    before { sign_in admin_user }

    it 'remove o atendimento' do
      expect do
        delete :destroy, params: { id: atendimento.id }
      end.to change(Atendimento, :count).by(-1)
    end
  end

  describe 'PATCH #encerrar' do
    context 'quando o usuário pode encerrar' do
      it 'fecha o atendimento' do
        patch :encerrar, params: { id: atendimento.id }
        atendimento.reload
        expect(atendimento.fechamento).to be_present
      end
    end
  end

  describe 'autorização' do
    context 'com atendimento de outro usuário' do
      it 'permite visualizar o atendimento' do
        get :show, params: { id: other_user_atendimento.id }
        expect(response).to have_http_status(:ok)
      end

      it 'não permite encerrar o atendimento' do
        expect do
          patch :encerrar, params: { id: other_user_atendimento.id }
        end.not_to(change { other_user_atendimento.reload.fechamento })

        expect(response).to redirect_to(root_path)
      end

      it 'não permite excluir o próprio atendimento' do
        expect do
          delete :destroy, params: { id: atendimento.id }
        end.not_to change(Atendimento, :count)

        expect(response).to redirect_to(root_path)
      end
    end

    context 'com usuário administrador' do
      before { sign_in admin_user }

      it 'permite excluir o atendimento' do
        expect do
          delete :destroy, params: { id: atendimento.id }
        end.to change(Atendimento, :count).by(-1)
      end
    end
  end
end
