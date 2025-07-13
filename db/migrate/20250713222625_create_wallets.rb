
class CreateWallets < ActiveRecord::Migration[7.1]
  def change
    create_table :wallets do |t|
      t.string :address, null: false, index: { unique: true }
      t.text :public_key_hex, null: false
      t.decimal :balance, precision: 18, scale: 8, default: 0.0, null: false
      t.boolean :is_master, default: false, null: false
      t.integer :incoming_tx_count, default: 0, null: false
      t.integer :outcoming_tx_count, default: 0, null: false
      t.integer :last_nonce, default: -1, null: false
      t.timestamps
    end
  end
end
