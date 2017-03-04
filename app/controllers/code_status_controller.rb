class CodeStatusController < ApplicationController
  def index
    @gem_versions = Gem::Specification.sort_by{ |g| [g.name.downcase, g.version] }.sort_by(&:name)
    @important_gems = [
      "rails",
      "will_paginate",
      "turbolinks"
    ]
  end
end
