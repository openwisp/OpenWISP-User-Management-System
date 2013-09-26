class CreateInvoices < ActiveRecord::Migration
  def self.up
    create_table :invoices do |t|
      t.integer :user_id
      t.string :transaction_id
      t.decimal :amount, :precision => 8, :scale => 2
      t.decimal :tax, :precision => 8, :scale => 2
      t.decimal :total, :precision => 8, :scale => 2
      t.datetime :created_at

      t.timestamps
    end
    
    # add unique index on user_id
    add_index :invoices, :user_id, :unique => true
  end

  def self.down
    drop_table :invoices
  end
end
