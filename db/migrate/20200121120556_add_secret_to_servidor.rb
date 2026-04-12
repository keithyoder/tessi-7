# frozen_string_literal: true

class AddSecretToServidor < ActiveRecord::Migration[5.2]
  def change
    change_table :servidores, bulk: true do |t|
      t.string :radius_secret
      t.integer :radius_porta
    end
  end
end
