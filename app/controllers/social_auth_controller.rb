class SocialAuthController < ApplicationController
  def create
    # if there is any missing vital information
    # abort the operation and display a helpful error message
    if auth_hash["provider"] == "facebook" and auth_hash["info"]["email"].nil? or\
       auth_hash["provider"] == "google_oauth2" and auth_hash["extra"]["raw_info"]["email_verified"] != "true"
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

    @account_session = AccountSession.create(@account, true)

    if @account.verified?
      @account.current_login_ip = request.remote_ip
      @account.save!
      @account.captive_portal_login!
      flash[:notice] = I18n.t(:Login_successful)
      # determine URL for redirect (defaults to account URL)
      config_url = Configuration.get('social_login_success_url', '')
      redirect_url = config_url != '' ? config_url : account_url
      redirect_to redirect_url
    else
      # ask mobile phone
      redirect_to additional_fields_url
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
