class Account < ApplicationRecord
  belongs_to :login, primary_key: 'login_id', foreign_key: 'login_id'
end
