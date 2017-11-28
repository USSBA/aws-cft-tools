# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubycritic/rake_task'
require 'yard'

RubyCritic::RakeTask.new do |task|
  # Glob pattern to match source files. Defaults to FileList['.'].
  task.paths = FileList['lib/**/*.rb']
end

RSpec::Core::RakeTask.new(:spec)

YARD::Rake::YardocTask.new

task default: :spec
