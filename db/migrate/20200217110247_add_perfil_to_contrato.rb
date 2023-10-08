# frozen_string_literal: true

class AddPerfilToContrato < ActiveRecord::Migration[5.2]
  def change
    add_reference :contratos, :pagamento_perfil, foreign_key: true
    add_reference :faturas, :pagamento_perfil, foreign_key: true
  end
end
