# frozen_string_literal: true

class FlagLog < ApplicationRecord
  belongs_to :flag_condition
  belongs_to :user
  belongs_to :post
  belongs_to :site
  belongs_to :api_key, optional: true

  scope(:auto, -> { where(is_auto: true) })
  scope(:manual, -> { where(is_auto: false) })
  scope(:successful, -> { where(success: true) })
  scope(:failed, -> { where(success: false) })
  scope(:today, -> { where('created_at > ?', Date.today) })
  scope(:tp, -> { joins(:post).where(posts: { is_tp: true }) })
  scope(:fp, -> { joins(:post).where(posts: { is_fp: true }) })

  def flag_icon
    if is_auto
      '⚑'
    else
      '⚐'
    end
  end
end
