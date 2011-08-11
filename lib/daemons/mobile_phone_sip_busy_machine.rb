#!/usr/bin/env ruby

require File.dirname(__FILE__) + "/../../config/application"
Rails.application.require_environment!

require File.dirname(__FILE__) + "/../../lib/mobile_phone_sip_busy_machine"

$running = true
Signal.trap("TERM") do 
  $running = false
end

sbm_t = Thread.new { MobilePhoneSipBusyMachine.new( :logger =>  ActiveRecord::Base.logger ).run }

while($running) do
  break unless sbm_t.join(1).nil?
end

sbm_t.kill
