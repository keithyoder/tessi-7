# frozen_string_literal: true

class CreateConexoes < ActiveRecord::Migration[5.2]
  def change
    create_table :conexoes do |t|
      t.references :pessoa, foreign_key: true
      t.references :plano, foreign_key: true
      t.references :ponto, foreign_key: true
      t.inet :ip
      t.string :velocidade
      t.boolean :bloqueado, default: false, null: false
      t.boolean :auto_bloqueio, default: false, null: false

      t.timestamps
    end
  end
end
