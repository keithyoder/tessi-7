# frozen_string_literal: true

class AddContratoToConexao < ActiveRecord::Migration[5.2]
  def change
    add_reference :conexoes, :contrato, index: true
    add_column :pontos, :canal_tamanho, :integer
    add_column :pontos, :equipamento, :string
  end
end
