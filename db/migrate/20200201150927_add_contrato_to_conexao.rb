# frozen_string_literal: true

class AddContratoToConexao < ActiveRecord::Migration[5.2]
  def change
    add_reference :conexoes, :contrato, index: true
    change_table :pontos, bulk: true do |t|
      t.integer :canal_tamanho
      t.string :equipamento
    end
  end
end
