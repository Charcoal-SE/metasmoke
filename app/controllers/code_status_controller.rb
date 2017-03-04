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
      Octokit.repository "Charcoal-SE/metasmoke"
    end
    @compare = Rails.cache.fetch "code_status/compare##{CurrentCommit}", expires_in: 1.minute do
      Octokit.compare "Charcoal-SE/metasmoke", CurrentCommit, @repo[:default_branch]
    end
    @compare_diff = Rails.cache.fetch "code_status/compare_diff##{CurrentCommit}", expires_in: 1.minute do
      Octokit.compare "Charcoal-SE/metasmoke", CurrentCommit, @repo[:default_branch], accept: "application/vnd.github.v3.diff"
    end
    @commit = Rails.cache.fetch "code_status/commit##{CurrentCommit}", expires_in: 5.minutes do
      Octokit.commit "Charcoal-SE/metasmoke", CurrentCommit
    end
    @commit_diff = Rails.cache.fetch "code_status/commit_diff##{CurrentCommit}", expires_in: 1.day do
      Octokit.commit "Charcoal-SE/metasmoke", CurrentCommit, accept: "application/vnd.github.v3.diff"
    end
  end
end
