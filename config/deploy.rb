set :repo_url, "git@github.com:biodivportal/ncbo_cron.git"
set :user, 'ontoportal'

set :deploy_to, '/srv/ontoportal/ncbo_cron_deployments'


set :stages, %w[appliance]
set :default_stage, 'appliance'
set :stage, 'appliance'
set :application, 'cron'

# SSH parameters
set :ssh_port, 22
set :pty, true

# Source code
set :repository_cache, "git_cache"
set :deploy_via, :remote_cache
set :ssh_options, { :forward_agent => true }

# Linked files and directories
append :linked_files, "config/config.rb"
append :linked_dirs, 'logs', '.bundle'
set :keep_releases, 2


