# This file is part of the OpenWISP User Management System
#
# Copyright (C) 2010 CASPUR (wifi@caspur.it)
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

class StatsController < ApplicationController
  before_filter :require_operator_or_account
  skip_before_filter :set_mobile_format

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
    @stat = params[:id]

    @from = Date.strptime(params[:from], I18n.t('date.formats.default')) rescue 14.days.ago.to_date
    @to = Date.strptime(params[:to], I18n.t('date.formats.default')) rescue Date.today

    respond_to do |format|
      format.html
      format.js { load_stat_data }
      format.json { load_stat_data }
    end
  end

  def export
    supported = ['svg', 'png', 'pdf']
    svg, mime_type, filename, width = params[:svg], params[:type], params[:filename], params[:width].to_i
    extension = mime_type.split('/').last

    # Svg mimetype is svg+xml (so not a valid file extension)
    # Also check to see if someone is tampering with params[:type] which
    # will be executed on cli
    extension = 'svg' if extension == 'svg+xml' || !supported.include?(extension)

    temp = Tempfile.open("temp", "#{Rails.root}/tmp/stat_exports/")
    temp << svg
    temp.close

    exported = %x{ rsvg-convert #{temp.path} --width #{width} --format #{extension} }

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
      else raise "Stat #{id} not found!"
    end
  end

  def operator_stat_data(id)
    case id
      when 'user_logins' then User.find(params[:user_id]).session_times_from(@from)
      when 'user_traffic' then User.find(params[:user_id]).traffic_sessions_from(@from)

      when 'registered_users' then User.registered_each_day(@from, @to)
      when 'traffic' then RadiusAccounting.traffic_each_day(@from, @to)
      when 'logins' then RadiusAccounting.logins_each_day(@from, @to)

      when 'top_traffic_users' then User.top_traffic(5)
      when 'last_logins' then RadiusAccounting.last_logins(5)
      when 'last_registered' then User.last_registered(5)

      else raise "Stat #{id} not found!"
    end
  end
end
