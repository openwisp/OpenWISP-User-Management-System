# This file is part of the OpenWISP User Management System
#
# Copyright (C) 2012 OpenWISP.org
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

require 'sip_busy_machine'

class MobilePhoneSipBusyMachine < SipBusyMachine

  public

  def initialize(params = {})
    super( params.merge(
               { :address => Configuration.get('sip_listen_address'),
                 :port => Configuration.get('sip_listen_port')
               })
    )
  end

  protected

  def valid_sip_server_address?(params)
    super(params)
    valid_sip_servers = Configuration.get('sip_servers').split(',').map { |n| n.strip }

    valid_sip_servers.include?(params[:address])
  end

  def valid_phone_numbers?(params)
    super(params)
    if params[:from] =~ /\A[0-9]+\Z/ and params[:to] =~ /\A[0-9]+\Z/
      valid_to_numbers = Configuration.get('verification_numbers').split(',').map { |n| n.strip }
      valid_to_numbers.each do |n|
        if n.include?(params[:to]) or params[:to].include?(n)
          return true
        end
      end
      false
    else
      @logger.error("Something nasty?!? From/to parameter format error (from: #{params[:from]}, to: #{params[:to]})")

      false
    end
  end

  def callback(params)
    super(params)
    if params[:from] =~ /\A[0-9]+\Z/ and params[:to] =~ /\A[0-9]+\Z/
      if user = User.find_by_mobile_phone(params[:from])
        if user.verify_with_mobile_phone?
          unless user.mobile_phone_identity_verify_or_password_recover!
            @logger.warn("Account with mobile #{params[:from]} already verified/recovered")
          end
        else
          @logger.error("Invalid verification method for account with mobile #{params[:from]}!")
        end
      else
        @logger.warn("Requested number cannot be found")
      end
    else
      @logger.error("Something nasty?!? From/to parameter format error (from: #{params[:from]}, to: #{params[:to]})")
    end
  end

end
