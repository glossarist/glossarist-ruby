# frozen_string_literal: true

require "lutaml/turtle"
require "lutaml/jsonld"

module Glossarist
  module Rdf
    class SkosConcept < Lutaml::Model::Serializable
      attribute :code, :string
      attribute :labels, LocalizedLiteral, collection: true
      attribute :definitions, LocalizedLiteral, collection: true
      attribute :alt_labels, LocalizedLiteral, collection: true
      attribute :scope_notes, LocalizedLiteral, collection: true
      attribute :sources, :string, collection: true
      attribute :domain, :string
      attribute :date_accepted, :string

      rdf do
        namespace Namespaces::SkosNamespace, Namespaces::DctermsNamespace

        subject { |c| "https://glossarist.org/concept/#{c.code}" }
        type "skos:Concept"

        predicate :notation,     namespace: Namespaces::SkosNamespace,
                                 to: :code
        predicate :prefLabel,    namespace: Namespaces::SkosNamespace,
                                 to: :labels,       lang_tagged: true
        predicate :definition,   namespace: Namespaces::SkosNamespace,
                                 to: :definitions,  lang_tagged: true
        predicate :altLabel,     namespace: Namespaces::SkosNamespace,
                                 to: :alt_labels,   lang_tagged: true
        predicate :scopeNote,    namespace: Namespaces::SkosNamespace,
                                 to: :scope_notes,  lang_tagged: true
        predicate :subject,      namespace: Namespaces::DctermsNamespace,
                                 to: :domain
        predicate :source,       namespace: Namespaces::DctermsNamespace,
                                 to: :sources
        predicate :dateAccepted, namespace: Namespaces::DctermsNamespace,
                                 to: :date_accepted
      end
    end
  end
end
