# frozen_string_literal: true

set :nvm_type, :user # or :system, depends on your nvm setup
set :nvm_node, 'v8.1.0'
set :nvm_map_bins, %w[node npm yarn]

set :rvm_ruby_version, '2.5.0@metasmoke'

set :puma_bind, %w[tcp://127.0.0.1:9292]
set :passenger_restart_with_touch, true

# set :bundle_path, nil

# server-based syntax
# ======================
# Defines a single server with a list of roles and multiple properties.
# You can define all roles on a single server, or split them:

server 'erwaysoftware.com', roles: %w[app db web]
# server 'example.com', user: 'deploy', roles: %w{app web}, other_property: :other_value
# server 'db.example.com', user: 'deploy', roles: %w{db}

# role-based syntax
# ==================

# Defines a role with one or multiple servers. The primary server in each
# group is considered to be the first unless any  hosts have the primary
# property set. Specify the username and a domain or IP for the server.
# Don't use `:all`, it's a meta role.

# role :app, %w{deploy@example.com}, my_property: :my_value
# role :web, %w{user1@primary.com user2@additional.com}, other_property: :other_value
# role :db,  %w{deploy@example.com}

# Configuration
# =============
# You can set any configuration variable like in config/deploy.rb
# These variables are then only loaded and set in this stage.
# For available Capistrano configuration variables see the documentation page.
# http://capistranorb.com/documentation/getting-started/configuration/
# Feel free to add new variables to customise your setup.

set :rails_env, 'production'

# Custom SSH Options
# ==================
# You may pass any option but keep in mind that net/ssh understands a
# limited set of options, consult the Net::SSH documentation.
# http://net-ssh.github.io/net-ssh/classes/Net/SSH.html#method-c-start
#
# Global options
# --------------
#  set :ssh_options, {
#    keys: %w(/home/rlisowski/.ssh/id_rsa),
#    forward_agent: false,
#    auth_methods: %w(password)
#  }
#
# The server-based syntax can be used to override options:
# ------------------------------------
server 'erwaysoftware.com',
       user: 'ubuntu',
       roles: %w[web app db],
       ssh_options: {
         user: 'ubuntu', # overrides user setting above
         port: 22,
         keys: %w[sshkey.pem],
         forward_agent: false,
         auth_methods: %w[publickey]
       }
