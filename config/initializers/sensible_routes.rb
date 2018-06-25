# frozen_string_literal: true

class SensibleRoute
  attr_reader :path, :url_details, :parameters, :verb

  def initialize(rt)
    @parameters = []

    formatter = rt.path.build_formatter
    parts = []
    matcher = []

    # Yes, this is a hack. Yes, it will probably break. No, it's not 'temporary'.
    internal = formatter.instance_variable_get :@parts
    internal.each do |part|
      if part.is_a? String
        parts << part
        matcher << part
      elsif part.is_a? ActionDispatch::Journey::Format::Parameter
        parts << ":#{part.name}"
        @parameters << part.name
        matcher << if rt.requirements[part.name.to_sym]
                     rt.requirements[part.name.to_sym]
                   else
                     '[^/]+'
                   end
      end
    end

    @path = parts.join
    @url_details = rt.requirements
    @verb = rt.verb
    @regex = Regexp.new "^#{matcher.join}$"
  end

  def match?(path)
    @regex.match?(path)
  end
end

class SensibleRouteCollection
  def initialize
    @routes = []
  end

  def add(new)
    @routes << new
  end

  def match_for(path)
    @routes.select { |rt| rt.match?(path) }.first
  end
end

module Rails
  cache.delete :sensible_routes

  def self.sensible_routes
    Rails.cache.fetch :sensible_routes do
      routes = SensibleRouteCollection.new
      Rails.application.routes.routes.to_a.each { |r| routes.add(SensibleRoute.new(r)) }
      return routes
    end
  end
end
