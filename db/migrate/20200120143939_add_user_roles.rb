# frozen_string_literal: true

class AddUserRoles < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :role, :integer
  end
end
