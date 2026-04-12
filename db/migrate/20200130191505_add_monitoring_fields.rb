# frozen_string_literal: true

class AddMonitoringFields < ActiveRecord::Migration[5.2]
  def change
    change_table :pontos, bulk: true do |t|
      t.string :ssid
      t.string :frequencia
    end
    change_table :servidores, bulk: true do |t|
      t.string :versao
      t.string :equipamento
    end
  end
end
