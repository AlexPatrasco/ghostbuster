class AddSpectreFieldsToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :customer_id, :integer
    add_column :users, :customer_secret, :string
    add_column :users, :customer_status, :string
  end
end
