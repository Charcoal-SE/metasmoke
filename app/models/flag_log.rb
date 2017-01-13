class FlagLog < ApplicationRecord
  belongs_to :flag_condition
  belongs_to :user
  belongs_to :post
  belongs_to :site
end
