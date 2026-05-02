# frozen_string_literal: true

module Glossarist
  class ResolutionAdapter
    class Local < ResolutionAdapter
      attr_reader :index, :concepts

      def initialize(concepts)
        super()
        @concepts = concepts
        @index = {}
        build_index
      end

      def resolve(reference)
        case reference.ref_type
        when "local"
          resolve_by_id(reference.concept_id)
        when "designation"
          resolve_by_designation(reference.term)
        else
          resolve_by_id(reference.concept_id) if reference.concept_id
        end
      end

      def resolve_by_id(concept_id)
        @index[concept_id]
      end

      def resolve_by_designation(term)
        return nil unless term

        downcased = term.downcase
        concepts.find do |concept|
          designations_for(concept).any? { |d| d&.downcase == downcased }
        end
      end

      private

      def designations_for(concept)
        concept.each_value.flat_map do |lang_block|
          next [] unless lang_block.is_a?(Hash) && lang_block.key?("terms")

          Array(lang_block["terms"]).filter_map { |t| t["designation"] }
        end
      end

      def build_index
        concepts.each do |concept|
          termid = (concept["termid"] || concept["id"])&.to_s
          @index[termid] = concept if termid
        end
      end
    end
  end
end
