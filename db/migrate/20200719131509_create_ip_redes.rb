# frozen_string_literal: true

class CreateIpRedes < ActiveRecord::Migration[5.2]
  def change
    create_table :ip_redes do |t|
      t.inet :rede
      t.references :ponto

      t.timestamps
    end
  end
end
