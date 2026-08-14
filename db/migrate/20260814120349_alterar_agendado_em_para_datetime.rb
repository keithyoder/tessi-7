# frozen_string_literal: true

class AlterarAgendadoEmParaDatetime < ActiveRecord::Migration[7.1]
  def up
    change_column :os, :agendado_em, :datetime
  end

  def down
    change_column :os, :agendado_em, :date
  end
end
