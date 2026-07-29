# frozen_string_literal: true

require "lutaml/model"

module Glossarist
  module Rdf
    # RDF view for V3::GenericMember. Emits a gloss:GenericMember
    # subject carrying the ConceptRef target plus the ISO 704:2022
    # orthogonal dimensions (presence, count, is_delimiting).
    #
    # Mirror of GlossPartitiveMember. Separate RDF class so SPARQL
    # queries can distinguish genus/species decompositions from
    # whole/part decompositions.
    class GlossGenericMember < Lutaml::Model::Serializable
      attribute :ref_id, :string
      attribute :ref_source, :string
      attribute :ref_text, :string
      attribute :presence, :string
      attribute :count, :string
      attribute :is_delimiting, :boolean

      rdf do
        namespace Namespaces::GlossaristNamespace

        subject { |m| "genericMember/#{GlossGenericMember.deterministic_id(m)}" }

        types "gloss:GenericMember"

        predicate :refSource, namespace: Namespaces::GlossaristNamespace,
                              to: :ref_source
        predicate :refId, namespace: Namespaces::GlossaristNamespace,
                          to: :ref_id
        predicate :refText, namespace: Namespaces::GlossaristNamespace,
                            to: :ref_text
        predicate :presence, namespace: Namespaces::GlossaristNamespace,
                             to: :presence
        predicate :count, namespace: Namespaces::GlossaristNamespace,
                          to: :count
        predicate :isDelimiting, namespace: Namespaces::GlossaristNamespace,
                                 to: :is_delimiting
      end

      def self.deterministic_id(member)
        readable = [member.ref_source, member.ref_id].compact.reject(&:empty?)
        return readable.join(":") unless readable.empty?

        DeterministicSlug.from_parts(
          member.ref_source, member.ref_id, member.ref_text,
          member.presence, member.count, member.is_delimiting
        )
      end
    end
  end
end
