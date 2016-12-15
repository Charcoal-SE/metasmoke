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
  has_and_belongs_to_many :sites
  has_many :user_site_settings
  has_many :flag_conditions
  has_many :flag_logs

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

    self.stackexchange_chat_id = Net::HTTP.get_response(URI.parse("http://chat.stackexchange.com/accounts/#{stack_exchange_account_id}"))["location"].scan(/\/users\/(\d*)\//)[0][0]

    self.stackoverflow_chat_id = Net::HTTP.get_response(URI.parse("http://chat.stackoverflow.com/accounts/#{stack_exchange_account_id}"))["location"].scan(/\/users\/(\d*)\//)[0][0]

    self.meta_stackexchange_chat_id = Net::HTTP.get_response(URI.parse("http://chat.meta.stackexchange.com/accounts/#{stack_exchange_account_id}"))["location"].scan(/\/users\/(\d*)\//)[0][0]
  end

  def self.code_admins
    Role.where(:name => :code_admin).first.users
  end

  def remember_me
    true
  end

  # Flagging

  def spam_flag(post)
    if api_token.nil?
      raise "Not authenticated"
    end

    auth_dict = { "key" => AppConfig["stack_exchange"]["key"], "access_token" => api_token }
    auth_string = "key=#{AppConfig["stack_exchange"]["key"]}&access_token=#{api_token}"

    path = post.is_answer? ? 'answers' : 'questions'
    site = post.site

    # Try to get flag options
    flag_options = JSON.parse(Net::HTTP.get_response(URI.parse("https://api.stackexchange.com/2.2/#{path}/#{post.stack_id}/flags/options?site=#{site.site_domain}&#{auth_string}")).body)["items"]
    spam_flag_option = flag_options.select { |fo| fo["title"] == "spam" }.first

    raise "No option to flag as spam" unless spam_flag_option.present?

    request_params = { "option_id" => spam_flag_option["option_id"], "site" => site.site_domain }.merge auth_dict
    flag_response = JSON.parse(Net::HTTP.post_form(URI.parse("https://api.stackexchange.com/2.2/#{path}/#{post.stack_id}/flags/add"), request_params).body)
    raise "Didn't successfully flag" if flag_response.include? "error_id" or flag_response.include? "error_message"
  end
end
