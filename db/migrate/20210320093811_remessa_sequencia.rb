# frozen_string_literal: true

class RemessaSequencia < ActiveRecord::Migration[5.2]
  def change
    add_column :pagamento_perfis, :sequencia, :integer
  end
end
