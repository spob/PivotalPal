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


# if you're still using the script/reaper helper you will need
# these http://github.com/rails/irs_process_scripts

after "deploy", "deploy:bundle_gems"
after "deploy:bundle_gems", "deploy:migrate"
after "deploy:migrate", "deploy:cleanup"
after "deploy:cleanup", "deploy:precompile"
after "deploy:precompile", "deploy:restart"

# If you are using Passenger mod_rails uncomment this:
namespace :deploy do
   task :bundle_gems do
     run "cp #{shared_path}/application.rb #{current_path}/config/application.rb"
     run "ln -nfs #{shared_path}/gems #{current_path}/vendor/bundle"
     run "cd #{deploy_to}/current && bundle install --deployment"
   end
   task :precompile do
     #load 'deploy/assets'
    run "cd #{deploy_to}/current && rake assets:precompile"
   end
   task :migrate do
     run "cp #{shared_path}/config.rb #{current_path}/config/initializers/config.rb"
     run "cp #{shared_path}/database.yml #{current_path}/config/database.yml"
     run "cd #{deploy_to}/current && rake db:migrate"
   end
   task :start do ; end
   task :stop do ; end
   task :restart, :roles => :app, :except => { :no_release => true } do
     run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
   end
end
