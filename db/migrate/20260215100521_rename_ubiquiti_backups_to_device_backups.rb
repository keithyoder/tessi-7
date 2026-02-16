# frozen_string_literal: true

# Migration para renomear ubiquiti_backups para device_backups
# e alterar a associação de ponto para device
#
# Esta migração:
# 1. Renomeia a tabela ubiquiti_backups para device_backups
# 2. Remove a coluna ponto_id e adiciona device_id
# 3. Migra dados existentes vinculando backups ao device correspondente do ponto
class RenameUbiquitiBackupsToDeviceBackups < ActiveRecord::Migration[7.1]
  def up
    # Adiciona device_id antes de remover ponto_id para poder migrar dados
    add_reference :ubiquiti_backups, :device, foreign_key: true, index: true

    # Migra dados: vincula cada backup ao device do ponto correspondente
    execute <<~SQL.squish
      UPDATE ubiquiti_backups
      SET device_id = devices.id
      FROM devices
      WHERE devices.deviceable_type = 'Ponto'
        AND devices.deviceable_id = ubiquiti_backups.ponto_id
    SQL

    # Remove backups órfãos (pontos sem device associado)
    execute <<~SQL.squish
      DELETE FROM ubiquiti_backups
      WHERE device_id IS NULL
    SQL

    # Torna device_id obrigatório
    change_column_null :ubiquiti_backups, :device_id, false

    # Remove a foreign key e coluna ponto_id
    remove_reference :ubiquiti_backups, :ponto, foreign_key: true

    # Renomeia a tabela
    rename_table :ubiquiti_backups, :device_backups
  end

  def down
    rename_table :device_backups, :ubiquiti_backups

    add_reference :ubiquiti_backups, :ponto, foreign_key: true, index: true

    # Tenta restaurar ponto_id a partir do device
    execute <<~SQL.squish
      UPDATE ubiquiti_backups
      SET ponto_id = devices.deviceable_id
      FROM devices
      WHERE devices.id = ubiquiti_backups.device_id
        AND devices.deviceable_type = 'Ponto'
    SQL

    remove_reference :ubiquiti_backups, :device, foreign_key: true
  end
end
