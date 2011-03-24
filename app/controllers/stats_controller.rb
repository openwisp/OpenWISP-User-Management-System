class StatsController < ApplicationController
  before_filter :require_operator

  access_control do
    default :deny

    allow :stats_viewer, :to => :show
  end

  def show
    @data = stat_data params[:id]

    respond_to do |format|
      format.js
      format.json { render :json => @data }
    end
  end

  private

  def stat_data(id)
    case id
      when 'registered_users' then registered_users_data
      when 'traffic' then traffic_data
      when 'logins' then logins_data
      else raise "Stat #{id} not found!"
    end
  end

  def logins_data
    logins = RadiusAccounting.logins_each_day_from(14.days.ago)

    [
        {
            :name => I18n.t(:Logins),
            :data => logins[0]
        },
        {
            :type => 'line',
            :name => I18n.t(:Unique_logins),
            :data => logins[1]
        }
    ]
  end

  def traffic_data
    traffic = RadiusAccounting.traffic_each_day_from(14.days.ago)

    [
        {
            :name => I18n.t(:Upload),
            :data => traffic[1]
        },
        {
            :name => I18n.t(:Download),
            :data => traffic[2]
        },
        {
            :type => 'line',
            :name => I18n.t(:Traffic_total),
            :data => traffic[0]
        },
    ]
  end

  def registered_users_data
    [
        {
            :name => I18n.t(:Registered_users),
            :data => User.registered_each_day_from(14.days.ago)
        }
    ]
  end
end