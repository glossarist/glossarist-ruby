# frozen_string_literal: true

# (c) Copyright 2021 Ribose Inc.
#

require "psych"

require_relative "glossarist/version"

require_relative "glossarist/model"
require_relative "glossarist/concept"
require_relative "glossarist/collection"
require_relative "glossarist/designations"
require_relative "glossarist/localized_concept"

module Glossarist
  class Error < StandardError; end
  # Your code goes here...
end
