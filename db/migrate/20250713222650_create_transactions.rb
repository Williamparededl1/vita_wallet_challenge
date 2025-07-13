class CreateTransactions < ActiveRecord::Migration[7.1]
  def change
    create_table :transactions do |t|
      t.string :uuid, null: false, index: { unique: true }
      t.string :sender_address, null: false
      t.string :receiver_address, null: false
      t.decimal :amount, precision: 18, scale: 8, null: false
      t.integer :nonce, null: false
      t.text :raw_transaction_message, null: false
      t.text :signature, null: false
      t.string :status, null: false, default: 'pending'
      t.timestamps
    end
  end
end
