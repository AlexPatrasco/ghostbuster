class CreateTokens < ActiveRecord::Migration[5.0]
  def change
    create_table :tokens do |t|
      t.integer :entity_id
      t.string :entity_type
      t.string :return_to
      t.boolean :return_login_id
      t.timestamps
    end
  end
end
