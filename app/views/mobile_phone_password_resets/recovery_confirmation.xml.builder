xml.mobile_phone_password_resets do
  xml.account_recovered @account.recovered?
  if @account.recovered?
    xml.account_perishable_token(@account.recovered? ? @account.perishable_token : '')
  else
    xml.numbers do
      Configuration.get('verification_numbers').split(',').map{|n| n.strip}.each do |number|
        xml.number number
      end
    end
  end
end