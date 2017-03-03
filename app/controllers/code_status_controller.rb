class CodeStatusController < ApplicationController
  def index
    @gem_versions = Gem::Specification.sort_by{ |g| [g.name.downcase, g.version] }.sort_by(&:name)
    @rails_version = @gem_versions.select { |g| g.name.downcase == "rails" }.first.version.to_s
  end
end
