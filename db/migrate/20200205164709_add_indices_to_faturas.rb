# frozen_string_literal: true

class AddIndicesToFaturas < ActiveRecord::Migration[5.2]
  def change
    add_index :faturas, :liquidacao
    add_index :faturas, %i[meio_liquidacao liquidacao]
    add_index :faturas, :vencimento
  end
end
