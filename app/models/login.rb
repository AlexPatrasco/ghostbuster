class Login < ApplicationRecord
  belongs_to :customer, class_name: 'User', primary_key: 'customer_id', foreign_key: 'customer_id'

  has_many :accounts, primary_key: 'login_id', foreign_key: 'login_id'
end
