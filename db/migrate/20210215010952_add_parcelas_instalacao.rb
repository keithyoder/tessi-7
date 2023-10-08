# frozen_string_literal: true

class AddParcelasInstalacao < ActiveRecord::Migration[5.2]
  def change
    add_column :contratos, :parcelas_instalacao, :integer
  end
end
