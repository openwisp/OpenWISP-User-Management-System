require 'sip_busy_machine'

class MobilePhoneSipBusyMachine < SipBusyMachine

  public

    def initialize(params = {})
      super( params.merge({ :address => Configuration.get('sip_listen_address'), :port => Configuration.get('sip_listen_port') }))
    end

  protected

    def validSIPServerAddress?(params)
      super(params)
      valid_sip_servers = Configuration.get('sip_servers').split(',').map { |n| n.strip }
      return valid_sip_servers.include?(params[:address])
    end

    def validPhoneNumbers?(params)
      super(params)
      if params[:from] =~ /\A[0-9]+\Z/ and params[:to] =~ /\A[0-9]+\Z/
        valid_to_numbers = Configuration.get('verification_numbers').split(',').map { |n| n.strip }
        valid_to_numbers.each do |n|
          if n.include?(params[:to]) or params[:to].include?(n)
            return true
          end
        end
        return false
      else
        @logger.error("Something nasty?!? From/to parameter format error (from: #{params[:from]}, to: #{params[:to]})")
        return false
      end
    end

  public # TODO: remove: only for testing... the following should be a protected method!

    def callback(params)
      super(params)
      if params[:from] =~ /\A[0-9]+\Z/ and params[:to] =~ /\A[0-9]+\Z/
        if user = User.find_by_mobile_phone(params[:from])
          if user.verification_method == User::VERIFY_BY_MOBILE 
            unless user.mobile_phone_identity_verify_or_password_recover!
              @logger.debug("Account with mobile #{params[:from]} already verified/recovered")
            end
          else
            @logger.error("Invalid verification method for account with mobile #{params[:from]}!")
          end
        else
          @logger.info("Requested number cannot be found")
        end
      else
          @logger.error("Something nasty?!? From/to parameter format error (from: #{params[:from]}, to: #{params[:to]})")
      end
    end

end
