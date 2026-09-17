# frozen_string_literal: true

require "stringio"
lock "~> 3.20.0"

set :ssh_options, {
  forward_agent: !ENV["CI"],
  port: 39_168,
  auth_methods: %w[publickey]
}
set :repo_url, "git@github.com:WebgateSystems/cvgen_web.git"
set :repository_cache, "git_cache"
set :deploy_via, :remote_cache
set :bundle_without, %w[test development].join(":")
set :pty, !ENV["CI"]

# Avoid using global /tmp for Capistrano uploads/scripts (e.g. capistrano-nvm writes nvm-exec.sh there).
# When staging + production deploy as different users on the same host, stale /tmp files can cause
# "Permission denied" due to sticky bit. Use per-app shared tmp instead.
set :tmp_dir, -> { shared_path.join("tmp") }

# NVM / Node
set :nvm_type, :user
set :nvm_node, "v24.18.1"
# yarn nie mapujemy, bo Yarn 3 jest uruchamiany przez corepack (shim), a nie globalny bin
set :nvm_map_bins, %w[node npm]

# Yarn version required by project (must match package.json "packageManager")
set :yarn_version, "1.22.22"

set :log_level, :info
set :format, :pretty
set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto

set :linked_files,
    %W[config/settings/#{fetch(:stage)}.yml public/robots.txt]
set :linked_dirs, %w[log public/uploads public/assets tmp]

set :keep_releases, 5

# ---- Hooks ----
after "deploy:cleanup", "deploy:restart"

desc "Invoke a rake command on the remote server" # example: cap staging "invoke[db:seed]"
task :invoke, [ :command ] => "deploy:set_rails_env" do |_task, args|
  on primary(:app) do
    within current_path do
      with rails_env: fetch(:rails_env) do
        rake args[:command]
      end
    end
  end
end

# ---- Node/Yarn tasks ----
namespace :node do
  # Pomocniczo: zawsze uruchamiamy komendy z poprawnym PATH do nvm node
  def with_nvm_path(&block)
    nvm_bin_path = "$HOME/.nvm/versions/node/#{fetch(:nvm_node)}/bin"
    with path: "#{nvm_bin_path}:$PATH", &block
  end

  desc "Build frontend assets"
  task :build do
    on roles(:web) do
      within release_path do
        with_nvm_path do
          execute :npm, "run build"
          execute :npm, "run build:css"
        end
      end
    end
  end
end

namespace :deploy do
  task :restart do
    on roles(:web) do
      execute("~#{fetch(:deploy_user)}/bin/#{fetch(:stage)}.sh", :restart)
    end
  end

  namespace :assets do
    Rake::Task["precompile"].clear_actions

    desc "Precompile assets"
    task :precompile do
      on roles(:web) do
        within release_path do
          with rails_env: fetch(:rails_env) do
            nvm_bin_path = "$HOME/.nvm/versions/node/#{fetch(:nvm_node)}/bin"
            with path: "#{nvm_bin_path}:$PATH" do
              rake "assets:precompile"
            end
          end
        end
      end
    end
  end
end
