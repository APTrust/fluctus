# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

Fluctus::Application.load_tasks

# Get rid of the default task (was spec)
task :default => []; Rake::Task[:default].clear

task :ci => ['jetty:clean', 'fluctus:travis']
task :default => [:ci]

