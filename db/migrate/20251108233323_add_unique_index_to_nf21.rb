class AddUniqueIndexToNf21 < ActiveRecord::Migration[7.2]
  def change
    add_index :nf21s, :numero, unique: true
  end
end
