class ConexaoEndereco < ActiveRecord::Migration[5.2]
  def change
    add_reference :conexoes, :logradouro, foreign_key: true
    add_column :conexoes, :numero, :string
    add_column :conexoes, :complemento, :string
  end
end
