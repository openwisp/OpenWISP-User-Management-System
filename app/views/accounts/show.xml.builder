xml.account do
  xml.username @account.username
  xml.email @account.email
  xml.email_confirmation @account.email_confirmation
  xml.mobile_prefix @account.mobile_prefix
  xml.mobile_suffix @account.mobile_suffix
  xml.verification_method @account.verification_method
  xml.given_name @account.given_name
  xml.surname @account.surname
  xml.birth_date @account.birth_date
  xml.city @account.city
  xml.address @account.address
  xml.zip @account.zip
  xml.state @account.state
end
