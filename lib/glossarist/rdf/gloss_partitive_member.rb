# frozen_string_literal: true

require "digest"
require "lutaml/model"

module Glossarist
  module Rdf
    # RDF view for V3::PartitiveMember. Emits a gloss:PartitiveMember
    # subject carrying the ConceptRef target plus the ISO 704:2022
    # orthogonal dimensions (presence, count, is_delimiting).
    #
    # Subject identity is content-derived so the same member in the
    # same relation produces the same URI across runs (and across
    # processes). Two members with identical ref + dimensions share a
    # subject — that is intentional: it exposes model-level
    # inconsistency if the same partitive concept is given different
    # dimensions inside the same dataset.
    class GlossPartitiveMember < Lutaml::Model::Serializable
      attribute :ref_id, :string
      attribute :ref_source, :string
      attribute :ref_text, :string
      attribute :presence, :string
      attribute :count, :string
      attribute :is_delimiting, :boolean

      rdf do
        namespace Namespaces::GlossaristNamespace

        subject { |m| "partitiveMember/#{GlossPartitiveMember.deterministic_id(m)}" }

        types "gloss:PartitiveMember"

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

        parts = [member.ref_source, member.ref_id, member.ref_text,
                 member.presence, member.count, member.is_delimiting]
        Digest::MD5.hexdigest(parts.compact.join("|"))[0..11]
      end
    end
  end
end
