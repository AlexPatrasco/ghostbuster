class Login < ApplicationRecord
  belongs_to :customer, class_name: 'User', primary_key: 'customer_id', foreign_key: 'customer_id'
end
