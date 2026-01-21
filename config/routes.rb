# frozen_string_literal: true

# == Route Map
#

Rails.application.routes.draw do # rubocop:disable Metrics/BlockLength
  resources :equipamentos
  get 'sac/inadimplencia'
  get 'sac/suspensao'
  resources :atendimento_detalhes, only: %i[new create index]
  resources :atendimentos do
    get :encerrar, on: :member
  end
  resources :os do
    get :impressao, on: :member
  end
  resources :classificacoes
  resources :clasificacoes
  resources :excecoes
  resources :ip_redes
  resources :nf21s, only: %i[show]
  resources :nf21s do
    get 'competencia/:mes', action: :competencia, as: :competencia, on: :collection
  end
  resources :fibra_caixas
  resources :fibra_redes
  resources :retornos
  resources :pagamento_perfis do
    get 'remessa/:sequencia', action: :remessa, as: :remessa, on: :member
  end
  resources :liquidacoes
  resources :faturas do
    get :liquidacao, on: :member
    get :boleto, on: :member
    get :estornar, on: :member
    get :cancelar, on: :member
    get :gerar_nf, on: :member
  end
  patch '/contratos/:id/assinatura' => 'contratos#update_assinatura'
  resources :contratos do
    get :boletos, on: :member
    get :termo, on: :member
    get :churn, on: :collection
    get :assinatura, on: :member
    get :autentique, on: :member
    get :pendencias, on: :collection
    get :trocado, on: :member

    member do
      post :renovacao, to: 'contratos/renovacoes#create'
    end

    resources :pix_automatico, only: %i[new create index]
  end
  resources :conexoes do
    get :suspenso, on: :collection
    get :integrar, on: :collection
  end
  resources :nfcom_notas, only: [:show] 
  resources :pessoas do
    get :autocomplete_logradouro_nome, on: :collection
  end
  resources :plano_enviar_atributos
  resources :plano_verificar_atributos
  resources :pontos do
    get :snmp, on: :collection
  end
  resources :planos
  resources :servidores do
    get :backup, on: :member
    get :backups, on: :collection
    get :mapa, on: :member
  end
  resources :logradouros
  resources :bairros
  resources :cidades do
    get :sici, on: :collection
  end
  devise_for :users, controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations'
  }
  resources :estados, only: %i[index show edit update]
  resources :token
  resources :settings
  resources :viablidades, only: %i[new create show]
  post '/webhooks/:token' => 'webhook_eventos#create'
  get 'welcome/index'
  root 'welcome#index'
end
