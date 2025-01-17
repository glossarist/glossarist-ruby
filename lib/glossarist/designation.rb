# frozen_string_literal: true

# (c) Copyright 2021 Ribose Inc.
#

require_relative "designation/base"
require_relative "designation/expression"
require_relative "designation/abbreviation"
require_relative "designation/grammar_info"
require_relative "designation/symbol"
require_relative "designation/graphical_symbol"
require_relative "designation/letter_symbol"

module Glossarist
  module Designation
    # Bi-directional class-to-string mapping for STI-like serialization.
    SERIALIZED_TYPES = {
      Expression => "expression",
      Symbol => "symbol",
      Abbreviation => "abbreviation",
      GraphicalSymbol => "graphical_symbol",
      LetterSymbol => "letter_symbol",
    }
      .tap { |h| h.merge!(h.invert) }
      .freeze
  end
end
