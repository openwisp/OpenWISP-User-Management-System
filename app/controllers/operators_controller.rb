class OperatorsController < ApplicationController
  before_filter :require_operator

  access_control :subject_method => :current_operator do
    default :deny

    allow :operators_manager
  end

  def index
    @operators = Operator.all :order => 'login ASC'
  end

  def show
    @operator = Operator.find(params[:id])
  end

  def new
    @operator = Operator.new
  end

  def create
    @operator = Operator.new(params[:operator])
    if @operator.save
      flash[:notice] = I18n.t(:Operator_created_success)
      redirect_to operators_path
    else
      render :action => :new
    end
  end

  def edit
    @operator = Operator.find(params[:id])
  end

  def update
    @operator = Operator.find(params[:id])
    if @operator.update_attributes(params[:operator])
      flash[:notice] = I18n.t(:Operator_updated_success)
      redirect_to operators_path
    else
      render :action => :edit
    end
  end

  def destroy
    Operator.find(params[:id]).destroy
    flash[:notice] = I18n.t(:Operator_deleted_success)
    redirect_to operators_path
  end

end
