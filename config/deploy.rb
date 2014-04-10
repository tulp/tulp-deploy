# config valid only for Capistrano 3.1
lock '3.1.0'

SSHKit.config.command_map[:rake] = "bundle exec rake"

set :application, 'tulp'
set :user, 'tulp'
set :repo_url, 'git@github.com:tulp/tulp.git'

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }

# Default deploy_to directory is /var/www/my_app
set :deploy_to, "/srv/#{fetch(:application)}-application" 
set :repo_path, "#{fetch(:shared_path)}/cached-copy"

# force 
set :force_assets, fetch(:force_assets, ENV['ASSETS'])

# Default value for :scm is :git
set :scm, :git

# Default value for :format is :pretty
set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
set :linked_files, %w(
  config/database.yml 
  config/unicorn.rb 
  config/redis_config.rb 
  config/sphinx.yml 
  config/newrelic.yml
)

# Default value for linked_dirs is []
set :linked_dirs, %w{
  bin 
  log 
  tmp/pids 
  tmp/cache 
  tmp/sockets 
  public/system 
  public/robots 
  db/sphinx
}

# Default value for default_env is {}
set :default_env, { 
  path: "/usr/local/bin:/usr/bin:/bin", 
  home: '/home/tulp',
  rails_env: fetch(:stage).to_s
}

set :assets_paths, %w[vendor/assets app/assets]
set :git_log_cmd, "git log #{fetch(:previous_revision,'HEAD')}..#{fetch(:current_revision, 'HEAD')}"        

def if_changed?(paths)
  capture(
    :git, :log, 
    fetch(:previous_revision, 'HEAD'), '..', fetch(:current_revision, 'HEAD'),
    paths.join(' '), '| wc -l').to_i > 0
end

# default ssh options
set :ssh_options, {
  forward_agent: true
}

# Default value for keep_releases is 5
# set :keep_releases, 5

namespace :deploy do

  desc "Start application"
  task :start do
    on roles(:app), in: :sequence, wait: 5 do
      execute :sudo, :sv, "start", "tulp_rails" 
      execute :sudo, :sv, "start", "tulp_resque_1"
    end    
  end

  desc "Stop application"
  task :stop do
    on roles(:app), in: :sequence, wait: 5 do
      execute :sudo, :sv, "-w 60", "stop", "tulp_rails" 
      execute :sudo, :sv, "-w 60", "stop", "tulp_resque_1"
    end    
  end

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute :sudo, :sv, "-w 60", '2', "tulp_rails" 
      execute :sudo, :sv, "-w 60", 'restart', "tulp_resque_1"
    end
  end

  after :publishing, :restart
  after :finishing, "deploy:cleanup"

  Rake::Task['deploy:compile_assets'].clear

  task :compile_assets => [:set_rails_env] do
    on roles(:web), in: :parallel do
      within release_path do
        if fetch(:force_assets) || is_changed?(fetch(:assets_paths))
          Rake::Task['deploy:assets:precompile'].invoke
          Rake::Task['deploy:assets:backup_manifest'].invoke
        else
          info "[SKIP] deploy:assets:precompile"
        end
      end
    end
  end
end

