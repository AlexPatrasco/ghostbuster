class User::TransactionsController < UserController

  def index
    @transactions = Account.find_by(account_id: params[:account_id]).transactions
  end
end
