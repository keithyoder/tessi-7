# frozen_string_literal: true

class CreateServidores < ActiveRecord::Migration[5.2]
  def change
    create_table :servidores do |t|
      t.string :nome
      t.integer :ip
      t.string :usuario
      t.string :senha
      t.integer :api_porta
      t.integer :ssh_porta
      t.integer :snmp_porta
      t.string :snmp_comunidade
      t.boolean :ativo
      t.boolean :up

      t.timestamps
    end
  end
end
