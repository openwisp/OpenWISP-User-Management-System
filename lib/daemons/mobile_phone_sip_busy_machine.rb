#!/usr/bin/env ruby

# You might want to change this
ENV["RAILS_ENV"] ||= "production"

require File.dirname(__FILE__) + "/../../config/environment"
require File.dirname(__FILE__) + "/../../lib/mobile_phone_sip_busy_machine"
require File.dirname(__FILE__) + "/../../app/models/configuration"

$running = true
Signal.trap("TERM") do 
  $running = false
end

sbm_t = Thread.new { MobilePhoneSipBusyMachine.new( :logger =>  ActiveRecord::Base.logger ).run }

while($running) do
  break unless sbm_t.join(1).nil?
end

sbm_t.kill
