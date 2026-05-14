# frozen_string_literal: true

require "lutaml/model"

module Glossarist
  module Rdf
    COMMON_DESIGNATION_PREDICATES = lambda { |dsl|
      dsl.predicate :literalForm, namespace: Namespaces::SkosxlNamespace, to: :designation
      dsl.predicate :normativeStatus, namespace: Namespaces::GlossaristNamespace, to: :normative_status, as: :uri
      dsl.predicate :hasTermType, namespace: Namespaces::GlossaristNamespace, to: :term_type, as: :uri
      dsl.predicate :isInternational, namespace: Namespaces::GlossaristNamespace, to: :international
      dsl.predicate :isAbsent, namespace: Namespaces::GlossaristNamespace, to: :absent
      dsl.predicate :geographicalArea, namespace: Namespaces::GlossaristNamespace, to: :language
      dsl.predicate :language, namespace: Namespaces::DctermsNamespace, to: :lang_code
      dsl.predicate :script, namespace: Namespaces::GlossaristNamespace, to: :script
      dsl.predicate :conversionSystem, namespace: Namespaces::GlossaristNamespace, to: :system
      dsl.members :pronunciations, link: "gloss:hasPronunciation"
      dsl.members :sources
    }.freeze

    DESIGNATION_NAMESPACES = [
      Namespaces::GlossaristNamespace,
      Namespaces::SkosxlNamespace,
      Namespaces::SkosNamespace,
      Namespaces::DctermsNamespace,
      Namespaces::IsoThesNamespace,
    ].freeze

    class GlossDesignation < Lutaml::Model::Serializable
      include Relationships

      attribute :designation, :string
      attribute :normative_status, :string
      attribute :type, :string
      attribute :language, :string
      attribute :script, :string
      attribute :system, :string
      attribute :international, :boolean
      attribute :absent, :boolean
      attribute :term_type, :string
      attribute :concept_id, :string
      attribute :lang_code, :string
      attribute :index, :string
      attribute :pronunciations, GlossPronunciation, collection: true
      attribute :sources, GlossConceptSource, collection: true

      rdf do
        namespace(*DESIGNATION_NAMESPACES)

        subject { |d| "concept/#{d.concept_id}/#{d.lang_code}/designation/#{d.index}" }

        types "gloss:Designation", "skosxl:Label"

        COMMON_DESIGNATION_PREDICATES.call(self)
      end
    end

    class GlossExpression < GlossDesignation
      attribute :prefix, :string
      attribute :usage_info, :string
      attribute :field_of_application, :string
      attribute :grammar_info, GlossGrammarInfo, collection: true

      rdf do
        namespace(*DESIGNATION_NAMESPACES)

        subject { |d| "concept/#{d.concept_id}/#{d.lang_code}/designation/#{d.index}" }

        types "gloss:Expression", "skosxl:Label"

        COMMON_DESIGNATION_PREDICATES.call(self)
        predicate :prefix, namespace: Namespaces::GlossaristNamespace, to: :prefix
        predicate :usageInfo, namespace: Namespaces::GlossaristNamespace, to: :usage_info
        predicate :fieldOfApplication, namespace: Namespaces::GlossaristNamespace, to: :field_of_application
        members :grammar_info, link: "gloss:hasGrammarInfo"
      end
    end

    class GlossAbbreviation < GlossExpression
      attribute :acronym, :boolean
      attribute :initialism, :boolean
      attribute :truncation, :boolean

      rdf do
        namespace(*DESIGNATION_NAMESPACES)

        subject { |d| "concept/#{d.concept_id}/#{d.lang_code}/designation/#{d.index}" }

        types "gloss:Abbreviation", "skosxl:Label"

        COMMON_DESIGNATION_PREDICATES.call(self)
        predicate :prefix, namespace: Namespaces::GlossaristNamespace, to: :prefix
        predicate :usageInfo, namespace: Namespaces::GlossaristNamespace, to: :usage_info
        predicate :fieldOfApplication, namespace: Namespaces::GlossaristNamespace, to: :field_of_application
        members :grammar_info, link: "gloss:hasGrammarInfo"
        predicate :isAcronym, namespace: Namespaces::GlossaristNamespace, to: :acronym
        predicate :isInitialism, namespace: Namespaces::GlossaristNamespace, to: :initialism
        predicate :isTruncation, namespace: Namespaces::GlossaristNamespace, to: :truncation
      end
    end

    class GlossSymbol < GlossDesignation
      rdf do
        namespace(*DESIGNATION_NAMESPACES)

        subject { |d| "concept/#{d.concept_id}/#{d.lang_code}/designation/#{d.index}" }

        types "gloss:Symbol", "skosxl:Label"

        COMMON_DESIGNATION_PREDICATES.call(self)
      end
    end

    class GlossLetterSymbol < GlossSymbol
      attribute :text, :string

      rdf do
        namespace(*DESIGNATION_NAMESPACES)

        subject { |d| "concept/#{d.concept_id}/#{d.lang_code}/designation/#{d.index}" }

        types "gloss:LetterSymbol", "skosxl:Label"

        COMMON_DESIGNATION_PREDICATES.call(self)
        predicate :text, namespace: Namespaces::GlossaristNamespace, to: :text
      end
    end

    class GlossGraphicalSymbol < GlossSymbol
      attribute :text, :string
      attribute :image, :string

      rdf do
        namespace(*DESIGNATION_NAMESPACES)

        subject { |d| "concept/#{d.concept_id}/#{d.lang_code}/designation/#{d.index}" }

        types "gloss:GraphicalSymbol", "skosxl:Label"

        COMMON_DESIGNATION_PREDICATES.call(self)
        predicate :text, namespace: Namespaces::GlossaristNamespace, to: :text
        predicate :image, namespace: Namespaces::GlossaristNamespace, to: :image
      end
    end
  end
end
