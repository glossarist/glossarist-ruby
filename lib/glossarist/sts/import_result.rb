# frozen_string_literal: true

module Glossarist
  module Sts
    DuplicateConflict = Struct.new(:new_concept, :existing_concept, :key,
                                   keyword_init: true)

    class ImportResult
      attr_reader :concepts, :conflicts, :source_files, :skipped_count

      def initialize(concepts:, conflicts: [], source_files: [],
skipped_count: 0)
        @concepts = concepts
        @conflicts = conflicts
        @source_files = source_files
        @skipped_count = skipped_count
      end

      def conflict?
        !conflicts.empty?
      end
    end
  end
end
