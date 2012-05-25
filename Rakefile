require "bundler/gem_tasks"
require 'rspec/core/rake_task'

$:.unshift('lib')

RSpec::Core::RakeTask.new do |t|
  t.pattern = "./test/unit/*.rb"
end

desc "Run tests"
task :default => :spec
