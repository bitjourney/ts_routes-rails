require "bundler/gem_tasks"
require "rake/testtask"

Bundler.setup
load "rails/tasks/routes.rake"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

namespace :test do
  desc 'Show routes for tests'
  task :routes do
    Dir["#{__dir__}/test/support/**/*.rb"].sort.each { |f| require f }
    require 'action_dispatch/routing/inspector'

    all_routes = Rails.application.routes.routes
    inspector = ActionDispatch::Routing::RoutesInspector.new(all_routes)
    puts inspector.format(ActionDispatch::Routing::ConsoleFormatter.new, ENV['CONTROLLER'])
  end
end

task :default => :test
