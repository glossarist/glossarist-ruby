# frozen_string_literal: true

module Glossarist
  # Inline mentions — fully declarative {{kind:target}} syntax per
  # concept-model docs/design/inline-mentions.md.
  #
  # Every mention target is a CANONICAL IDENTIFIER. No magic
  # combinations, no bare text, no procedural indirection. The parser
  # REJECTS any non-declarative form with a clear error.
  module Mentions
    autoload :InvalidMentionError, "glossarist/mentions/invalid_mention_error"
    autoload :Parser,              "glossarist/mentions/parser"
    autoload :Resolver,            "glossarist/mentions/resolver"
  end
end
