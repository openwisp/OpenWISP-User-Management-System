class AssociatedUser < ActiveResource::Base
  # return access point mac address from user mac address
  # return false if OWMW is not configured
  def self.access_point_mac_address_by_user_mac_address(mac)
    # ensure OWMW is enabled
    if OWMW != {}
      # if owmw is enabled ensure is configured correctly
     OWMW.size.times{ |owmw|
      if OWMW[owmw]["password"].nil? or OWMW[owmw]["url"].nil? or OWMW[owmw]["url"].empty?
        raise "OWMW not configured correctly, check configuration for environment '#{Rails.env}'"
      end

      begin 
         AssociatedUser.site = OWMW[owmw]["url"]
         AssociatedUser.user = OWMW[owmw]["username"]
         AssociatedUser.password = OWMW[owmw]["password"]
         if  AssociatedUser.find(mac).access_point.mac_address
	     puts "Item **** FOUND **** in "+AssociatedUser.site.to_s
             return AssociatedUser.find(mac).access_point.mac_address
         end
      rescue Exception => e
	puts "Item NOT FOUND in "+AssociatedUser.site.to_s
	next
       end
     }
    else
      return false
    end
    return false
  end
end
