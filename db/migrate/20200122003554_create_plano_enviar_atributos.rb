# frozen_string_literal: true

class CreatePlanoEnviarAtributos < ActiveRecord::Migration[5.2]
  def change
    create_table :plano_enviar_atributos do |t|
      t.references :plano, foreign_key: true
      t.string :atributo
      t.string :op
      t.string :valor

      t.timestamps
    end
  end
end
