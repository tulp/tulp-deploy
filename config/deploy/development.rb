import 'lib/dummy.rb'

set :stage, :development
set :scm, :dummy
set :keep_releases, 1
server ENV['SERVER'] || 'localhost', user: 'tulp', roles: %w/web app db sphinx/
set :bundle_without, nil
set :bundle_flags, '--verbose'
set :branch, ENV['REVISION'] || ENV['BRANCH'] || 'master'

