class ConfigurationsController < ApplicationController
  before_filter :require_operator
  skip_before_filter :set_mobile_format

  access_control do
    default :deny

    allow :configurations_manager
  end

  def edit
    @configuration = Configuration.find(params[:id])
  end

  def update
    @configuration = Configuration.find(params[:id])
    if @configuration.update_attributes(params[:configuration])
      flash[:notice] = I18n.t(:Configuration_key_updated)
      redirect_to configurations_path
    else
      render :action => :edit
    end
  end

  def index
    @configurations = Configuration.order("configurations.key")
  end

end
