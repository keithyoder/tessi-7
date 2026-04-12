# frozen_string_literal: true

class AddGerencianetFields < ActiveRecord::Migration[5.2]
  def change
    change_table :pagamento_perfis, bulk: true do |t|
      t.string :client_id
      t.string :client_secret
    end
    change_table :faturas, bulk: true do |t|
      t.string :pix
      t.integer :id_externo
      t.string :link
      t.string :codigo_de_barras
    end
  end
end
