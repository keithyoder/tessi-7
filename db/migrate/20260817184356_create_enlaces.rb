# frozen_string_literal: true

class CreateEnlaces < ActiveRecord::Migration[7.2]
  def change
    create_table :enlaces do |t|
      t.integer :tecnologia, null: false
      t.string :canal
      t.integer :fibra_cor
      t.bigint :capacidade_bytes
      t.decimal :sinal_normal, precision: 5, scale: 2
      t.text :observacoes

      t.timestamps
    end

    create_table :enlace_extremidades do |t|
      t.references :enlace, null: false, foreign_key: true
      t.references :infraestrutura, polymorphic: true, null: false
      t.integer :posicao, null: false
      t.inet :ip

      t.timestamps
    end

    add_index :enlace_extremidades, %i[enlace_id posicao], unique: true
  end
end
