CONFIG['spid_login_enabled'] = (Configuration.get("saml_login_enabled", "false") == "true") rescue false
CONFIG['spid']=Hash.new
CONFIG['spid']['certificate_file']=Configuration.get("spid_certificate_file")
CONFIG['spid']['idp_sso_target_url']= Configuration.get("spid_idp_sso_target_url")
CONFIG['spid']['metadata_file'] = Configuration.get("spid_metadata_file")
CONFIG['spid']['spid_name_identifier_format'] = Configuration.get("urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress")
CONFIG['spid']['private_key_file'] = Configuration.get("spid_private_key_file")
# ensure feature enabled during automated tests
if RAILS_ENV == 'test'
  CONFIG['spid_login_enabled'] = true
end

