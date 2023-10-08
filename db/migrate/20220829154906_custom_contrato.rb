class CustomContrato < ActiveRecord::Migration[5.2]
  def change
    add_column :contratos, :descricao_personalizada, :string
    add_column :contratos, :valor_personalizado, :decimal, precision: 8, scale: 2

  end
end
