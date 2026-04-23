# frozen_string_literal: true

# (c) Copyright 2021 Ribose Inc.
#

require "rspec/matchers"
require "tmpdir"
require_relative "../lib/glossarist"

Bundler.require(:development)

Dir["./spec/support/**/*.rb"].sort.each { |file| require file }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  config.expect_with :rspec do |c|
    c.syntax = [:should, :expect]
  end
end

require "nokogiri"
Lutaml::Model::Config.configure do |config|
  config.xml_adapter_type = :nokogiri
end

require "canon"
Canon::Config.configure do |config|
  config.xml.match.profile = :spec_friendly
  config.xml.diff.use_color = true
end
