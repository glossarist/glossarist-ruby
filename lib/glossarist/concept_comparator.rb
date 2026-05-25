# frozen_string_literal: true

module Glossarist
  class ConceptComparator
    def initialize(new_concepts:, old_concepts:)
      @new_concepts = new_concepts
      @old_concepts = old_concepts
    end

    def compare(show_diffs: true)
      new_index = build_index(@new_concepts)
      old_index = build_index(@old_concepts)

      matched_ids = new_index.keys & old_index.keys
      new_only_ids = new_index.keys - old_index.keys
      old_only_ids = old_index.keys - new_index.keys

      diffs = if show_diffs
                compute_diffs(matched_ids, new_index, old_index)
              else
                []
              end

      ComparisonResult.new(
        new_count: @new_concepts.length,
        old_count: @old_concepts.length,
        matched: matched_ids.sort,
        new_only: new_only_ids.sort,
        old_only: old_only_ids.sort,
        diffs: diffs,
      )
    end

    private

    def build_index(concepts)
      concepts.each_with_object({}) do |concept, index|
        id = extract_id(concept)
        index[id] = concept if id
      end
    end

    def extract_id(concept)
      concept.data&.id || concept.id
    end

    def compute_diffs(matched_ids, new_index, old_index)
      matched_ids.filter_map do |id|
        new_concept = new_index[id]
        old_concept = old_index[id]

        score, tree = Lutaml::Model::Serialize.diff_with_score(
          new_concept, old_concept,
          show_unchanged: false,
          highlight_diff: false,
          indent: ""
        )
        similarity = ((1 - score) * 100).round(2)

        ConceptDiff.new(
          concept_id: id,
          similarity: similarity,
          diff_tree: strip_ansi(tree),
        )
      end.sort_by { |d| -d.similarity }
    end

    def strip_ansi(text)
      text.gsub(/\e\[[0-9;]*m/, "")
    end
  end
end
