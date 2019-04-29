class Lists::ItemsController < ApplicationController
  before_action :set_list
  before_action :verify_privileges

  def new
    @list = Lists::List.find(params[:list_id])
  end

  def add
    @item = @list.items.new(params.require(:lists_item).permit(:content).merge(user: current_user))
    if @item.save
      flash[:success] = "Added as ##{@item.id}."
    else
      flash[:danger] = 'Failed to add.'
    end
    redirect_to list_path(@list)
  end

  def remove
    @item = @list.items.find(params[:item_id])
    if @item.destroy
      flash[:success] = 'Removed.'
    else
      flash[:danger] = 'Failed to remove.'
    end
    redirect_to list_path(@list)
  end

  private

  def set_list
    @list = Lists::List.find(params[:list_id])
  end

  def verify_privileges
    return if user_signed_in? && current_user.has_role?(@list.write_privs)
    redirect_to missing_privileges_path(required: @list.write_privs)
  end
end
