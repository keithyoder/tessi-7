# frozen_string_literal: true

class AddIndexToFatura < ActiveRecord::Migration[5.2]
  def change
    add_index :faturas, %i[pagamento_perfil_id nossonumero]
  end
end
