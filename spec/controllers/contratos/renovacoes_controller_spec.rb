# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contratos::RenovacoesController, type: :controller do
  let(:contrato) do
    create(
      :contrato,
      adesao: Date.new(2026, 1, 10),
      prazo_meses: 12,
      pagamento_perfil: any_pagamento_perfil
    )
  end

  let(:service) { instance_double(Contratos::RenovarService) }

  shared_examples 'não autorizado a renovar contrato' do
    it 'lança CanCan::AccessDenied' do
      expect do
        post :create, params: { id: contrato.id, meses_por_fatura: 1 }
      end.to raise_error(CanCan::AccessDenied)
    end
  end

  describe 'POST #create' do
    context 'quando administrador' do
      before do
        sign_in admin_user
        allow(Contratos::RenovarService).to receive(:new)
          .with(contrato: contrato, meses_por_fatura: anything)
          .and_return(service)
      end

      it 'chama RenovarService e redireciona com aviso quando faturas são geradas' do
        allow(service).to receive(:call).and_return([instance_double(Fatura), instance_double(Fatura)])

        post :create, params: { id: contrato.id, meses_por_fatura: 3 }

        expect(response).to redirect_to(contrato)
        expect(flash[:notice]).to eq('2 faturas geradas com sucesso.')
      end

      it 'redireciona com aviso quando não há meses restantes' do
        allow(service).to receive(:call).and_return([])

        post :create, params: { id: contrato.id }

        expect(response).to redirect_to(contrato)
        expect(flash[:notice]).to eq('Não há meses restantes para renovar o contrato.')
      end

      it 'redireciona com alerta quando ocorre um erro no serviço' do
        allow(service).to receive(:call).and_raise(StandardError, 'Algo deu errado')

        post :create, params: { id: contrato.id }

        expect(response).to redirect_to(contrato)
        expect(flash[:alert]).to eq('Erro ao renovar contrato: Algo deu errado')
      end
    end

    context 'quando financeiro nível 1' do
      let(:financeiro_n1) { create(:user, role: :financeiro_n1) }

      before do
        sign_in financeiro_n1
        allow(Contratos::RenovarService).to receive(:new)
          .with(contrato: contrato, meses_por_fatura: anything)
          .and_return(service)
      end

      it 'pode renovar o contrato' do
        allow(service).to receive(:call).and_return([instance_double(Fatura)])

        post :create, params: { id: contrato.id, meses_por_fatura: 1 }

        expect(response).to redirect_to(contrato)
        expect(flash[:notice]).to eq('1 fatura gerada com sucesso.')
      end
    end

    context 'quando financeiro nível 2' do
      let(:financeiro_n2) { create(:user, role: :financeiro_n2) }

      before do
        sign_in financeiro_n2
        allow(Contratos::RenovarService).to receive(:new)
          .with(contrato: contrato, meses_por_fatura: anything)
          .and_return(service)
      end

      it 'pode renovar o contrato' do
        allow(service).to receive(:call).and_return([instance_double(Fatura)])

        post :create, params: { id: contrato.id, meses_por_fatura: 1 }

        expect(response).to redirect_to(contrato)
        expect(flash[:notice]).to eq('1 fatura gerada com sucesso.')
      end
    end

    # context 'quando técnico nível 1 (não autorizado)' do
    #   let(:tecnico_n1) { create(:user, role: :tecnico_n1) }
    #   before { sign_in tecnico_n1 }

    #   include_examples 'não autorizado a renovar contrato'
    # end
  end
end
