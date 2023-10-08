class AddGerencianetFields < ActiveRecord::Migration[5.2]
  def change
    add_column :pagamento_perfis, :client_id, :string
    add_column :pagamento_perfis, :client_secret, :string
    add_column :faturas, :pix, :string
    add_column :faturas, :id_externo, :integer
    add_column :faturas, :link, :string
    add_column :faturas, :codigo_de_barras, :string
  end
end
