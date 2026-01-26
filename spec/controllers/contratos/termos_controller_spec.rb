# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contratos::TermosController, type: :controller do
  let(:contrato) { create(:contrato) }
  let(:user)     { create(:user, role: :financeiro_n2) }
  let(:service)  { instance_spy(Contratos::TermoService) }

  before do
    sign_in user

    allow(Contratos::TermoService)
      .to receive(:new)
      .with(contrato)
      .and_return(service)
  end

  describe 'GET #show' do
    let(:pdf_data) { '%PDF fake' }

    before do
      allow(service).to receive(:gerar_pdf).and_return(pdf_data)
    end

    it 'returns a PDF inline' do
      get :show, params: { contrato_id: contrato.id }

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq 'application/pdf'
      expect(response.body).to eq pdf_data
    end
  end

  describe 'POST #create' do
    before do
      allow(service).to receive(:enviar_para_assinatura)
    end

    it 'calls the TermoService' do
      post :create, params: { contrato_id: contrato.id }

      expect(service).to have_received(:enviar_para_assinatura)
    end

    it 'redirects to contrato' do
      post :create, params: { contrato_id: contrato.id }

      expect(response).to redirect_to(contrato)
    end
  end

  context 'when user is tecnico_n2' do
    let(:user) { create(:user, role: :tecnico_n2) }

    before { sign_in user }

    it 'is forbidden' do
      post :create, params: { contrato_id: contrato.id }

      expect(response).to redirect_to(root_path)
    end
  end
end
