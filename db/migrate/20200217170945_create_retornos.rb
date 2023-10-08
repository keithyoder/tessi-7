# frozen_string_literal: true

class CreateRetornos < ActiveRecord::Migration[5.2]
  def change
    create_table :retornos do |t|
      t.references :pagamento_perfil
      t.date :data
      t.integer :sequencia

      t.timestamps
    end
  end
end
