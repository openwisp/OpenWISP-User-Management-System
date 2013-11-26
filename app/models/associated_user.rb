class AssociatedUser < ActiveResource::Base
  self.site = OWMW["url"]
  self.user = OWMW["username"]
  self.password = OWMW["password"]
  
  # return access point mac address from user mac address
  # return false if OWMW is not configured
  def self.access_point_mac_address_by_user_mac_address(mac)
    # ensure OWMW is enabled
    if OWMW != {}
      # if owmw is enabled ensure is configured correctly
      if OWMW["password"].nil? or OWMW["url"].nil? or OWMW["url"].empty?
        raise "OWMW not configured correctly, check configuration for environment '#{Rails.env}'"
      end
      AssociatedUser.find(mac).access_point.mac_address
    else
      return false
    end
  end
end