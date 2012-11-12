xml.account do
  xml.password @account.password
  xml.password_confirmation @account.password_confirmation
  xml.email @account.email
  xml.email_confirmation @account.email_confirmation
  xml.city @account.city
  xml.address @account.address
  xml.zip @account.zip
  xml.state @account.state
end