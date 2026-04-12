# frozen_string_literal: true

class AddIpv6Fields < ActiveRecord::Migration[5.2]
  def change
    add_column :pontos, :ipv6, :inet
    add_column :servidores, :ipv6, :inet
    change_table :conexoes, bulk: true do |t|
      t.inet :ipv6
      t.cidr :pool
    end
  end
end
