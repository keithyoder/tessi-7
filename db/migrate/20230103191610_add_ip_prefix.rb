class AddIpPrefix < ActiveRecord::Migration[5.2]
  def change
    add_column :ip_redes, :subnet, :integer
  end
end
