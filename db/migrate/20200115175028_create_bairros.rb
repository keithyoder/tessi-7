# frozen_string_literal: true

class CreateBairros < ActiveRecord::Migration[5.2]
  def change
    create_table :bairros do |t|
      t.string :nome
      t.references :cidade, foreign_key: true
      t.decimal :latitude
      t.decimal :longitude

      t.timestamps
    end
  end
end
