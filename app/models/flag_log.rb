# frozen_string_literal: true

class FlagLog < ApplicationRecord
  include Websocket

  belongs_to :flag_condition
  belongs_to :user, optional: true
  belongs_to :post
  belongs_to :site
  belongs_to :api_key, optional: true

  scope(:auto, -> { where(is_auto: true) })
  scope(:manual, -> { where(is_auto: false) })
  scope(:dry_run, -> { where(is_dry_run: true) })
  scope(:successful, -> { where(success: true) })
  scope(:failed, -> { where(success: false) })
  scope(:today, -> { where('created_at > ?', Date.today) })
  scope(:tp, -> { joins(:post).where(posts: { is_tp: true }) })
  scope(:fp, -> { joins(:post).where(posts: { is_fp: true }) })
  scope(:spam, -> { where(flag_type: 'spam') })
  scope(:abusive, -> { where(flag_type: 'abusive') })
  scope(:other, -> { where(flag_type: 'other') })

  default_scope { where(flag_type: 'spam').or(where(flag_type: 'abusive')) }

  def flag_icon
    if is_auto && flag_type == 'spam'
      '⚑'
    elsif is_auto && flag_type == 'abusive'
      '🏁'
    else
      '⚐'
    end
  end
end
