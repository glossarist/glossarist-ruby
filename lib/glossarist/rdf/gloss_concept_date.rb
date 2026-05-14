# frozen_string_literal: true

require "lutaml/model"

module Glossarist
  module Rdf
    class GlossConceptDate < Lutaml::Model::Serializable
      attribute :date_value, :string
      attribute :date_type, :string
      attribute :concept_id, :string

      rdf do
        namespace Namespaces::GlossaristNamespace

        subject { |d| "concept/#{d.concept_id}/date/#{d.date_type}" }

        types "gloss:ConceptDate"

        predicate :dateValue, namespace: Namespaces::GlossaristNamespace, to: :date_value
        predicate :dateType, namespace: Namespaces::GlossaristNamespace, to: :date_type, as: :uri
      end
    end
  end
end
