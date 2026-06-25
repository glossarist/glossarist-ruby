# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

Dir.glob(File.expand_path("lib/glossarist/tasks/*.rake", __dir__)).each do |f|
  load f
end

task default: :spec
