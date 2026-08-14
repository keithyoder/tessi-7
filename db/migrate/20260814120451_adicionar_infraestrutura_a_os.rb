# frozen_string_literal: true

class AdicionarInfraestruturaAOs < ActiveRecord::Migration[7.1]
  def change
    change_table :os, bulk: true do |t|
      t.references :infraestrutura, polymorphic: true, index: true, null: true
      t.change_null :pessoa_id, true
    end
  end
end
