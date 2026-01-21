# frozen_string_literal: true

class AddUserNameIndexToRadAcct < ActiveRecord::Migration[7.2]
  def change
    return unless table_exists?(:radacct)

    add_index :radacct, %i[username acctstarttime]
  end
end
