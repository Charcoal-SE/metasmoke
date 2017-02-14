namespace :custom do
    task :symlink_db_yml do
      run "ln -s #{shared_path}/config/database.yml #{release_path}/config/database.yml"
    end
end
