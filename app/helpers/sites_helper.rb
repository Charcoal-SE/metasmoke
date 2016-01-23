module SitesHelper
  def self.updateSites
    require 'net/http'
    url = URI.parse('http://api.stackexchange.com/2.2/sites?pagesize=1000&filter=!*L1-8Dpi2xJ-sYWj')
    req = Net::HTTP::Get.new(url.to_s)
    res = Net::HTTP.start(url.host, url.port) {|http|
      http.request(req)
    }
    sites = JSON.parse(res.body)["items"]
    puts sites
    if sites.count > 100 #all is well
      sites.each do |site|
        if Site.find_by_site_url(site["site_url"])  == nil
          s=Site.new
          s.site_url = site["site_url"]
          s.site_domain = URI.parse(s.site_url).host
          s.site_logo = site["favicon_url"].gsub(/http:/, "")
          s.site_name = site["name"]
          s.save!
        end
      end
    end
  end
end
