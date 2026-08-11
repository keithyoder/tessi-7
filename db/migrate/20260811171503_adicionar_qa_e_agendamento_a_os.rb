# frozen_string_literal: true

class AdicionarQaEAgendamentoAOs < ActiveRecord::Migration[7.1]
  def change
    change_table :os, bulk: true do |t|
      t.column :resultado, :integer
      t.column :agendado_em, :date
      t.column :vezes_reagendada, :integer, default: 0, null: false
      t.references :os_origem, foreign_key: { to_table: :os }, index: true
    end
  end
end
