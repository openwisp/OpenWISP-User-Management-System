module AccountsHelper
  def link_to_paypal(link, args)
    account = args[:bill_to]
    args.delete :bill_to

    link_to(link, account.verify_with_credit_card(account_url, verify_credit_card_url), args) if account
  end

  def encrypted_submit_to_paypal(submit, args)
    account = args[:bill_to]
    args.delete :bill_to
    paypal_form = ""

    if account
      paypal_url, enc_data = account.encrypted_verify_with_credit_card(account_url, secure_verify_credit_card_url)

      paypal_form = form_tag paypal_url, args
      paypal_form += hidden_field_tag :cmd, "_s-xclick"
      paypal_form += hidden_field_tag :encrypted, enc_data
      paypal_form += submit
      paypal_form += "</form>"
    end

    paypal_form
  end

  def account_verification_methods
    Account::SELFVERIFICATION_METHODS
  end

  def account_verification_select
    account_verification_methods.map{ |method| [ t(method.to_sym), method ] }
  end
end
