# frozen_string_literal: true

# == Route Map
#

Rails.application.routes.draw do # rubocop:disable Metrics/BlockLength
  # Root and Welcome
  root 'welcome#index'
  get 'welcome/index'

  # Authentication
  devise_for :users, controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations'
  }

  # Settings and Configuration
  resources :settings
  resources :token

  # Geographic Resources
  resources :estados, only: %i[index show edit update]
  resources :cidades do
    get :sici, on: :collection
  end
  resources :bairros
  resources :logradouros

  # Network Infrastructure
  resources :servidores do
    get :backup, on: :member
    get :backups, on: :collection
    get :mapa, on: :member
  end
  resources :pontos do
    get :snmp, on: :collection
  end
  resources :ip_redes
  resources :fibra_redes
  resources :fibra_caixas

  # Customer Management
  resources :pessoas do
    get :autocomplete_logradouro_nome, on: :collection
  end
  resources :conexoes do
    get :suspenso, on: :collection
    get :integrar, on: :collection
  end
  resources :equipamentos

  # Plans and Services
  resources :planos
  resources :plano_enviar_atributos
  resources :plano_verificar_atributos

  # Contracts and Billing
  resources :contratos do
    get :boletos, on: :member
    get :churn, on: :collection
    get :assinatura, on: :member
    get :pendencias, on: :collection
    get :trocado, on: :member
    resource :termo, only: %i[show create], module: :contratos

    member do
      post :renovacao, to: 'contratos/renovacoes#create'
    end

    resources :pix_automatico, only: %i[new create index]
  end
  patch '/contratos/:id/assinatura' => 'contratos#update_assinatura'

  resources :faturas do
    get :liquidacao, on: :member
    get :boleto, on: :member
    get :estornar, on: :member
    get :cancelar, on: :member
    get :gerar_nf, on: :member
  end
  resources :liquidacoes

  resources :pagamento_perfis do
    get 'remessa/:sequencia', action: :remessa, as: :remessa, on: :member
  end
  resources :retornos

  resources :nf21s, only: %i[show]
  resources :nf21s do
    get 'competencia/:mes', action: :competencia, as: :competencia, on: :collection
  end
  resources :nfcom_notas, only: [:show]

  # Support and Service Orders
  resources :atendimentos do
    patch :encerrar, on: :member
  end
  resources :atendimento_detalhes, only: %i[new create index]
  resources :os do
    get :impressao, on: :member
  end
  resources :classificacoes
  resources :clasificacoes
  resources :excecoes

  # SAC
  get 'sac/inadimplencia'
  get 'sac/suspensao'

  # Viability
  resources :viablidades, only: %i[new create show]

  # Webhooks
  post '/webhooks/:token' => 'webhook_eventos#create'
end
