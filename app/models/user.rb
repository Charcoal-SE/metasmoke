# frozen_string_literal: true

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
  has_many :flag_logs, dependent: :nullify
  has_many :smoke_detectors
  has_many :moderator_sites

  # All accounts start with flagger role enabled
  after_create do
    add_role :flagger

    message = case stack_exchange_account_id.present?
              when true
                "New metasmoke user ['#{username}'](//stackexchange.com/users/#{stack_exchange_account_id}) created"
              when false
                "New metasmoke user '#{username}' created"
              end

    SmokeDetector.send_message_to_charcoal message
  end

  before_save do
    # Retroactively update
    (changed & %w[stackexchange_chat_id meta_stackexchange_chat_id stackoverflow_chat_id]).each do
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
      res = Net::HTTP.get_response(URI.parse("http://chat.stackexchange.com/accounts/#{stack_exchange_account_id}"))
      self.stackexchange_chat_id = res['location'].scan(%r{/users/(\d*)/})[0][0]
    rescue
      puts 'Probably no c.SE ID'
    end

    begin
      res = Net::HTTP.get_response(URI.parse("http://chat.stackoverflow.com/accounts/#{stack_exchange_account_id}"))
      self.stackoverflow_chat_id = res['location'].scan(%r{/users/(\d*)/})[0][0]
    rescue
      puts 'Probably no c.SO ID'
    end

    begin
      res = Net::HTTP.get_response(URI.parse("http://chat.meta.stackexchange.com/accounts/#{stack_exchange_account_id}"))
      self.meta_stackexchange_chat_id = res['location'].scan(%r{/users/(\d*)/})[0][0]
    rescue
      puts 'Probably no c.mSE ID'
    end
  end

  def get_username(readonly_api_token = nil)
    return if api_token.nil? && readonly_api_token.nil?

    begin
      config = AppConfig['stack_exchange']
      auth_string = "key=#{config['key']}&access_token=#{readonly_api_token || api_token}"

      resp = Net::HTTP.get_response(URI.parse("https://api.stackexchange.com/2.2/me/associated?pagesize=1&filter=!ms3d6aRI6N&#{auth_string}")).body
      resp = JSON.parse(resp.body)

      first_site = resp['items'][0]['site_url']

      resp = Net::HTTP.get_response(URI.parse("https://api.stackexchange.com/2.2/me?site=#{first_site}&filter=!-.wwQ56Mfo3J&#{auth_string}"))
      resp = JSON.parse(resp.body)

      return resp['items'][0]['display_name']
    rescue
      return
    end
  end

  def self.code_admins
    Role.where(name: :code_admin).first.users
  end

  def remember_me
    true
  end

  # Transparent interface to encrypted API token
  def api_token
    return self[:api_token] if encrypted_api_token.nil?

    encryption_key = AppConfig['stack_exchange']['token_aes_key']
    begin
      return AESCrypt.decrypt(encrypted_api_token, encryption_key, salt, iv)
    rescue OpenSSL::Cipher::CipherError
      # Since dev environments don't have the proper keys to perform
      # decryption on a prod data dump, we allow this error in dev
      return encrypted_api_token if Rails.env.development? || Rails.env.test?
      raise
    end
  end

  def api_token=(new_value)
    if new_value.nil?
      self.encrypted_api_token = nil
      return new_value
    end

    encryption_key = AppConfig['stack_exchange']['token_aes_key']
    salt, iv, encrypted = AESCrypt.encrypt(new_value, encryption_key)
    update(encrypted_api_token: encrypted, salt: salt, iv: iv)
    new_value
  end

  # Flagging

  def update_moderator_sites
    return if api_token.nil?

    page = 1
    has_more = true
    self.moderator_sites = []
    auth_string = "key=#{AppConfig['stack_exchange']['key']}&access_token=#{api_token}"
    while has_more
      params = "?page=#{page}&pagesize=100&filter=!6OrReH6NRZrmc&#{auth_string}"
      url = 'https://api.stackexchange.com/2.2/me/associated' + params

      response = JSON.parse(Net::HTTP.get_response(URI.parse(url)).body)
      has_more = response['has_more']
      page += 1

      response['items'].each do |network_account|
        next unless network_account['user_type'] == 'moderator'
        domain = Addressable::URI.parse(network_account['site_url']).host
        ModeratorSite.find_or_create_by(site_id: Site.find_by_site_domain(domain).id,
                                        user_id: id)
      end

      sleep response['backoff'].to_i if has_more && response.include?('backoff')
    end

    save!
  end

  def spam_flag(post, dry_run = false)
    if moderator_sites.pluck(:site_id).include? post.site_id
      raise 'User is a moderator on this site; not flagging'
    end

    raise 'Not authenticated' if api_token.nil?

    auth_dict = { 'key' => AppConfig['stack_exchange']['key'], 'access_token' => api_token }
    auth_string = "key=#{AppConfig['stack_exchange']['key']}&access_token=#{api_token}"

    path = post.is_answer? ? 'answers' : 'questions'
    site = post.site

    # Try to get flag options
    uri = URI.parse("https://api.stackexchange.com/2.2/#{path}/#{post.stack_id}/flags/options?site=#{site.site_domain}&#{auth_string}")
    response = JSON.parse(Net::HTTP.get_response(uri).body)
    flag_options = response['items']

    unless flag_options.present?
      begin
        # rubocop:disable Style/GuardClause
        if response['error_message'] == 'The account associated with the access_token does not have a user on the site'
          return false, 'No account on this site.'
        else
          return false, 'Flag options not present'
        end
        # rubocop:enable Style/GuardClause
      rescue
        return false, 'Flag options not present'
      end
    end

    spam_flag_option = flag_options.select { |fo| fo['title'] == 'spam' }.first

    unless spam_flag_option.present?
      return false, 'Spam flag option not present'
    end

    request_params = { 'option_id' => spam_flag_option['option_id'], 'site' => site.site_domain }.merge auth_dict
    return true, 0 if dry_run
    uri = URI.parse("https://api.stackexchange.com/2.2/#{path}/#{post.stack_id}/flags/add")
    flag_response = JSON.parse(Net::HTTP.post_form(uri, request_params).body)
    # rubocop:disable Style/GuardClause
    if flag_response.include?('error_id') || flag_response.include?('error_message')
      return false, flag_response['error_message']
    else
      return true, (flag_response.include?('backoff') ? flag_response['backoff'] : 0)
    end
    # rubocop:enable Style/GuardClause
  end
end
