class CreateWebhookEventos < ActiveRecord::Migration[5.2]
  def change
    create_table :webhook_eventos do |t|
      t.references :webhook, foreign_key: true
      t.timestamp :processed_at
      t.jsonb :headers
      t.jsonb :body

      t.timestamps
    end
  end
end
