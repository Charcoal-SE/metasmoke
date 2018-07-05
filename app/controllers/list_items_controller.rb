class ListItemsController < ApplicationController
  def list
    @type = ListType.find_by name: params[:list]
    @items = @type.list_items.paginate(page: params[:page], per_page: 100)
  end

  def create
    respond_to do |format|
      format.html do
        redirect_to new_user_session_path and return unless user_signed_in?

        list_type = params[:list_item].present? && params[:list_item][:list_type_id].present? ?
                      ListType.find(params[:list_item][:list_type_id]) : nil
        if list_type.present?
          if list_type.permissions.present? && !current_user.has_role?(list_type.permissions)
            redirect_to missing_privileges_path(required: list_type.permissions) and return
          end
        else
          flash[:danger] = 'You must select a list to add this item to!'
          redirect_back fallback_location: root_path and return
        end

        @item = ListItem.new list_item_params.merge(user: current_user)
        if @item.save
          flash[:success] = 'Successfully created.'
        else
          flash[:danger] = 'Failed to create new item.'
        end
        redirect_back fallback_location: root_path
      end

      format.json do
        smokey = SmokeDetector.where(access_token: params[:key])

        render plain: 'Go away', status: 403 and return unless smokey.exists?
        smokey = smokey.first

        type = ListType.find_by name: params[:type]
        @item = ListItem.create list_item_smokey_params.merge(smoke_detector: smokey, list_type: type)
        render plain: 'OK'
      end
    end
  end

  private

  def list_item_params
    params.require(:list_item).permit(:data, :list_type_id)
  end

  def list_item_smokey_params
    params.require(:list_item).permit(:data)
  end
end
