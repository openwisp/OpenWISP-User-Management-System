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

require 'shellwords'

class StatsController < ApplicationController
  before_filter :require_operator_or_account
  skip_before_filter :set_mobile_format

  AVAILABLE_STATS_GRAPH = %w{account_logins account_traffic user_logins user_traffic registered_users registered_users_daily traffic logins top_traffic_users last_logins last_registered}

  access_control do
    default :deny

    action :index, :show, :export do
      allow :stats_viewer, :if => :current_operator
    end

    actions :show do
      allow anonymous, :if => :current_account
    end
  end

  def index
  end

  def show
    @stat = (AVAILABLE_STATS_GRAPH & [ params[:id] ]).first

    @from = Date.strptime(params[:from], I18n.t('date.formats.default')) rescue 14.days.ago.to_date
    @to = Date.strptime(params[:to], I18n.t('date.formats.default')) rescue Date.today
    @number = params[:number].to_i rescue 5

    data = load_stat_data

    respond_to do |format|
      format.html
      format.js { data }
      format.json { data }
      format.xml { render :xml => data }
    end
  rescue NoMethodError
    render :nothing => true, :status => :bad_request
  end

  def export
    supported = %w(svg png pdf)
    svg, mime_type, filename, width = params[:svg], params[:type], params[:filename], params[:width].to_i
    extension = mime_type.split('/').last

    # Svg mimetype is svg+xml (so not a valid file extension)
    # Also check to see if someone is tampering with params[:type] which
    # will be executed on cli
    extension = 'svg' if extension == 'svg+xml' || !supported.include?(extension)

    temp = Tempfile.open("temp", "#{Rails.root}/tmp/stat_exports/")
    temp << svg
    temp.close

    exported = %x{ rsvg-convert #{Shellwords.escape(temp.path)} --width #{width} --format #{Shellwords.escape(extension)} }

    send_data exported, :filename => "#{filename}.#{extension}", :type => mime_type
  end

  private

  def load_stat_data
    if current_operator
      @data = operator_stat_data @stat
    elsif current_account
      @data = account_stat_data @stat
    end
  end

  def account_stat_data(id)
    case id
      when 'account_logins' then current_account.session_times_from(@from)
      when 'account_traffic' then current_account.traffic_sessions_from(@from)
      else raise NoMethodError.new("Stat #{id} not found!")
    end
  end

  def operator_stat_data(id)
    # intercept mac address and convert it to called-station-id format
    called_station_id = params["called-station-id"].upcase.gsub(':', '-') rescue nil
    
    case id
      when 'user_logins' then User.find(params[:user_id]).session_times_from(@from)
      when 'user_traffic' then User.find(params[:user_id]).traffic_sessions_from(@from)

      when 'registered_users'
        data = { 'all' => User.registered_each_day(@from, @to) }
        if User.self_verification_methods.length > 1
          data['mobile_phone'] = User.registered_each_day(@from, @to, 'mobile_phone')
          data['credit_card'] = User.registered_each_day(@from, @to, 'gestpay_credit_card')
        end
        return data
      when 'registered_users_daily'
        data = { 'all' => User.registered_daily(@from, @to) }
        if User.self_verification_methods.length > 1
          data['mobile_phone'] = User.registered_daily(@from, @to, 'mobile_phone')
          data['credit_card'] = User.registered_daily(@from, @to, 'gestpay_credit_card')
        end
        return data
      when 'traffic' then RadiusAccounting.traffic_each_day(@from, @to, called_station_id)
      when 'logins' then RadiusAccounting.logins_each_day(@from, @to, called_station_id)

      when 'top_traffic_users' then User.top_traffic(@number)
      when 'last_logins' then RadiusAccounting.last_logins(@number)
      when 'last_registered' then User.last_registered(@number)

      else raise NoMethodError.new("Stat #{id} not found!")
    end
  end
end
