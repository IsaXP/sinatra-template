#========================
#CONFIG
#========================
set :application, "APP_NAME"
set :scm, :git
set :git_enable_submodules, 1
set :repository, "GIT_URL"
set :branch, "master"
set :ssh_options, { :forward_agent => true }
 
set :stage, :production
set :user, "deploy"
set :use_sudo, false
set :runner, "deploy"
set :deploy_to, "/data/apps/#{stage}/#{application}"
set :app_server, :passenger
set :domain, "DOMAIN_URL"
 
#========================
#ROLES
#========================
role :app, domain
role :web, domain
role :db, domain, :primary => true

#========================
#CUSTOM
#========================

after "deploy:cold" do
  admin.symlink_config
  admin.nginx_restart
end

namespace :deploy do
  task :start, :roles => :app do
    run "touch #{current_release}/tmp/restart.txt"
  end
 
  task :stop, :roles => :app do
    # Do nothing. (as we run passenger)
  end
 
  desc "Restart Application"
  task :restart, :roles => :app, :except: { :no_release => true } do
    run "touch #{current_release}/tmp/restart.txt"
  end

  # This will make sure that Capistrano doesn't try to run rake:migrate (this is not a Rails project!)
  task :cold do
    deploy.update
    deploy.start
  end
end

#Additional tasks
namespace :admin do
  desc "Link to nginx configuration."
  task :symlink_config, roles: :app do
    run "#{sudo} ln -nfs #{deploy_to}/current/config/nginx.server /etc/nginx/site-enabled/#{application}"
  end

  desc "Unlink (delete) server config."
  task :unlink_config, role: :app do
    run "#{sudo} rm /etc/nginx/site-enabled/#{application}"
  end

  desc "Restart Nginx."
  task :nginx_restart, roles: :app do
    run "#{sudo} service nginx restart"
  end
end