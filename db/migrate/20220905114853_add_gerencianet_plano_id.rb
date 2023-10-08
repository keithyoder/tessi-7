class AddGerencianetPlanoId < ActiveRecord::Migration[5.2]
  def change
    add_column :planos, :gerencianet_id, :integer
  end
end
