json.merge! user.as_json
json.username CGI::unescapeHTML(user.username) unless user.username.nil?
json.merge!(moderator_sites: user.moderator_sites.map { |ms| ms.site.as_json })