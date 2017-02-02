class CreateTransactions < ActiveRecord::Migration[5.0]
  def change
    create_table :transactions do |t|
      t.integer :account_id
      t.integer :transaction_id
      t.text :description
      t.decimal :amount
      t.string :currency_code
      t.date :made_on
      t.string :status

      t.timestamps
    end
  end
end
