# frozen_string_literal: true

class AddCaixaToConexao < ActiveRecord::Migration[5.2]
  def change
    add_reference :conexoes, :caixa, references: :fibra_caixas, index: true
    add_column :conexoes, :porta, :integer
  end
end
