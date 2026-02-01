# spec/controllers/nfcom_notas_controller_spec.rb
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NfcomNotasController, type: :controller do
  describe 'GET #index' do
    it_behaves_like 'action authorization', :get, :index,
                    allowed_roles: %i[admin financeiro_n2],
                    denied_roles: %i[financeiro_n1 tecnico_n1 tecnico_n2]

    context 'para usuário autorizado' do
      let!(:nota_antiga) { create(:nfcom_nota, competencia: 13.months.ago.beginning_of_month) }
      let!(:nota_recente) do
        create(:nfcom_nota,
               competencia: 1.month.ago.beginning_of_month,
               status: 'authorized',
               valor_total: 100.00)
      end

      before do
        sign_in create(:user, :admin)
        create(:nfcom_nota,
               competencia: 1.month.ago.beginning_of_month,
               status: 'rejected',
               valor_total: 50.00)
      end

      it 'retorna sucesso' do
        get :index
        expect(response).to have_http_status(:ok)
      end

      it 'agrupa notas por competência dos últimos 12 meses' do
        get :index
        competencias = controller.instance_variable_get(:@competencias_com_count)

        expect(competencias).to be_a(Hash)
        expect(competencias.keys).not_to include(nota_antiga.competencia)
        expect(competencias.keys).to include(nota_recente.competencia)
        expect(competencias[nota_recente.competencia]).to eq(2)
      end

      it 'calcula contagens de status por competência' do
        get :index
        status_counts = controller.instance_variable_get(:@status_counts_by_competencia)

        expect(status_counts).to be_a(Hash)
        expect(status_counts[[nota_recente.competencia, 'authorized']]).to eq(1)
        expect(status_counts[[nota_recente.competencia, 'rejected']]).to eq(1)
      end

      it 'calcula valores totais autorizados por competência' do
        get :index
        authorized_values = controller.instance_variable_get(:@authorized_values_by_competencia)

        expect(authorized_values).to be_a(Hash)
        expect(authorized_values[nota_recente.competencia]).to eq(100.00)
      end
    end
  end

  describe 'GET #competencia' do
    let(:mes) { '2026-01' }
    let!(:nota_mes) { create(:nfcom_nota, competencia: "#{mes}-01", numero: 1) }
    let!(:nota_mes_2) { create(:nfcom_nota, competencia: "#{mes}-01", numero: 2) }

    before do
      create(:nfcom_nota, competencia: '2026-02-01')
    end

    it_behaves_like 'action authorization', :get, :competencia,
                    allowed_roles: %i[admin financeiro_n2],
                    denied_roles: %i[financeiro_n1 tecnico_n1 tecnico_n2],
                    params_block: -> { { mes: mes } }

    context 'para formato HTML' do
      before { sign_in create(:user, :admin) }

      it 'filtra notas pela competência' do
        get :competencia, params: { mes: mes }

        notas = controller.instance_variable_get(:@notas)
        expect(notas.map(&:id)).to contain_exactly(nota_mes.id, nota_mes_2.id)
      end

      it 'ordena notas por número' do
        get :competencia, params: { mes: mes }

        notas = controller.instance_variable_get(:@notas)
        expect(notas.first.numero).to eq(1)
        expect(notas.last.numero).to eq(2)
      end

      it 'calcula estatísticas totais' do
        get :competencia, params: { mes: mes }

        stats = controller.instance_variable_get(:@total_stats)
        expect(stats).to be_a(Hash)
        expect(stats.values.sum).to eq(2)
      end

      it 'pagina resultados' do
        get :competencia, params: { mes: mes, page: 1 }

        notas = controller.instance_variable_get(:@notas)
        expect(notas).to respond_to(:current_page)
      end

      it 'permite busca por ransack' do
        get :competencia, params: { mes: mes, q: { numero_eq: 1 } }

        notas = controller.instance_variable_get(:@notas)
        expect(notas.map(&:id)).to contain_exactly(nota_mes.id)
      end
    end

    context 'para formato CSV' do
      before { sign_in create(:user, :admin) }

      it 'gera arquivo CSV' do
        get :competencia, params: { mes: mes }, format: :csv

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('text/csv')
        expect(response.headers['Content-Disposition']).to include("nfcom_competencia_#{mes}.csv")
      end

      it 'inclui cabeçalhos corretos' do
        get :competencia, params: { mes: mes }, format: :csv

        csv_data = CSV.parse(response.body, headers: true)
        expect(csv_data.headers).to include('Série', 'Número', 'Cliente', 'Status', 'Valor Total')
      end

      it 'inclui todas as notas filtradas' do
        get :competencia, params: { mes: mes }, format: :csv

        csv_data = CSV.parse(response.body, headers: true)
        expect(csv_data.count).to eq(2)
      end
    end

    context 'para formato ZIP' do
      before { sign_in create(:user, :admin) }

      it 'gera arquivo ZIP' do
        allow(Nfcom::GeradorXmlZipService).to receive(:new).and_return(
          double(generate: StringIO.new('fake zip data'))
        )

        get :competencia, params: { mes: mes }, format: :zip

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/zip')
        expect(response.headers['Content-Disposition']).to include("nfcom_competencia_#{mes}.zip")
      end
    end
  end

  describe 'GET #show' do
    let(:nota) { create(:nfcom_nota, xml_autorizado: '<xml>test</xml>') }

    # NOTE: HTML format redirects, so we test authorization separately for each format
    context 'para authorization' do
      context 'quando não autenticado' do
        it 'redireciona para login' do
          get :show, params: { id: nota.id }
          expect(response).to redirect_to(new_user_session_path)
        end
      end

      context 'quando autenticado' do
        %i[admin financeiro_n2 financeiro_n1 tecnico_n1 tecnico_n2].each do |role|
          context "para #{role}" do
            before { sign_in create(:user, role) }

            it 'permite acesso' do
              get :show, params: { id: nota.id }
              expect(response).to have_http_status(:redirect) # Redirects to PDF
            end
          end
        end
      end
    end

    context 'para formato HTML' do
      before { sign_in create(:user, :admin) }

      it 'redireciona para formato PDF' do
        get :show, params: { id: nota.id }
        expect(response).to redirect_to(nfcom_nota_path(nota, format: :pdf))
      end
    end

    context 'para formato PDF' do
      before { sign_in create(:user, :admin) }

      it 'gera PDF da nota' do
        fake_pdf = 'fake pdf content'
        allow(Nfcom::GeradorDanfePdfService).to receive(:new).and_return(
          double(generate: fake_pdf)
        )

        get :show, params: { id: nota.id }, format: :pdf

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/pdf')
        expect(response.body).to eq(fake_pdf)
      end

      it 'define nome do arquivo corretamente' do
        allow(Nfcom::GeradorDanfePdfService).to receive(:new).and_return(
          double(generate: 'fake pdf')
        )

        get :show, params: { id: nota.id }, format: :pdf

        expect(response.headers['Content-Disposition']).to include(
          "nfcom_#{nota.numero}_serie_#{nota.serie}.pdf"
        )
      end

      it 'trata erros de XML' do
        allow(Nfcom::GeradorDanfePdfService).to receive(:new).and_raise(
          Nfcom::Errors::XmlError.new('XML inválido')
        )

        get :show, params: { id: nota.id }, format: :pdf

        expect(response).to redirect_to(fatura_path(nota.fatura))
        expect(flash[:error]).to eq('XML inválido')
      end

      it 'trata erros genéricos' do
        allow(Nfcom::GeradorDanfePdfService).to receive(:new).and_raise(
          StandardError.new('Erro desconhecido')
        )

        get :show, params: { id: nota.id }, format: :pdf

        expect(response).to redirect_to(fatura_path(nota.fatura))
        expect(flash[:error]).to be_present
      end
    end

    context 'para formato XML' do
      before { sign_in create(:user, :admin) }

      it 'retorna XML autorizado' do
        get :show, params: { id: nota.id }, format: :xml

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/xml')
        expect(response.body).to eq(nota.xml_autorizado)
      end

      it 'define nome do arquivo corretamente' do
        get :show, params: { id: nota.id }, format: :xml

        expect(response.headers['Content-Disposition']).to include(
          "nfcom_#{nota.numero}_serie_#{nota.serie}.xml"
        )
      end

      context 'quando nota não tem XML autorizado' do
        let(:nota_sem_xml) { create(:nfcom_nota, xml_autorizado: nil) }

        it 'redireciona com erro' do
          get :show, params: { id: nota_sem_xml.id }, format: :xml

          expect(response).to redirect_to(fatura_path(nota_sem_xml.fatura))
          expect(flash[:error]).to be_present
        end
      end
    end

    context 'quando nota não existe' do
      before { sign_in create(:user, :admin) }

      it 'levanta ActiveRecord::RecordNotFound' do
        expect do
          get :show, params: { id: 999_999 }
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'POST #gerar_lote' do
    let(:data_inicio) { Date.new(2026, 1, 1) }
    let(:data_fim) { Date.new(2026, 1, 31) }

    it_behaves_like 'action authorization', :post, :gerar_lote,
                    allowed_roles: %i[admin financeiro_n2],
                    denied_roles: %i[financeiro_n1 tecnico_n1 tecnico_n2],
                    params_block: -> { { data_inicio: data_inicio.to_s, data_fim: data_fim.to_s } },
                    success_status: :redirect

    context 'para usuário autorizado' do
      before do
        sign_in create(:user, :admin)
        allow(GerarNotasJob).to receive(:perform_later)
      end

      it 'enfileira job com parâmetros corretos' do
        post :gerar_lote, params: { data_inicio: data_inicio.to_s, data_fim: data_fim.to_s }

        expect(GerarNotasJob).to have_received(:perform_later).with(
          data_inicio: data_inicio,
          data_fim: data_fim
        )
      end

      it 'redireciona para index com mensagem de sucesso' do
        post :gerar_lote, params: { data_inicio: data_inicio.to_s, data_fim: data_fim.to_s }

        expect(response).to redirect_to(nfcom_notas_path)
        expect(flash[:notice]).to be_present
      end
    end

    context 'para validações de data' do
      before { sign_in create(:user, :admin) }

      it 'rejeita data_inicio posterior a data_fim' do
        post :gerar_lote, params: { data_inicio: data_fim.to_s, data_fim: data_inicio.to_s }

        expect(response).to redirect_to(nfcom_notas_path)
        expect(flash[:error]).to be_present
      end

      it 'trata datas inválidas' do
        post :gerar_lote, params: { data_inicio: 'invalid', data_fim: data_fim.to_s }

        expect(response).to redirect_to(nfcom_notas_path)
        expect(flash[:error]).to be_present
      end
    end

    context 'para tratamento de erros' do
      before do
        sign_in create(:user, :admin)
        allow(GerarNotasJob).to receive(:perform_later).and_raise(StandardError.new('Job error'))
      end

      it 'captura e trata erros do job' do
        post :gerar_lote, params: { data_inicio: data_inicio.to_s, data_fim: data_fim.to_s }

        expect(response).to redirect_to(nfcom_notas_path)
        expect(flash[:error]).to be_present
      end
    end
  end

  describe 'private methods' do
    let(:user) { create(:user, :admin) }

    before { sign_in user }

    describe '#permit_search_params' do
      it 'permite apenas parâmetros permitidos no ransack' do
        allowed_params = {
          fatura_contrato_pessoa_nome_cont: 'João',
          numero_eq: '123',
          serie_eq: '1',
          status_eq: 'authorized'
        }

        get :competencia, params: { mes: '2026-01', q: allowed_params }

        expect(response).to have_http_status(:ok)
      end
    end

    describe '#total_stats_for' do
      let(:mes) { '2026-01' }
      let(:competencia) { Date.parse("#{mes}-01") }

      before do
        create(:nfcom_nota, status: 'authorized', competencia: competencia)
        create(:nfcom_nota, status: 'rejected', competencia: competencia)
        create(:nfcom_nota, status: 'authorized', competencia: competencia)
      end

      it 'retorna contagem agrupada por status' do
        get :competencia, params: { mes: mes }

        stats = controller.instance_variable_get(:@total_stats)
        expect(stats).to be_a(Hash)
        expect(stats['authorized']).to eq(2)
        expect(stats['rejected']).to eq(1)
      end

      it 'não inclui notas de outras competências' do
        create(:nfcom_nota, status: 'authorized', competencia: Date.parse('2026-02-01'))

        get :competencia, params: { mes: mes }

        stats = controller.instance_variable_get(:@total_stats)
        expect(stats['authorized']).to eq(2) # Only the 2 from this month
      end
    end
  end
end
