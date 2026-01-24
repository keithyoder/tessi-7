# frozen_string_literal: true

# == Schema Information
#
# Table name: planos
#
#  id             :bigint           not null, primary key
#  ativo          :boolean          default(TRUE)
#  burst          :boolean
#  desconto       :decimal(8, 2)
#  download       :integer
#  mensalidade    :decimal(8, 2)
#  nome           :string
#  upload         :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  gerencianet_id :integer
#
# Indexes
#
#  index_planos_on_nome  (nome) UNIQUE
#
require 'csv'

class Plano < ApplicationRecord
  has_many :plano_verificar_atributos, dependent: :destroy
  has_many :plano_enviar_atributos, dependent: :destroy
  has_many :conexoes, dependent: :restrict_with_error
  scope :ativos, ->(plano_atual = nil) { where('ativo').or(Plano.where(id: plano_atual)) }

  after_save do
    atr = PlanoEnviarAtributo.where(plano: self, atributo: 'Mikrotik-Rate-Limit').first_or_create
    atr.op = '='
    atr.valor = mikrotik_rate_limit
    atr.save
  end

  after_create do
    atr = PlanoEnviarAtributo.where(plano: self, atributo: 'Acct-Interim-Interval').first_or_create
    atr.op = ':='
    atr.valor = '900'
    atr.save

    atr = PlanoVerificarAtributo.where(plano: self, atributo: '	Simultaneous-Use').first_or_create
    atr.op = ':='
    atr.valor = '1'
    atr.save
  end

  def self.to_csv
    attributes = %w[id nome mensalidade download upload burst]
    CSV.generate(headers: true) do |csv|
      csv << attributes
      find_each do |plano|
        csv << attributes.map { |attr| plano.send(attr) }
      end
    end
  end

  def velocidade
    "#{download}M ▼ / #{upload}M ▲"
  end

  def mikrotik_rate_limit
    if burst
      burstup = (upload * 1024 * 1.1).to_i
      burstdown = (download * 1024 * 1.1).to_i
    else
      burstup = upload * 1024
      burstdown = download * 1024
    end
    format('%<upload>sM/%<download>sM %<burstup>sK/%<burstdown>sK %<upload>sM/%<download>sM 60/60 8 %<upload>sM/%<download>sM',
           upload: upload, download: download, burstup: burstup, burstdown: burstdown)
  end

  def burst_as_string
    if burst?
      'Ativiado'
    else
      'Desativado'
    end
  end

  def garantia
    if upload == download
      100
    else
      30
    end
  end

  def valor_com_desconto
    if desconto.present?
      mensalidade - desconto
    else
      mensalidade
    end
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[mensalidade nome]
  end
end
