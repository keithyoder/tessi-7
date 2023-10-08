class CreateWebhooks < ActiveRecord::Migration[5.2]
  def change
    create_table :webhooks do |t|
      t.integer :tipo
      t.string :token

      t.timestamps
    end
  end
end
