set :application, "PivotalPal"
set :repository,  "git@github.com:spob/PivotalPal.git"

set :scm, :git

set :user, 'deploy'
set :use_sudo, false
set :deploy_to, "/var/www/#{application}"
set :deploy_via, :remote_cache

set :keep_releases, 8

role :web, "pivotalpal.sturim.org"                          # Your HTTP server, Apache/etc
role :app, "pivotalpal.sturim.org"                          # This may be the same as your `Web` server
role :db,  "pivotalpal.sturim.org", :primary => true # This is where Rails migrations will run
#role :db,  "your slave db-server here"

# if you want to clean up old releases on each deploy uncomment this:
# after "deploy:restart", "deploy:cleanup"

# if you're still using the script/reaper helper you will need
# these http://github.com/rails/irs_process_scripts

after "deploy", "deploy:bundle_gems"
after "deploy:bundle_gems", "deploy:restart"

# If you are using Passenger mod_rails uncomment this:
namespace :deploy do
   task :bundle_gems do
     run "cd #{deploy_to}/current && bundle install --deployment"
   end
   task :start do ; end
   task :stop do ; end
   task :restart, :roles => :app, :except => { :no_release => true } do
     run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
   end
end
