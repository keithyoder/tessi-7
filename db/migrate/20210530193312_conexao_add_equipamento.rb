# frozen_string_literal: true

class ConexaoAddEquipamento < ActiveRecord::Migration[5.2]
  def change
    add_reference :conexoes, :equipamento
  end
end
