# frozen_string_literal: true

module SitesHelper
  def self.update_sites
    require 'net/http'
    url = URI.parse('https://api.stackexchange.com/2.2/sites?pagesize=1000&filter=!SmNndiHFp*Yrs)zUme')
    res = Net::HTTP.get_response(url)
    sites = JSON.parse(res.body)['items']
    return unless sites.count > 100 # all is not well; bail
    ids = sites.map do |site|
      uri = URI.parse(site['site_url'])
      aliased_hosts = (site['aliases'] || []).map { |a| URI.parse(a).host }
      print "#{uri.host} " unless Rails.env.test?
      if Site.exists?(site_domain: uri.host)
        s = Site.find_by(site_domain: uri.host)
      elsif Site.exists?(site_domain: aliased_hosts)
        s = Site.find_by(site_domain: aliased_hosts)
        s.site_domain = uri.host
      else
        s = Site.new(site_domain: uri.host)
      end

      if s.new_record?
        puts "[\x1b[1m\x1b[36mnew\x1b[0m]" unless Rails.env.test?
        SmokeDetector.send_message_to_charcoal "New site [#{site['name']}](#{site['site_url']}) launched!" unless Rails.env.test?
      else
        puts "[\x1b[32mok\x1b[0m]" unless Rails.env.test?
      end

      s.api_parameter = site['api_site_parameter']
      s.site_url = site['site_url']
      s.site_logo = site['favicon_url'].gsub(/https?:/, '')
      s.site_name = site['name']
      s.is_child_meta = site['site_type'] == 'meta_site'
      s.save!
      s.id
    end
    Site.where.not(id: ids).update_all(closed: true)
  end

  # Not actually intended to be used in prod code, just there as a console helper.
  def self.do_site_rename(old_name, new_name)
    old_site = Site.find_by site_name: old_name
    new_site = Site.find_by site_name: new_name
    puts "Old: ##{old_site.id} '#{old_site.site_name}'; new: ##{new_site.id} '#{new_site.site_name}'"

    puts 'Remapping Posts...'
    Post.where(site_id: old_site.id).update_all(site_id: new_site.id)

    puts 'Remapping StackExchangeUsers...'
    StackExchangeUser.where(site_id: old_site.id).update_all(site_id: new_site.id)

    puts 'Remapping FlagLogs...'
    FlagLog.where(site_id: old_site.id).update_all(site_id: new_site.id)

    puts 'Removing ModeratorSites...'
    ModeratorSite.where(site_id: old_site.id).delete_all

    puts 'Remapping HABTM_FlagConditions...'
    ActiveRecord::Base.connection.execute "UPDATE flag_conditions_sites SET site_id = #{new_site.id} WHERE site_id = #{old_site.id};"

    puts 'Remapping HABTM_UserSiteSettings...'
    ActiveRecord::Base.connection.execute "UPDATE sites_user_site_settings SET site_id = #{new_site.id} WHERE site_id = #{old_site.id};"

    puts 'Removing Site...'
    old_site.destroy

    puts 'Done'
  end
end
