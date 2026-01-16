# frozen_string_literal: true

class CriarNfcoms < ActiveRecord::Migration[7.2]
  def change
    create_table :nfcom_notas do |t|
      # Sequential numbering (for next nota tracking)
      t.integer :serie, null: false, default: 1
      t.integer :numero, null: false
      
      # Legal requirements - MUST store these
      t.string :chave_acesso, limit: 44 # 44-digit access key
      t.string :protocolo, limit: 24 # SEFAZ authorization protocol
      t.text :xml_autorizado # The complete authorized XML (this is the legal document!)
      
      # Status tracking
      t.string :status, null: false, default: 'pending' # pending, authorized, rejected, cancelled
      t.datetime :data_autorizacao
      t.string :mensagem_sefaz # Error message if rejected
      
      # Business link
      t.references :fatura, foreign_key: true
      
      # Minimal query fields
      t.date :competencia, null: false # YYYY-MM-01 for billing month
      t.decimal :valor_total, precision: 13, scale: 2 # For reports/queries
      
      t.timestamps
    end
    
    # Indexes
    add_index :nfcom_notas, :chave_acesso, unique: true
    add_index :nfcom_notas, [:serie, :numero], unique: true
    add_index :nfcom_notas, :status
    add_index :nfcom_notas, :competencia
  end
end
