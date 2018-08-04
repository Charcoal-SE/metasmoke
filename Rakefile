# frozen_string_literal: true

# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)
require 'ruby-progressbar'

Rails.application.load_tasks

namespace :export do
  desc "Export JSON data to /ml_data.json"
  task :json => :environment do
    posts = { title: [], body: [], is_tp?: [], is_fp?: [], is_naa?: [] }
    precs = Post.all
    pb = ProgressBar.create(:title => "Exporting to JSON", total: precs)
    precs.each do |post|
      posts.keys.each do |field|
        posts[field].push(post.send(field))
      end
      pb.increment
    end
    File.open("#{Rails.root}/smokey_dump.json","w") do |f|
      f.write(posts.to_json)
    end
  end
end
