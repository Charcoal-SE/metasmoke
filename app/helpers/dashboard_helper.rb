# frozen_string_literal: true

module DashboardHelper
  def tab(tab_name)
    site_dash_path(params.permit(*%i[site_id months]).to_h.merge(tab: tab_name))
  end
end
