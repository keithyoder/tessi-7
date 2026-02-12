class CreateDevices < ActiveRecord::Migration[7.1]
  def change
    create_table :devices do |t|
      t.string :type, null: false
      t.references :deviceable, polymorphic: true, null: false
      t.references :equipamento, foreign_key: true

      t.string :mac
      t.string :usuario
      t.string :senha
      t.string :firmware
      t.datetime :last_seen_at
      t.jsonb :properties, default: {}

      t.timestamps
    end

    add_index :devices, :mac
    add_index :devices, :type
    add_index :devices, %i[deviceable_type deviceable_id], unique: true
    add_index :devices, :properties, using: :gin
  end
end
