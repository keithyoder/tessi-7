# frozen_string_literal: true

class AddFieldsToFatura3 < ActiveRecord::Migration[5.2]
  def change
    add_reference :faturas, :registro, references: :retornos, index: true
    add_reference :faturas, :baixa, references: :retornos, index: true
    add_foreign_key :faturas, :retornos, column: :registro_id
    add_foreign_key :faturas, :retornos, column: :baixa_id
  end
end
