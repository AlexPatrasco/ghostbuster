class CreateAccounts < ActiveRecord::Migration[5.0]
  def change
    create_table :accounts do |t|
      t.integer :login_id
      t.integer :account_id
      t.string :name
      t.string :nature
      t.decimal :balance
      t.string :currency_code
      
      t.timestamps
    end
  end
end
