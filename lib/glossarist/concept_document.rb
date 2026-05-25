# frozen_string_literal: true

module Glossarist
  class ConceptDocument < Lutaml::Model::Serializable
    attribute :concept, ManagedConcept
    attribute :localizations, LocalizedConcept, collection: true

    yamls do
      sequence do
        map_document 0, to: :concept, type: ManagedConcept
        map_document 1.., to: :localizations, type: LocalizedConcept,
                                           collection: true
      end
    end

    def self.from_managed_concept(managed_concept)
      new(
        concept: managed_concept,
        localizations: managed_concept.localizations&.values || [],
      )
    end

    def self.for_version(version)
      case version.to_s
      when "2"
        require_relative "v2"
        V2::ConceptDocument
      else
        require_relative "v3"
        V3::ConceptDocument
      end
    end

    def to_managed_concept
      mc = concept
      localizations.each { |l10n| mc.add_localization(l10n) }
      mc
    end
  end
end
