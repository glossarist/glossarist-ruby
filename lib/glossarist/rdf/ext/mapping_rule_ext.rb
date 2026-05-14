# frozen_string_literal: true

# Extends Lutaml::Rdf::MappingRule with `as:` option for URI-valued predicates.
#
# Usage:
#   predicate :hasStatus, namespace: Ns, to: :status, as: :uri
#   predicate :name, namespace: Ns, to: :name                   # default: :literal
module Lutaml
  module Rdf
    class MappingRule
      attr_reader :as

      def initialize(predicate_name, namespace:, to:, lang_tagged: false, as: :literal)
        validate!(predicate_name, namespace, to)
        @predicate_name = predicate_name.to_s.freeze
        @namespace = namespace
        @to = to
        @lang_tagged = lang_tagged
        @as = as
      end

      def uri_value?
        @as == :uri
      end
    end
  end
end
