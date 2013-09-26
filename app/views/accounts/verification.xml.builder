xml.account do
  xml.verified @account.verified?
  xml.verification_method @account.verification_method

  unless @account.verified?
    xml.verification do
      if @account.verification_method == Account::VERIFY_BY_MOBILE
        xml.numbers do
          Configuration.get('verification_numbers').split(',').map{|n| n.strip}.each do |number|
            xml.number number
          end
        end
      elsif @account.verification_method == Account::VERIFY_BY_PAYPAL
        xml.paypal do
          xml << link_to_paypal(image_tag("paypal.png"), :bill_to                      => @account)
          # xml << encrypted_submit_to_paypal(image_submit_tag("paypal.png"), :bill_to => @account)
        end
      end
      xml.minutes_left @account.expire_time
    end
  end
end
