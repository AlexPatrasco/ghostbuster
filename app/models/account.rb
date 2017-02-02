class Account < ApplicationRecord
  belongs_to :login, primary_key: 'login_id', foreign_key: 'login_id'

  has_many :transactions, primary_key: 'account_id', foreign_key: 'account_id'
end
