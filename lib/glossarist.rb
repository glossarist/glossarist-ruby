# frozen_string_literal: true

require "active_model"

require_relative "glossarist/model"
require_relative "glossarist/version"

require_relative "glossarist/designations"
require_relative "glossarist/localized_concept"

module Glossarist
  class Error < StandardError; end
  # Your code goes here...
end
