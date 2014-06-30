# config valid only for Capistrano 3.1
lock '3.2.1'

SSHKit.config.command_map[:rake] = "bundle exec rake"

set :application, 'tulp'
set :user, 'tulp'
set :repo_url, 'git@github.com:tulp/tulp.git'

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }

# Default deploy_to directory is /var/www/my_app
set :deploy_to, "/srv/#{fetch(:application)}-application" 
set :repo_path, "#{fetch(:shared_path)}/cached-copy"

# Default value for :scm is :git
set :scm, :git

# Default value for :format is :pretty
set :format, :pretty

# Default value for :log_level is :debug
set :log_level, :info

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
set :linked_files, %w(
  config/database.yml 
  config/redis_config.rb 
  config/sphinx.yml 
  config/newrelic.yml
).push(*fetch(:linked_files, []))

# Default value for linked_dirs is []
set :linked_dirs, %w{
  bin 
  log 
  tmp/pids 
  tmp/cache 
  tmp/sockets 
  public/system 
  public/assets
  public/sitemaps  
}

# Default value for default_env is {}
set :default_env, { 
  path: "/usr/local/bin:/usr/bin:/bin", 
  home: '/home/tulp',
  rails_env: fetch(:stage).to_s
}

# default ssh options
set :ssh_options, {
  forward_agent: true
}

# Default value for keep_releases is 5
# set :keep_releases, 5

set :whenever_roles, [:db]

namespace :deploy do
  namespace :symlink do
    task :linked_files do
      on roles(:web) do
        file = 'config/unicorn.rb'
        target = release_path.join(file)
        source = shared_path.join(file)
        unless test "[ -L #{target} ]"
          if test "[ -f #{target} ]"
            execute :rm, target
          end
          execute :ln, '-s', source, target
        end
      end
    end      
  end
end

namespace :deploy do

  desc "Start application"
  task :start do
    on roles(:web), in: :sequence, wait: 5 do      
      execute :sudo, :sv, "start", "tulp_rails" 
    end    
    on roles(:resque), in: :sequence, wait: 5 do
      execute :sudo, :sv, "start", "tulp_resque_1"
    end    
  end

  desc "Stop application"
  task :stop do
    on roles(:web), in: :sequence, wait: 5 do
      execute :sudo, :sv, "-w 60", "stop", "tulp_rails" 
    end    
    on roles(:resque), in: :sequence, wait: 5 do
      execute :sudo, :sv, "stop", "tulp_resque_1"
    end    
  end

  desc 'Restart application'
  task :restart do
    on roles(:web), in: :sequence, wait: 5 do
      execute :sudo, :sv, "-w 60", '2', "tulp_rails" 
    end
    on roles(:resque), in: :sequence, wait: 5 do
      execute :sudo, :sv, "-w 60", 'restart', "tulp_resque_1"
    end    
  end

  after :publishing, :restart
  after :finishing, "deploy:cleanup"
end

