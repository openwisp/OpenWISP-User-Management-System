# This file is part of the OpenWISP User Management System
#
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

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
