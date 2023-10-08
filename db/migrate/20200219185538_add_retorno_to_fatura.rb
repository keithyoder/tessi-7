# frozen_string_literal: true

class AddRetornoToFatura < ActiveRecord::Migration[5.2]
  def change
    add_reference :faturas, :retorno, index: true
    add_column :pagamento_perfis, :banco, :integer
  end
end
