# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "standard/rake"
require "yard"

YARD::Rake::YardocTask.new

RSpec::Core::RakeTask.new(:spec)

task default: %i[spec standard]
