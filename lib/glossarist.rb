# frozen_string_literal: true

# (c) Copyright 2021 Ribose Inc.
#

require "psych"
require "thor"
require "lutaml/model"

require_relative "glossarist/utilities"
require_relative "glossarist/version"
require_relative "glossarist/glossary_definition"

require_relative "glossarist/designation"
require_relative "glossarist/asset"
require_relative "glossarist/citation"
require_relative "glossarist/collection"
require_relative "glossarist/concept_date"
require_relative "glossarist/concept_manager"
require_relative "glossarist/concept_set"
require_relative "glossarist/concept_source"
require_relative "glossarist/detailed_definition"
require_relative "glossarist/related_concept"
require_relative "glossarist/concept_data"
require_relative "glossarist/concept"
require_relative "glossarist/localized_concept"
require_relative "glossarist/managed_concept_data"
require_relative "glossarist/managed_concept"
require_relative "glossarist/managed_concept_collection"
require_relative "glossarist/non_verb_rep"

require_relative "glossarist/collections"

require_relative "glossarist/config"
require_relative "glossarist/error"

module Glossarist
  def self.configure
    config = Glossarist::Config.instance

    yield(config) if block_given?
  end
end
