include ApiHelper

class CodeStatusController < ApplicationController
  def index
    @gem_versions = Gem::Specification.sort_by{ |g| [g.name.downcase, g.version] }.sort_by(&:name)
    @important_gems = [
      "rails",
      "will_paginate",
      "turbolinks"
    ]
  end
  def api
    @repo = Rails.cache.fetch "code_status/repo##{CurrentCommit}", expires_in: 5.minutes do
      ApiHelper.authorized_get("https://api.github.com/repos/Charcoal-SE/metasmoke")
    end
    @compare = Rails.cache.fetch "code_status/compare##{CurrentCommit}", expires_in: 1.minute do
      ApiHelper.authorized_get("https://api.github.com/repos/Charcoal-SE/metasmoke/compare/#{CurrentCommit}...#{@repo[:default_branch]}")
    end
    @compare_diff = Rails.cache.fetch "code_status/compare_diff##{CurrentCommit}", expires_in: 1.minute do
      ApiHelper.authorized_get("https://api.github.com/repos/Charcoal-SE/metasmoke/compare/#{CurrentCommit}...#{@repo[:default_branch]}", headers: {
        Accept: "application/vnd.github.v3.diff"
      }, parse_json: false)
    end
    @commit = Rails.cache.fetch "code_status/commit##{CurrentCommit}", expires_in: 5.minutes do
      ApiHelper.authorized_get("https://api.github.com/repos/Charcoal-SE/metasmoke/commits/#{CurrentCommit}")
    end
    @commit_diff = Rails.cache.fetch "code_status/commit_diff##{CurrentCommit}", expires_in: 1.day do
      ApiHelper.authorized_get("https://api.github.com/repos/Charcoal-SE/metasmoke/commits/#{CurrentCommit}", headers: {
        Accept: "application/vnd.github.v3.diff"
      }, parse_json: false)
    end
  end
end
