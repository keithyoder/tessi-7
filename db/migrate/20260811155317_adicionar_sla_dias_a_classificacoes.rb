# frozen_string_literal: true

class AdicionarSlaDiasAClassificacoes < ActiveRecord::Migration[7.1]
  def change
    add_column :classificacoes, :sla_dias, :integer
  end
end
