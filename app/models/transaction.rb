class Transaction < ApplicationRecord
  belongs_to :account, primary_key: 'account_id', foreign_key: 'account_id'
end
