class OnlineUsersController < ApplicationController
  before_filter :require_operator

  access_control do
    default :deny

    allow :users_browser,    :to => :index
  end

  def index
    @online_users = OnlineUser.find(:all)

    respond_to do |format|
      format.xml
    end
  end
end
