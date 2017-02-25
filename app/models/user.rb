require 'open-uri'

class User < ApplicationRecord
  rolify
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :feedbacks
  has_many :api_tokens
  has_many :api_keys
  has_many :user_site_settings
  has_many :flag_conditions
  has_many :flag_logs, :dependent => :nullify
  has_many :smoke_detectors
  has_many :moderator_sites

  # All accounts start with flagger role enabled
  after_create do
    self.add_role :flagger

    message = case self.stack_exchange_account_id.present?
    when true
      "New metasmoke user ['#{self.username}'](//stackexchange.com/users/#{self.stack_exchange_account_id}) created"
    when false
      "New metasmoke user '#{self.username}' created"
    end

    SmokeDetector.send_message_to_charcoal message
  end

  after_save do
    if stack_exchange_account_id_changed?
      if stack_exchange_account_id.present?
        self.add_role :reviewer
      else
        self.remove_role :reviewer
      end
    end
  end

  before_save do
    # Retroactively update
    (self.changed & ["stackexchange_chat_id", "meta_stackexchange_chat_id", "stackoverflow_chat_id"]).each do
      # todo
    end
  end

  def active_for_authentication?
    super && roles.present?
  end

  def inactive_message
    if !has_role?(:reviewer)
      :not_approved
    else
      super # Use whatever other message
    end
  end

  def update_chat_ids
    return if stack_exchange_account_id.nil?

    begin
      self.stackexchange_chat_id = Net::HTTP.get_response(URI.parse("http://chat.stackexchange.com/accounts/#{stack_exchange_account_id}"))["location"].scan(/\/users\/(\d*)\//)[0][0]
    rescue
      puts "Probably no c.SE ID"
    end

    begin
      self.stackoverflow_chat_id = Net::HTTP.get_response(URI.parse("http://chat.stackoverflow.com/accounts/#{stack_exchange_account_id}"))["location"].scan(/\/users\/(\d*)\//)[0][0]
    rescue
      puts "Probably no c.SO ID"
    end

    begin
      self.meta_stackexchange_chat_id = Net::HTTP.get_response(URI.parse("http://chat.meta.stackexchange.com/accounts/#{stack_exchange_account_id}"))["location"].scan(/\/users\/(\d*)\//)[0][0]
    rescue
      puts "Probably no c.mSE ID"
    end
  end

  def get_username(readonly_api_token=nil)
    return if api_token.nil? and readonly_api_token.nil?

    begin
      config = AppConfig["stack_exchange"]
      auth_string = "key=#{AppConfig["stack_exchange"]["key"]}&access_token=#{readonly_api_token || api_token}"

      resp = JSON.parse(Net::HTTP.get_response(URI.parse("https://api.stackexchange.com/2.2/me/associated?pagesize=1&filter=!ms3d6aRI6N&#{auth_string}")).body)

      first_site = resp["items"][0]["site_url"]

      resp = JSON.parse(Net::HTTP.get_response(URI.parse("https://api.stackexchange.com/2.2/me?site=stackoverflow&filter=!-.wwQ56Mfo3J&#{auth_string}")).body)

      return resp["items"][0]["display_name"]
    rescue
      return
    end
  end

  def self.code_admins
    Role.where(:name => :code_admin).first.users
  end

  def remember_me
    true
  end

  # Flagging

  def update_moderator_sites
    return if api_token.nil?

    page = 1
    has_more = true
    self.moderator_sites = []
    auth_string = "key=#{AppConfig["stack_exchange"]["key"]}&access_token=#{api_token}"
    while has_more
      params = "?page=#{page}&pagesize=100&filter=!6OrReH6NRZrmc&#{auth_string}"
      url = "https://api.stackexchange.com/2.2/me/associated" + params

      response = JSON.parse(Net::HTTP.get_response(URI.parse(url)).body)
      has_more = response["has_more"]
      page += 1

      response["items"].each do |network_account|
        if network_account["user_type"] == "moderator"
          self.moderator_sites << ModeratorSite.new(:site_id => Site.find_by_site_url(network_account["site_url"]).id)
        end
      end

      if has_more and response.include? "backoff"
        sleep response["backoff"].to_i
      end
    end

    save!
  end

  def spam_flag(post, dry_run=false)
    if self.moderator_sites.pluck(:site_id).include? post.site_id
      raise "User is a moderator on this site; not flagging"
    end

    if api_token.nil?
      raise "Not authenticated"
    end

    auth_dict = { "key" => AppConfig["stack_exchange"]["key"], "access_token" => api_token }
    auth_string = "key=#{AppConfig["stack_exchange"]["key"]}&access_token=#{api_token}"

    path = post.is_answer? ? 'answers' : 'questions'
    site = post.site

    # Try to get flag options
    flag_options = JSON.parse(Net::HTTP.get_response(URI.parse("https://api.stackexchange.com/2.2/#{path}/#{post.stack_id}/flags/options?site=#{site.site_domain}&#{auth_string}")).body)["items"]

    unless flag_options.present?
      return false, "Flag options not present"
    end

    spam_flag_option = flag_options.select { |fo| fo["title"] == "spam" }.first

    unless spam_flag_option.present?
      return false, "Spam flag option not present"
    end

    request_params = { "option_id" => spam_flag_option["option_id"], "site" => site.site_domain }.merge auth_dict
    if !dry_run
      flag_response = JSON.parse(Net::HTTP.post_form(URI.parse("https://api.stackexchange.com/2.2/#{path}/#{post.stack_id}/flags/add"), request_params).body)
      if flag_response.include? "error_id" or flag_response.include? "error_message"
        return false, flag_response['error_message']
      else
        return true, (flag_response.include?("backoff") ? flag_response['backoff'] : 0)
      end
    else
      return true, 0
    end
  end
end
