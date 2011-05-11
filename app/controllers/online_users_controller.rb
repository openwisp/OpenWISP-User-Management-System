class OnlineUsersController < ApplicationController
  def index
    @online_users = OnlineUser.find(:all)

    respond_to do |format|
      format.xml { render :xml => @online_users.to_xml }
    end
  end

  def show
    @online_user = OnlineUser.find(params[:id])

    respond_to do |format|
      format.xml { render :xml => @online_user.to_xml }
    end
  end
end
