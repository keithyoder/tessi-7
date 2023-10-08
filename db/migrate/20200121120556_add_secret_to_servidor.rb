# frozen_string_literal: true

class AddSecretToServidor < ActiveRecord::Migration[5.2]
  def change
    add_column :servidores, :radius_secret, :string
    add_column :servidores, :radius_porta, :integer
  end
end
