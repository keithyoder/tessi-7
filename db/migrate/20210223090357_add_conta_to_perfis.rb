# frozen_string_literal: true

class AddContaToPerfis < ActiveRecord::Migration[5.2]
  def change
    add_column :pagamento_perfis, :variacao, :string
  end
end
