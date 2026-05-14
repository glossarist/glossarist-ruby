# frozen_string_literal: true

# Extends Lutaml::Rdf::MemberRule with `inline:` and `link:` options.
#
# Usage:
#   members :localizations, link: "gloss:hasLocalization"
#   members :designations, link: ->(d) { skosxl_predicate_for(d) }
#   members :definitions, link: "gloss:hasDefinition"
#   members :sources                                # no linking predicate
module Lutaml
  module Rdf
    class MemberRule
      attr_reader :attr_name, :inline, :link

      def initialize(attr_name, inline: true, link: nil)
        @attr_name = attr_name.to_sym
        @inline = inline
        @link = link
      end

      def link_predicate_for(member, mapping)
        return nil unless @link

        case @link
        when String
          mapping.namespace_set.resolve_compact_iri(@link)
        when Proc
          uri = @link.call(member)
          uri.include?(":") ? mapping.namespace_set.resolve_compact_iri(uri) : uri
        end
      end
    end
  end
end
