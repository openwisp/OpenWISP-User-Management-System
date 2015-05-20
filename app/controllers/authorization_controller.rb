class AuthorizationController < ApplicationController
  def create
    if auth_hash["info"]["email"].nil?
      redirect_to root_url, :flash => {
        :error => "Your #{auth_hash["provider"]} account does not have a verified email address. You need to have a verified email address in order to proceed."
      }
      return nil
    end

    @account = Account.find_or_create_from_oauth(auth_hash)

    unless @account.errors.empty?
      redirect_to root_url, :flash => {
        :error => @account.errors
      }
      return nil
    end

    @account.store_ip(request.remote_ip)
    @account_session = AccountSession.create(@account, true)
    @account.captive_portal_login!
    @account.clear_ip!
    flash[:notice] = I18n.t(:Login_successful)

    respond_to do |format|
      format.html { redirect_to account_url }
      format.mobile { redirect_to account_url }
    end
  end

  def failure
    redirect_to root_url, :flash => {
      :error => "#{I18n.t(:Social_login_failed)}: #{params[:message]}"
    }
  end

  protected

  def auth_hash
    request.env['omniauth.auth']
  end
end
