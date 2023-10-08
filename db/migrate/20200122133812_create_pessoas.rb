# frozen_string_literal: true

class CreatePessoas < ActiveRecord::Migration[5.2]
  def change
    create_table :pessoas do |t|
      t.string :nome
      t.integer :tipo
      t.string :cpf
      t.string :cnpj
      t.string :rg
      t.string :ie
      t.date :nascimento
      t.references :logradouro, foreign_key: true
      t.string :numero
      t.string :complemento
      t.string :nomemae
      t.string :email
      t.string :telefone1
      t.string :telefone2

      t.timestamps
      t.index :nome
    end
  end
end
