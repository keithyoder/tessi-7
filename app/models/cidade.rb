# frozen_string_literal: true

class Cidade < ApplicationRecord
  belongs_to :estado
  has_many :bairros
  has_many :logradouros, through: :bairros
  has_many :pessoas, through: :logradouros
  has_many :conexoes, through: :pessoas
  has_many :pontos, through: :conexoes

  CIDADES_ATENDIDAS = %w[2600500 2600609 2601201 2601706 2602803 2603207 2608008 2610806 2610905 2616001 2611200
                         2613008 2612406].freeze
  scope :assinantes, lambda {
    select('cidades.*, pontos.tecnologia').joins(:conexoes, :pontos).distinct
  }
  scope :atendidas, lambda {
    where(ibge: CIDADES_ATENDIDAS)
  }

  def titulo
    'Cidade'
  end

  def search
    'nome_cont'
  end

  def self.ransackable_attributes(_auth_object = nil)
    ['nome']
  end

  def self.to_csv
    require 'csv'
    attributes = %w[id nome estado ibge]
    CSV.generate(headers: true) do |csv|
      csv << attributes

      all.each do |cidade|
        csv << attributes.map { |attr| cidade.send(attr) }
      end
    end
  end

  def nome_uf
    "#{nome} - #{estado.sigla}"
  end

  def quantas_conexoes(tipo)
    collection = conexoes.ativo
    case tecnologia
    when 1
      collection = collection.radio
    when 2
      collection = collection.fibra
    end

    case tipo
    when 'Pessoa Física'
      collection = collection.pessoa_fisica
    when 'Pessoa Jurídica'
      collection = collection.pessoa_juridica
    end
    collection.count
  end
end
