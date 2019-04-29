class Lists::ListsController < ApplicationController
  before_action :verify_admin, except: [:index]
  before_action :set_list, except: [:index, :new, :create]

  def index
    @lists = Lists::List.all.order(name: :asc)
  end

  def new
    @list = Lists::List.new
  end

  def create
    @list = Lists::List.new list_params
    if @list.save
      redirect_to list_path(@list)
    else
      render :new
    end
  end

  def show; end

  def edit; end

  def update
    if @list.update list_params
      redirect_to list_path(@list)
    else
      render :edit
    end
  end

  def destroy
    if @list.destroy
      redirect_to lists_path
    else
      flash[:danger] = 'This list can\'t be deleted right now - poke a developer.'
      render :show
    end
  end

  private

  def list_params
    params.require(:lists_list).permit(:name, :description, :write_privs, :manage_privs, :link_table, :link_field)
  end

  def set_list
    @list = Lists::List.find(params[:id])
  end
end
