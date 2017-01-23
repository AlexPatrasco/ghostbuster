class UserController < ApplicationController
  before_action :authenticate_user!
  
  private

  def api
    SpectreClient.new
  end
end
