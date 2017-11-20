class SamlController < ApplicationController
  def init
    requestsaml = OneLogin::RubySaml::Authrequest.new
    if request.fullpath.ends_with? 'spid'
       redirect_to(requestsaml.create(saml_settings('spid')))
    else
       redirect_to root_url, :flash => {
         :error => "#{I18n.t(:Spid_login_failed)}: #{request.inspect}"
       }
       return nil
    end
  end

  def consume
    if request.fullpath.ends_with? 'spid'  
       options =  CONFIG['spid_options'].first
       options[:settings] = saml_settings('spid')
    else 
       redirect_to root_url, :flash => {
         :error => "#{I18n.t(:Spid_login_failed)} Fullpath #{response.inspect}" 
       }
       return nil
    end
    response = OneLogin::RubySaml::Response.new(params[:SAMLResponse], options)
    # We validate the SAML Response and check if the user already exists in the system
    if response.is_valid? || response.errors.include?(CONFIG['spid_skip_errors'])
       # authorize_success, log the user
       session[:userid] = response.nameid
       session[:attributes] = response.attributes
       Rails.logger.warn(session[:attributes].inspect)
       @account = Account.find_or_create_from_saml(session[:attributes], CONFIG['spid_attributes'].first)
       unless @account.errors.empty? 
          redirect_to root_url, :flash => {
              :error => "#{I18n.t(:Spid_login_failed)} Account errors #{@account.errors.map{ |a| a.join(' ') } }"   #{response.inspect}"
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

    settings.assertion_consumer_service_url = CONFIG[service]["assertion_consumer_service_url"]
    settings.issuer                         = CONFIG[service]["spid_issuer"]
    settings.idp_sso_target_url             = CONFIG[service]["idp_sso_target_url"]
    settings.name_identifier_format         = CONFIG[service]["spid_name_identifier_format"]
    settings.protocol_binding = 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST'

    xml = IO.read(CONFIG[service]["metadata_file"])
    hash = Hash.from_xml(xml)
    settings.idp_cert = hash["EntitiesDescriptor"]["EntityDescriptor"]["IDPSSODescriptor"]["KeyDescriptor"]["KeyInfo"]["X509Data"]["X509Certificate"]
    settings.certificate = IO.read(CONFIG[service]["certificate_file"])
    settings.private_key = IO.read(CONFIG[service]["private_key_file"]) 

    # Optional for most SAML IdPs
    settings.authn_context = [ "urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport", 
                               "https://www.spid.gov.it/SpidL1" ]

    settings.attribute_consuming_service.configure do
      service_name "Registrazione Utenti WiFi con SPID"
      CONFIG['spid_required'].first.each { |key, value| add_attribute :name => key, :name_format => "urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified", :friendly_name => value }
    end

    settings
  end

  
end
