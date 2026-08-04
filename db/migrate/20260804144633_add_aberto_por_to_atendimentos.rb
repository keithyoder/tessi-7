# frozen_string_literal: true

class AddAbertoPorToAtendimentos < ActiveRecord::Migration[7.2]
  def change
    add_reference :atendimentos, :aberto_por, foreign_key: { to_table: :users }, index: true
  end
end
