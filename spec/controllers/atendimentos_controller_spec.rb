# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AtendimentosController, type: :controller do
  let!(:admin_user) { create(:user, :admin) }
  let!(:user) { create(:user, :financeiro_n1) }
  let!(:other_user) { create(:user, :financeiro_n2) }

  let!(:pessoa) { create(:pessoa, :fisica) }
  let!(:classificacao) { create(:classificacao) }
  let!(:new_classificacao) { create(:classificacao) }

  let!(:atendimento) do
    create(:atendimento,
           pessoa: pessoa,
           classificacao: classificacao,
           responsavel: user,
           fechamento: nil)
  end

  let!(:other_user_atendimento) do
    create(:atendimento,
           pessoa: pessoa,
           classificacao: classificacao,
           responsavel: other_user,
           fechamento: nil)
  end

  let!(:closed_atendimento) do
    create(:atendimento,
           pessoa: pessoa,
           classificacao: classificacao,
           responsavel: user,
           fechamento: 1.day.ago)
  end

  describe 'GET #index' do
    # All authenticated users can read
    it_behaves_like 'action authorization', :get, :index,
                    allowed_roles: %i[admin financeiro_n2 financeiro_n1 tecnico_n1 tecnico_n2],
                    denied_roles: []

    context 'para usuário autenticado' do
      before { sign_in user }

      it 'retorna uma resposta bem-sucedida' do
        get :index
        expect(response).to be_successful
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
  end

  describe 'GET #show' do
    it_behaves_like 'action authorization', :get, :show,
                    allowed_roles: %i[admin financeiro_n2 financeiro_n1 tecnico_n1 tecnico_n2],
                    denied_roles: [],
                    params_block: -> { { id: atendimento.id } }

    context 'para usuário autenticado' do
      before { sign_in user }

      it 'retorna uma resposta bem-sucedida' do
        get :show, params: { id: atendimento.id }
        expect(response).to be_successful
      end

      it 'permite visualizar atendimento de outro usuário' do
        get :show, params: { id: other_user_atendimento.id }
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'GET #new' do
    it_behaves_like 'action authorization', :get, :new,
                    allowed_roles: %i[admin financeiro_n2 financeiro_n1 tecnico_n1 tecnico_n2],
                    denied_roles: []

    context 'para usuário autenticado' do
      before { sign_in user }

      it 'retorna uma resposta bem-sucedida' do
        get :new
        expect(response).to be_successful
      end

      context 'com parâmetro pessoa_id' do
        it 'retorna resposta bem-sucedida com pessoa_id' do
          get :new, params: { pessoa_id: pessoa.id }
          expect(response).to be_successful
        end
      end
    end
  end

  describe 'GET #edit' do
    it_behaves_like 'action authorization', :get, :edit,
                    allowed_roles: %i[admin financeiro_n2 financeiro_n1 tecnico_n1 tecnico_n2],
                    denied_roles: [],
                    params_block: -> { { id: atendimento.id } }

    context 'para usuário autenticado' do
      before { sign_in user }

      it 'retorna uma resposta bem-sucedida' do
        get :edit, params: { id: atendimento.id }
        expect(response).to be_successful
      end
    end
  end

  describe 'POST #create' do
    it_behaves_like 'action authorization', :post, :create,
                    allowed_roles: %i[admin financeiro_n2 financeiro_n1 tecnico_n1 tecnico_n2],
                    denied_roles: [],
                    params_block: lambda {
                      {
                        atendimento: {
                          pessoa_id: pessoa.id,
                          classificacao_id: classificacao.id,
                          responsavel_id: user.id,
                          detalhe_tipo: 'Presencial',
                          detalhe_descricao: 'Cliente reportou problema na conexão'
                        }
                      }
                    },
                    success_status: :redirect

    context 'para usuário autenticado' do
      before { sign_in user }

      context 'com parâmetros válidos' do
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
          expect(flash[:notice]).to be_present
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
  end

  describe 'PATCH #update' do
    it_behaves_like 'action authorization', :patch, :update,
                    allowed_roles: %i[admin financeiro_n2 financeiro_n1 tecnico_n1 tecnico_n2],
                    denied_roles: [],
                    params_block: -> { { id: atendimento.id, atendimento: { classificacao_id: new_classificacao.id } } },
                    success_status: :redirect

    context 'para usuário autenticado' do
      before { sign_in user }

      context 'com parâmetros válidos' do
        it 'atualiza o atendimento' do
          patch :update, params: { id: atendimento.id, atendimento: { classificacao_id: new_classificacao.id } }
          atendimento.reload
          expect(atendimento.classificacao).to eq(new_classificacao)
        end

        it 'redireciona para o atendimento' do
          patch :update, params: { id: atendimento.id, atendimento: { classificacao_id: new_classificacao.id } }
          expect(response).to redirect_to(atendimento)
        end
      end

      context 'com parâmetros inválidos' do
        it 'não atualiza o atendimento' do
          original_pessoa = atendimento.pessoa
          patch :update, params: { id: atendimento.id, atendimento: { pessoa_id: nil } }
          atendimento.reload
          expect(atendimento.pessoa).to eq(original_pessoa)
        end

        it 'retorna status unprocessable_content' do
          patch :update, params: { id: atendimento.id, atendimento: { pessoa_id: nil } }
          expect(response).to have_http_status(:unprocessable_content)
        end
      end
    end
  end

  describe 'DELETE #destroy' do
    # Only admin can destroy
    it_behaves_like 'action authorization', :delete, :destroy,
                    allowed_roles: %i[admin],
                    denied_roles: %i[financeiro_n2 financeiro_n1 tecnico_n1 tecnico_n2],
                    params_block: -> { { id: atendimento.id } },
                    success_status: :redirect

    context 'para usuário administrador' do
      before { sign_in admin_user }

      it 'remove o atendimento' do
        # Create a new atendimento for this test to avoid conflicts with authorization tests
        atendimento_to_delete = create(:atendimento, pessoa: pessoa, classificacao: classificacao, responsavel: user)

        expect do
          delete :destroy, params: { id: atendimento_to_delete.id }
        end.to change(Atendimento, :count).by(-1)
      end

      it 'redireciona para index' do
        delete :destroy, params: { id: atendimento.id }
        expect(response).to redirect_to(atendimentos_path)
      end
    end
  end

  describe 'PATCH #encerrar' do
    context 'quando não autenticado' do
      it 'redireciona para login' do
        patch :encerrar, params: { id: atendimento.id }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'quando o usuário pode encerrar (próprio atendimento aberto)' do
      before { sign_in user }

      it 'fecha o atendimento' do
        patch :encerrar, params: { id: atendimento.id }
        atendimento.reload
        expect(atendimento.fechamento).to be_present
      end

      it 'redireciona para o atendimento' do
        patch :encerrar, params: { id: atendimento.id }
        expect(response).to redirect_to(atendimento)
      end
    end

    context 'quando o usuário não pode encerrar' do
      before { sign_in user }

      it 'não permite encerrar atendimento de outro usuário' do
        expect do
          patch :encerrar, params: { id: other_user_atendimento.id }
        end.not_to(change { other_user_atendimento.reload.fechamento })

        expect(response).to redirect_to(root_path)
      end

      it 'não permite encerrar atendimento já fechado' do
        original_fechamento = closed_atendimento.fechamento

        patch :encerrar, params: { id: closed_atendimento.id }

        closed_atendimento.reload
        expect(closed_atendimento.fechamento).to eq(original_fechamento)
        expect(response).to redirect_to(root_path)
      end
    end

    context 'para administrador' do
      before { sign_in admin_user }

      it 'permite encerrar qualquer atendimento aberto' do
        patch :encerrar, params: { id: other_user_atendimento.id }
        other_user_atendimento.reload
        expect(other_user_atendimento.fechamento).to be_present
      end

      it 'não permite encerrar atendimento já fechado' do
        original_fechamento = closed_atendimento.fechamento

        patch :encerrar, params: { id: closed_atendimento.id }

        closed_atendimento.reload
        expect(closed_atendimento.fechamento).to eq(original_fechamento)
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
