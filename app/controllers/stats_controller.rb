class StatsController < ApplicationController
  before_filter :require_operator

  caches_action :show

  access_control do
    default :deny

    allow :stats_viewer, :to => :show
  end

  def show
    @data = stat_data params[:id]

    respond_to do |format|
      format.js { render params[:id] }
      format.json { render :json => @data }
    end
  end

  private

  def stat_data(id)
    case id
      when 'registered_users' then registered_users_data
      when 'traffic' then traffic_data
      when 'logins' then logins_data
      when 'top_traffic_users' then top_traffic_users
      when 'last_logins' then last_logins
      when 'online_users' then online_users
      when 'last_registered' then last_registered
      else raise "Stat #{id} not found!"
    end
  end

  def top_traffic_users
    User.top_traffic(5)
  end


  def last_logins
    RadiusAccounting.last_logins(5)
  end

  def online_users
    RadiusAccounting.online_users(5)
  end

  def last_registered
    User.last_registered(5)
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