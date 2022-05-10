# frozen_string_literal: true

# (c) Copyright 2021 Ribose Inc.
#

require "psych"

require_relative "glossarist/utilities"
require_relative "glossarist/version"
require_relative "glossarist/glossary_definition"

require_relative "glossarist/model"
require_relative "glossarist/concept_date"
require_relative "glossarist/detailed_definition"
require_relative "glossarist/related_concept"
require_relative "glossarist/ref"
require_relative "glossarist/concept_source"
require_relative "glossarist/collection"
require_relative "glossarist/designation"
require_relative "glossarist/concept"
require_relative "glossarist/localized_concept"
require_relative "glossarist/managed_concept_collection"
require_relative "glossarist/concept_manager"
require_relative "glossarist/managed_concept"
require_relative "glossarist/non_verb_rep"

module Glossarist
  class Error < StandardError; end
  class InvalidTypeError < StandardError; end
  # Your code goes here...
end
