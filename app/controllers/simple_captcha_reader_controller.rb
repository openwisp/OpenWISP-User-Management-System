# This file is part of the OpenWISP User Management System
#
# Copyright (C) 2010 CASPUR (Davide Guerri d.guerri@caspur.it)
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

class SimpleCaptchaReaderController < ApplicationController
  
  def simple_captcha_read
    begin
      captcha = SimpleCaptchaData.find_by_key(session[:simple_captcha]).value
      captcha = captcha.split("").map do |a| "#{a} " end.to_s
      if I18n.locale == 'it' || I18n.locale == :it
        output = %x[echo "#{captcha}" | text2wave -eval "(language_italian)" -eval "(Parameter.set 'Duration_Stretch 1.2)" -eval "(set! hts_duration_stretch 0.1)" -scale 0.5 | lame - - 2>/dev/null]
      else
        output = %x[echo "#{captcha}" | text2wave -eval "(Parameter.set 'Duration_Stretch 1.2)" -eval "(set! hts_duration_stretch 0.1)" -scale 0.5 | lame - - 2>/dev/null]
      end
      send_data output, :type => 'audio/mp3'
    rescue Exception => e
      logger.error "Exception #{e} in SimpleCaptchaReaderController::simple_captcha_read"
      send_data '', :type => 'audio/mp3'
    end
  end
  
end
