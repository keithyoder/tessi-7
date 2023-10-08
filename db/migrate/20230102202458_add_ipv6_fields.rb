class AddIpv6Fields < ActiveRecord::Migration[5.2]
  def change
    add_column :pontos, :ipv6, :inet
    add_column :servidores, :ipv6, :inet
    add_column :conexoes, :ipv6, :inet
    add_column :conexoes, :pool, :cidr
  end
end
