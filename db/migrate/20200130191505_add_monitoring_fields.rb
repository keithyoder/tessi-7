# frozen_string_literal: true

class AddMonitoringFields < ActiveRecord::Migration[5.2]
  def change
    add_column :pontos, :ssid, :string
    add_column :pontos, :frequencia, :string
    add_column :servidores, :versao, :string
    add_column :servidores, :equipamento, :string
  end
end
