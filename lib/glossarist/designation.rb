# frozen_string_literal: true

module Glossarist
  module Designation
    autoload :Base,              "glossarist/designation/base"
    autoload :Expression,        "glossarist/designation/expression"
    autoload :Abbreviation,      "glossarist/designation/abbreviation"
    autoload :GrammarInfo,       "glossarist/designation/grammar_info"
    autoload :Symbol,            "glossarist/designation/symbol"
    autoload :GraphicalSymbol,   "glossarist/designation/graphical_symbol"
    autoload :LetterSymbol,      "glossarist/designation/letter_symbol"

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
