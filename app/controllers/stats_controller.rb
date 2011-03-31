class StatsController < ApplicationController
  before_filter :require_operator_or_account

  access_control do
    default :deny

    action :show do
      allow :stats_viewer, :if => :current_operator
      allow anonymous, :if => :current_account
    end
  end

  def show
    if current_operator
      @data = operator_stat_data params[:id]
    elsif current_account
      @data = account_stat_data params[:id]
    end

    respond_to do |format|
      format.js { render params[:id] }
      format.any { render :json => @data }
    end
  end

  private

  def account_stat_data(id)
    case id
      when 'account_logins' then account_logins
      when 'account_traffic' then account_traffic
      else raise "Stat #{id} not found!"
    end
  end

  def operator_stat_data(id)
    case id
      when 'user_logins' then user_logins
      when 'user_traffic' then user_traffic
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



  ### Graphs ###

  # Account Graphs
  def account_logins
    [
        {
            :name => I18n.t(:Last_x_days_time, :count => 14),
            :data => current_account.session_times_from(14.days.ago)
        }
    ]
  end

  def account_traffic
    [
        {
            :name => I18n.t(:Download),
            :data => current_account.traffic_out_sessions_from(14.days.ago)
        },
        {
            :name => I18n.t(:Upload),
            :data => current_account.traffic_in_sessions_from(14.days.ago)
        }
    ]
  end


  # Operator Graphs
  def user_logins
    [
        {
            :name => I18n.t(:Last_x_days_time, :count => 14),
            :data => User.find(params[:user_id]).session_times_from(14.days.ago)
        }
    ]
  end

  def user_traffic
    [
        {
            :name => I18n.t(:Last_x_days_traffic_download, :count => 14),
            :data => User.find(params[:user_id]).traffic_out_sessions_from(14.days.ago)
        },
        {
            :name => I18n.t(:Last_x_days_traffic_upload, :count => 14),
            :data => User.find(params[:user_id]).traffic_in_sessions_from(14.days.ago)
        }
    ]
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
        }
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


  ### Operator Stats ###
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
end
