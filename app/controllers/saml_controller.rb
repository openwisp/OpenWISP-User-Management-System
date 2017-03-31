class SamlController < ApplicationController
  def init
    requestsaml = OneLogin::RubySaml::Authrequest.new
    if request.fullpath.ends_with? 'spid'
       redirect_to(requestsaml.create(saml_settings('spid')))
    else
       redirect_to root_url, :flash => {
         :error => "#{I18n.t(:Spid_login_failed)}: #{appo}"
       }
       return nil
    end
  end

  def consume
    options = CONFIG['spid_options'].first
    response = OneLogin::RubySaml::Response.new(params[:SAMLResponse], options)
    Rails.logger.warn(response.inspect)
    if request.fullpath.ends_with? 'spid'  
	response.settings = saml_settings('spid')
    else 
       redirect_to root_url, :flash => {
         :error => "#{I18n.t(:Spid_login_failed)} Fullpath #{response.inspect}" 
       }
       return nil
    end
    # We validate the SAML Response and check if the user already exists in the system
    if response.is_valid? || response.errors.include?(CONFIG['spid_skip_errors'])
       # authorize_success, log the user
       session[:userid] = response.nameid
       session[:attributes] = response.attributes
       @account = Account.find_or_create_from_saml(session[:attributes], CONFIG['spid_attributes'].first)
       unless @account.errors.empty? 
          redirect_to root_url, :flash => {
              :error => "#{I18n.t(:Spid_login_failed)} Account errors #{response.inspect}"
          }
          return nil
       end
       @account_session = AccountSession.create(@account, true)
          
       if @account.verified?
          @account.current_login_ip = request.remote_ip
          @account.save!
          @account.captive_portal_login!
          flash[:notice] = "#{I18n.t(:Login_successful)}: #{@account.username}"
          # determine URL for redirect (defaults to account URL)
          config_url = Configuration.get('social_login_success_url', '')
          redirect_url = config_url != '' ? config_url : account_url
          redirect_to redirect_url

    end
    else
       redirect_to root_url, :flash => {
         :error => "#{I18n.t(:Spid_login_failed)} #{response.inspect}"
       }
    end
  end

  def metadata
    meta = OneLogin::RubySaml::Metadata.new
    if request.fullpath.ends_with? 'spid'
       render :xml => meta.generate(saml_settings('spid')), :content_type => "application/samlmetadata+xml"
    else
    redirect_to root_url, :flash => {
      :error => "#{I18n.t(:Spid_login_failed)}: #{response.inspect}"
    }
    end
  end

  private

  def saml_settings(service, root_dir="owums")
    #service identifies the federation of the users: maybe spid, idem etc
    settings = OneLogin::RubySaml::Settings.new

    settings.assertion_consumer_service_url = "https://signup.fvgwifi.it/owums/consume/spid"
    settings.issuer                         = CONFIG['spid_issuer']
    settings.idp_sso_target_url             = CONFIG[service]["idp_sso_target_url"]
    settings.name_identifier_format         = CONFIG[service]["name_identifier_format"]
    xml = IO.read(CONFIG[service]["metadata_file"])
    hash = Hash.from_xml(xml)
    settings.idp_cert = hash["EntityDescriptor"]["Signature"]["KeyInfo"]["X509Data"]["X509Certificate"]
    settings.certificate = IO.read(CONFIG[service]["certificate_file"])
    settings.private_key = IO.read(CONFIG[service]["private_key_file"]) 

    # Optional for most SAML IdPs
    settings.authn_context = "urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport"

    # Optional. Describe according to IdP specification (if supported) which attributes the SP desires to receive in SAMLResponse.
    settings.attributes_index = 5
    # Optional. Describe an attribute consuming service for support of additional attributes.
    settings.attribute_consuming_service.configure do
      service_name "Registrazione Utenti WiFi con SPID"
      service_index 5
      add_attribute :name => "email", :name_format => "urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified", :friendly_name => "Indirizzo e-mail"
      add_attribute :name => "Name", :name_format => "urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified", :friendly_name => "Nome"
      add_attribute :name => "givenName", :name_format => "urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified", :friendly_name => "Cognome"
      add_attribute :name => "fiscalNumber", :name_format => "urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified", :friendly_name => "Codice fiscale"
    end

    settings
  end

  
end
