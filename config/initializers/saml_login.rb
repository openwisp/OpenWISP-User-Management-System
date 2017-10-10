CONFIG['spid_login_enabled'] = (Configuration.get("spid_login_enabled", "false") == "true") rescue false
CONFIG['spid']=Hash.new
CONFIG['spid']['spid_issuer']=Configuration.get("spid_issuer")
CONFIG['spid']['assertion_consumer_service_url']=Configuration.get("assertion_consumer_service_url")
CONFIG['spid']['certificate_file']=Configuration.get("spid_certificate_file")
CONFIG['spid']['idp_sso_target_url']= Configuration.get("spid_idp_sso_target_url")
CONFIG['spid']['metadata_file'] = Configuration.get("spid_metadata_file")
CONFIG['spid']['spid_name_identifier_format'] = Configuration.get("spid_name_identifier_format")
CONFIG['spid']['private_key_file'] = Configuration.get("spid_private_key_file")
CONFIG['spid']['attributes'] = {"Codice-fiscale-SPID" => "Codice Fiscale", "Shib-Identita-Nome" => "Nome", "Shib-Identita-Cognome" => "Cognome", "Shib-Email" => "Indirizzo e-mail"}
# ensure feature enabled during automated tests
if RAILS_ENV == 'test'
  CONFIG['spid_login_enabled'] = true
end

