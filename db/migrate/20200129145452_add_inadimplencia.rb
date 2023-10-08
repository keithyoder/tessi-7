# frozen_string_literal: true

class AddInadimplencia < ActiveRecord::Migration[5.2]
  def change
    add_column :conexoes, :inadimplente, :boolean, null: false, default: false
  end
end
