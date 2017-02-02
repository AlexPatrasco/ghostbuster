class CreateLogins < ActiveRecord::Migration[5.0]
  def change
    create_table :logins do |t|
      t.integer :customer_id
      t.integer :login_id, unique: true
      t.integer :provider_id
      t.string :provider_code
      t.string :provider_name
      t.datetime :last_success_at
      t.string :status

      t.timestamps
    end
  end
end
