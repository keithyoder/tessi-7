# frozen_string_literal: true

# == Schema Information
#
# Table name: estados
#
#  id         :bigint           not null, primary key
#  ibge       :integer
#  nome       :string
#  sigla      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_estados_on_nome  (nome) UNIQUE
#
class Estado < ApplicationRecord
  require 'csv'
  has_many :cidades
  validates :sigla, presence: true

  def titulo
    'Estado'
  end

  def search
    'nome_cont'
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[nome sigla]
  end

  def self.ransackable_associations(_auth_object = nil)
    ['cidades']
  end

  def self.to_csv
    attributes = %w[id sigla nome ibge]
    CSV.generate(headers: true) do |csv|
      csv << attributes

      all.each do |estado|
        csv << attributes.map { |attr| estado.send(attr) }
      end
    end
  end
end
