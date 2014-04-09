# server 'backend01.tulp.ru', user: 'tulp', roles: %w/app db/
# server 'backend02.tulp.ru', user: 'tulp', roles: %w/app db/
# server 'frontend01.tulp.ru', user: 'tulp', roles: %w/web/
set :stage, :production
set :branch, ENV['PRODUCTION_BRANCH'] || 'master'

