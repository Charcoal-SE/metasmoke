class ListTypesController < ApplicationController
  before_action :verify_admin
  before_action :set_list_type, except: [:index, :create]

  def index
    @list_types = ListType.all
  end

  def create
    @list_type = ListType.new list_type_params
    if @list_type.save
      flash[:success] = 'New list type saved.'
    else
      flash[:danger] = 'Failed to save new list type.'
    end
    redirect_back fallback_location: list_types_path
  end

  def update
    if @list_type.update list_type_params
      flash[:success] = 'Saved updated details.'
    else
      flash[:danger] = 'Failed to save updated details.'
    end
    redirect_back fallback_location: list_types_path
  end

  def destroy
    if @list_type.destroy
      flash[:success] = 'Removed list type.'
    else
      flash[:danger] = 'Failed to remove list type.'
    end
    redirect_back fallback_location: list_types_path
  end

  private

  def list_type_params
    params.require(:list_type).permit(:name, :description)
  end

  def set_list_type
    @list_type = ListType.find params[:id]
  end
end
