class ChangeIdExternoToString < ActiveRecord::Migration[7.2]
  def change
    change_column :faturas, :id_externo, :string
  end
end
