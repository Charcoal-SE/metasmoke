# frozen_string_literal: true

include APIHelper

class CodeStatusController < ApplicationController
  def index
    @gem_versions = Gem::Specification.sort_by { |g| [g.name.downcase, g.version] }.sort_by(&:name)
    @important_gems = %w[
      rails
      will_paginate
      turbolinks
    ]
  end

  def api
    @repo = Rails.cache.fetch "code_status/repo##{CurrentCommit}" do
      Octokit.repository 'Charcoal-SE/metasmoke'
    end
    @compare = Rails.cache.fetch "code_status/compare##{CurrentCommit}" do
      Octokit.compare 'Charcoal-SE/metasmoke', CurrentCommit, @repo[:default_branch]
    end
    @compare_diff = Rails.cache.fetch "code_status/compare_diff##{CurrentCommit}" do
      Octokit.compare 'Charcoal-SE/metasmoke', CurrentCommit, @repo[:default_branch], accept: 'application/vnd.github.v3.diff'
    end
    @commit = Rails.cache.fetch "code_status/commit##{CurrentCommit}" do
      Octokit.commit 'Charcoal-SE/metasmoke', CurrentCommit
    end
    @commit_diff = Rails.cache.fetch "code_status/commit_diff##{CurrentCommit}" do
      Octokit.commit 'Charcoal-SE/metasmoke', CurrentCommit, accept: 'application/vnd.github.v3.diff'
    end
  end
end
