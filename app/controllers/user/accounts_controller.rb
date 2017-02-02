class User::AccountsController < UserController

  def index
    @accounts = Login.find_by(login_id: params[:login_id]).accounts
  end
end
