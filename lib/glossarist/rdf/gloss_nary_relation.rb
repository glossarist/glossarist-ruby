# frozen_string_literal: true

require "lutaml/model"

module Glossarist
  module Rdf
    # Shared base for typed n-ary relation RDF views
    # (GlossPartitiveRelation, GlossGenericRelation, future leaves).
    #
    # Concrete leaves override the `rdf do` block to declare their
    # type-specific subject prefix, `types` declaration, member-class
    # attribute, and link predicate name. The deterministic_id and
    # criterion_fingerprint algorithms are inherited unchanged.
    class GlossNaryRelation < Lutaml::Model::Serializable
      attribute :identifier, :string
      attribute :comprehensive_uri, :string
      attribute :completeness, :string
      attribute :criterion, :hash

      rdf do
        namespace Namespaces::GlossaristNamespace

        predicate :comprehensive, namespace: Namespaces::GlossaristNamespace,
                                  to: :comprehensive_uri, uri_reference: true
        predicate :completeness, namespace: Namespaces::GlossaristNamespace,
                                 to: :completeness, uri_reference: true
        predicate :criterion, namespace: Namespaces::GlossaristNamespace,
                              to: :criterion
      end

      # Content-derived subject identifier. Combines identifier,
      # comprehensive_uri, completeness, criterion fingerprint, and
      # each member fingerprint. Same content → same hash across
      # instances, runs, and processes.
      #
      # Concrete subclasses override to specify the member attribute
      # name and member deterministic_id callable.
      def self.deterministic_id(_relation)
        raise NotImplementedError,
              "#{name}.deterministic_id must be overridden by the concrete leaf"
      end

      # Stable, ordering-insensitive fingerprint of a localized
      # criterion hash. Two relations with the same comprehensive,
      # completeness, and criterion produce the same fingerprint
      # regardless of hash-iteration order.
      def self.criterion_fingerprint(criterion)
        return nil unless criterion.is_a?(Hash) && !criterion.empty?

        criterion.sort_by { |k, _| k.to_s }
          .map { |k, v| "#{k}=#{v}" }
          .join(";")
      end
    end
  end
end
