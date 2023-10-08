# frozen_string_literal: true

class CreateNf21Itens < ActiveRecord::Migration[5.2]
  def change
    create_table :nf21_itens do |t|
      t.references :nf21
      t.text :item

      t.timestamps
    end
  end
end
