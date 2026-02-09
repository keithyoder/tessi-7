# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IpRedesController, type: :controller do
  let(:ponto) { create(:ponto) }
  let(:ip_rede) { create(:ip_rede, ponto: ponto) }
  let(:valid_attributes) do
    {
      rede: '192.168.1.0/24',
      ponto_id: ponto.id
    }
  end
  let(:invalid_attributes) do
    {
      rede: 'invalid',
      ponto_id: nil
    }
  end

  # =============================================================================
  # Authorization Tests
  # =============================================================================

  describe 'GET #index' do
    it_behaves_like 'action authorization',
                    :get,
                    :index,
                    allowed_roles: %i[admin tecnico_n1 tecnico_n2 financeiro_n1 financeiro_n2]
  end

  describe 'GET #show' do
    it_behaves_like 'action authorization',
                    :get,
                    :show,
                    allowed_roles: %i[admin tecnico_n1 tecnico_n2 financeiro_n1 financeiro_n2],
                    params_block: -> { { id: ip_rede.id } }
  end

  describe 'GET #new' do
    it_behaves_like 'action authorization',
                    :get,
                    :new,
                    allowed_roles: %i[admin tecnico_n2]
  end

  describe 'GET #edit' do
    it_behaves_like 'action authorization',
                    :get,
                    :edit,
                    allowed_roles: %i[admin tecnico_n2],
                    params_block: -> { { id: ip_rede.id } }
  end

  describe 'POST #create' do
    it_behaves_like 'action authorization',
                    :post,
                    :create,
                    allowed_roles: %i[admin tecnico_n2],
                    params_block: -> { { ip_rede: valid_attributes } },
                    success_status: :redirect
  end

  describe 'PATCH #update' do
    it_behaves_like 'action authorization',
                    :patch,
                    :update,
                    allowed_roles: %i[admin tecnico_n2],
                    params_block: -> { { id: ip_rede.id, ip_rede: valid_attributes } },
                    success_status: :redirect
  end

  describe 'DELETE #destroy' do
    it_behaves_like 'action authorization',
                    :delete,
                    :destroy,
                    allowed_roles: [:admin],
                    params_block: -> { { id: ip_rede.id } },
                    success_status: :redirect
  end

  # =============================================================================
  # Action Tests (as admin)
  # =============================================================================

  context 'para usuário autorizado' do
    before { sign_in create(:user, :admin) }

    describe 'GET #index' do
      it 'retorna sucesso' do
        get :index
        expect(response).to have_http_status(:ok)
      end

      it 'atribui @ip_redes' do
        ip_rede
        get :index

        ip_redes = controller.instance_variable_get(:@ip_redes)
        expect(ip_redes).to include(ip_rede)
      end

      it 'atribui @q (ransack search)' do
        get :index

        q = controller.instance_variable_get(:@q)
        expect(q).to be_present
      end

      it 'ordena por rede' do
        rede1 = create(:ip_rede, rede: '192.168.2.0/24')
        rede2 = create(:ip_rede, rede: '192.168.1.0/24')

        get :index

        ip_redes = controller.instance_variable_get(:@ip_redes)
        expect(ip_redes.to_a).to eq([rede2, rede1])
      end

      it 'inclui contagem de conexões' do
        ip_rede
        get :index

        ip_redes = controller.instance_variable_get(:@ip_redes)
        expect(ip_redes.first).to respond_to(:conexoes_count)
      end

      context 'com busca ransack' do
        it 'filtra por CIDR' do
          matching = create(:ip_rede, rede: '172.16.0.0/24')
          create(:ip_rede, rede: '192.168.1.0/24')

          get :index, params: { q: { rede_string_cont: '172.16.0' } }

          ip_redes = controller.instance_variable_get(:@ip_redes)
          expect(ip_redes.to_a).to include(matching)
          expect(ip_redes.to_a.count).to eq(1)
        end
      end

      context 'com paginação' do
        before do
          create_list(:ip_rede, 15) # rubocop:disable FactoryBot/ExcessiveCreateList
        end

        it 'pagina os resultados' do
          get :index

          ip_redes = controller.instance_variable_get(:@ip_redes)
          expect(ip_redes).to respond_to(:current_page)
          expect(ip_redes.to_a.count).to be <= 25
        end

        it 'aceita parâmetro de página' do
          get :index, params: { page: 2 }

          ip_redes = controller.instance_variable_get(:@ip_redes)
          expect(response).to have_http_status(:ok)
          expect(ip_redes.current_page).to eq(2)
        end
      end
    end

    describe 'GET #show' do
      it 'retorna sucesso' do
        get :show, params: { id: ip_rede.id }
        expect(response).to have_http_status(:ok)
      end

      it 'atribui @ip_rede' do
        get :show, params: { id: ip_rede.id }

        loaded_ip_rede = controller.instance_variable_get(:@ip_rede)
        expect(loaded_ip_rede).to eq(ip_rede)
      end

      it 'atribui @conexoes' do
        get :show, params: { id: ip_rede.id }

        conexoes = controller.instance_variable_get(:@conexoes)
        expect(conexoes).not_to be_nil
      end

      it 'carrega conexões da rede correta' do
        ip_rede.update!(rede: '192.168.1.0/24')
        conexao_na_rede = create(:conexao, ponto: ponto, ip: '192.168.1.10')
        create(:conexao, ponto: ponto, ip: '10.0.0.1')

        get :show, params: { id: ip_rede.id }

        conexoes = controller.instance_variable_get(:@conexoes)
        expect(conexoes.to_a).to include(conexao_na_rede)
        expect(conexoes.to_a.count).to eq(1)
      end

      it 'ordena conexões por IP' do
        ip_rede.update!(rede: '192.168.1.0/24')
        conexao1 = create(:conexao, ponto: ponto, ip: '192.168.1.20')
        conexao2 = create(:conexao, ponto: ponto, ip: '192.168.1.10')

        get :show, params: { id: ip_rede.id }

        conexoes = controller.instance_variable_get(:@conexoes)
        expect(conexoes.to_a).to eq([conexao2, conexao1])
      end

      context 'quando rede não existe' do
        it 'levanta ActiveRecord::RecordNotFound' do
          expect do
            get :show, params: { id: 999_999 }
          end.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end

    describe 'GET #new' do
      it 'retorna sucesso' do
        get :new
        expect(response).to have_http_status(:ok)
      end

      it 'atribui nova @ip_rede' do
        get :new

        ip_rede = controller.instance_variable_get(:@ip_rede)
        expect(ip_rede).to be_a_new(IpRede)
      end
    end

    describe 'GET #edit' do
      it 'retorna sucesso' do
        get :edit, params: { id: ip_rede.id }
        expect(response).to have_http_status(:ok)
      end

      it 'atribui @ip_rede' do
        get :edit, params: { id: ip_rede.id }

        loaded_ip_rede = controller.instance_variable_get(:@ip_rede)
        expect(loaded_ip_rede).to eq(ip_rede)
      end
    end

    describe 'POST #create' do
      context 'com parâmetros válidos' do
        it 'cria uma nova IpRede' do
          expect do
            post :create, params: { ip_rede: valid_attributes }
          end.to change(IpRede, :count).by(1)
        end

        it 'redireciona para a rede criada' do
          post :create, params: { ip_rede: valid_attributes }
          expect(response).to redirect_to(IpRede.last)
        end

        it 'exibe mensagem de sucesso' do
          post :create, params: { ip_rede: valid_attributes }
          expect(flash[:notice]).to be_present
        end

        it 'associa ao ponto correto' do
          post :create, params: { ip_rede: valid_attributes }
          expect(IpRede.last.ponto).to eq(ponto)
        end

        it 'define atributos corretamente' do
          post :create, params: { ip_rede: valid_attributes }

          created = IpRede.last
          expect(created.cidr.to_s).to eq('192.168.1.0/24')
          expect(created.ponto_id).to eq(ponto.id)
        end
      end

      context 'com parâmetros inválidos' do
        it 'não cria uma nova IpRede' do
          expect do
            post :create, params: { ip_rede: invalid_attributes }
          end.not_to change(IpRede, :count)
        end

        it 'retorna status unprocessable_content' do
          post :create, params: { ip_rede: invalid_attributes }
          expect(response).to have_http_status(:unprocessable_content)
        end

        it 'atribui @ip_rede com erros' do
          post :create, params: { ip_rede: invalid_attributes }

          ip_rede = controller.instance_variable_get(:@ip_rede)
          expect(ip_rede.errors).not_to be_empty
        end
      end
    end

    describe 'PATCH #update' do
      context 'com parâmetros válidos' do
        let(:new_attributes) do
          { rede: '10.0.0.0/24' }
        end

        it 'atualiza a IpRede' do
          patch :update, params: { id: ip_rede.id, ip_rede: new_attributes }
          ip_rede.reload
          expect(ip_rede.cidr.to_s).to eq('10.0.0.0/24')
        end

        it 'redireciona para a rede' do
          patch :update, params: { id: ip_rede.id, ip_rede: new_attributes }
          expect(response).to redirect_to(ip_rede)
        end

        it 'exibe mensagem de sucesso' do
          patch :update, params: { id: ip_rede.id, ip_rede: new_attributes }
          expect(flash[:notice]).to be_present
        end

        it 'permite alterar ponto' do
          novo_ponto = create(:ponto)
          patch :update, params: { id: ip_rede.id, ip_rede: { ponto_id: novo_ponto.id } }

          ip_rede.reload
          expect(ip_rede.ponto).to eq(novo_ponto)
        end
      end

      context 'com parâmetros inválidos' do
        it 'não atualiza a IpRede' do
          original_cidr = ip_rede.cidr.to_s
          patch :update, params: { id: ip_rede.id, ip_rede: invalid_attributes }
          ip_rede.reload
          expect(ip_rede.cidr.to_s).to eq(original_cidr)
        end

        it 'retorna status unprocessable_content' do
          patch :update, params: { id: ip_rede.id, ip_rede: invalid_attributes }
          expect(response).to have_http_status(:unprocessable_content)
        end

        it 'atribui @ip_rede com erros' do
          patch :update, params: { id: ip_rede.id, ip_rede: invalid_attributes }

          loaded_ip_rede = controller.instance_variable_get(:@ip_rede)
          expect(loaded_ip_rede.errors).not_to be_empty
        end
      end
    end

    describe 'DELETE #destroy' do
      it 'destrói a IpRede' do
        ip_rede # Create it first
        expect do
          delete :destroy, params: { id: ip_rede.id }
        end.to change(IpRede, :count).by(-1)
      end

      it 'redireciona para o índice' do
        delete :destroy, params: { id: ip_rede.id }
        expect(response).to redirect_to(ip_redes_path)
      end

      it 'exibe mensagem de sucesso' do
        delete :destroy, params: { id: ip_rede.id }
        expect(flash[:notice]).to be_present
      end
    end
  end

  # =============================================================================
  # Private Methods
  # =============================================================================

  describe 'private methods' do
    before { sign_in create(:user, :admin) }

    describe '#ip_rede_params' do
      it 'permite apenas parâmetros permitidos' do
        allowed_params = {
          rede: '192.168.1.0/24',
          ponto_id: ponto.id,
          subnet: '255.255.255.0'
        }

        post :create, params: { ip_rede: allowed_params }

        expect(response).to have_http_status(:redirect)
      end

      it 'filtra parâmetros não permitidos' do
        params_with_extra = valid_attributes.merge(
          id: 999,
          created_at: Time.current,
          updated_at: Time.current
        )

        post :create, params: { ip_rede: params_with_extra }

        created = IpRede.last
        expect(created.id).not_to eq(999)
      end
    end
  end
end
