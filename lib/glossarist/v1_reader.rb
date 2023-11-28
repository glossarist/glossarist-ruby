# frozen_string_literal: true

module Glossarist
  # An adapter to read concepts in V1 format, converts them to v2 format and
  # load into glossarist concept model.
  class V1Reader
    def self.load_concept_from_file(filename)
      new.load_concept_from_file(filename)
    end

    def load_concept_from_file(filename)
      concept_hash = Psych.safe_load(File.read(filename), permitted_classes: [Date])
      ManagedConcept.new(generate_v2_concept_hash(concept_hash))
    end

    private

    def generate_v2_concept_hash(concept_hash)
      v2_concept = { "groups" => concept_hash["groups"] }
      v2_concept["data"] = {
        "identifier" => concept_hash["termid"],
        "localized_concepts" => concept_hash.values.grep(Hash),
      }

      v2_concept
    end
  end
end
