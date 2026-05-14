# frozen_string_literal: true

require "lutaml/model"

module Glossarist
  module Rdf
    class GlossPronunciation < Lutaml::Model::Serializable
      attribute :content, :string
      attribute :language, :string
      attribute :script, :string
      attribute :country, :string
      attribute :system, :string
      attribute :concept_id, :string
      attribute :lang_code, :string
      attribute :index, :string

      rdf do
        namespace Namespaces::GlossaristNamespace

        subject { |p| "concept/#{p.concept_id}/#{p.lang_code}/pronunciation/#{p.index}" }

        types "gloss:Pronunciation"

        predicate :pronunciationContent, namespace: Namespaces::GlossaristNamespace, to: :content
        predicate :pronunciationLanguage, namespace: Namespaces::GlossaristNamespace, to: :language
        predicate :pronunciationScript, namespace: Namespaces::GlossaristNamespace, to: :script
        predicate :pronunciationCountry, namespace: Namespaces::GlossaristNamespace, to: :country
        predicate :pronunciationSystem, namespace: Namespaces::GlossaristNamespace, to: :system
      end
    end
  end
end
