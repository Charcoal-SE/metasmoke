class FlagLog < ApplicationRecord
  belongs_to :flag_condition
  belongs_to :user
  belongs_to :post
  belongs_to :site
  scope :auto, -> { where(is_auto: true) }
  scope :manual, -> { where(is_auto: false) }

  def flag_icon
    if is_auto
      return "⚑"
    else
      return "⚐"
    end
  end
end
