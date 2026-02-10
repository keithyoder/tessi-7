# frozen_string_literal: true

class CreateUbiquitiBackups < ActiveRecord::Migration[7.2]
  def change
    create_table :ubiquiti_backups do |t|
      t.references :ponto, null: false, foreign_key: true
      t.text :config, null: false
      t.string :checksum, null: false
      t.timestamps
    end

    add_index :ubiquiti_backups, %i[ponto_id checksum]
  end
end
