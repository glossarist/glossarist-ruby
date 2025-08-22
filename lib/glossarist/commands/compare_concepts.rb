module Glossarist
  module Commands
    class CompareConcepts < Base
      def compare_file_counts(new_concepts, old_concepts, output_content) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/AbcSize, Metrics/MethodLength
        new_count = new_concepts.managed_concepts.count
        old_count = old_concepts.managed_concepts.count

        output_content << "Comparing concept counts:"
        output_content << "-" * 40
        output_content << "New concepts: #{new_count} | " \
                          "Old concepts: #{old_count}"

        diff = new_count - old_count
        output_content << if diff.positive?
                            "New concepts added: #{diff}"
                          elsif diff.negative?
                            "Old concepts removed: #{-diff}"
                          else
                            "No change in concept counts."
                          end

        output_content << "-" * 40
      end

      def compare_mapped_concepts(new_concepts, old_concepts, output_content) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/AbcSize, Metrics/MethodLength
        output_content << "Comparing concepts:"
        output_content << "-" * 40

        new_concepts.each do |new_concept|
          old_concept = find_concept_by_id(old_concepts, new_concept.id)

          if old_concept
            diff_score, diff_tree = Lutaml::Model::Serialize.diff_with_score(
              new_concept,
              old_concept,
              show_unchanged: false,
              highlight_diff: true,
              use_colors: false,
              indent: "",
            )
            similarity_percentage = (1 - diff_score) * 100

            output_content << "Diff Tree of #{new_concept.id} with " \
                              "Similarity score: #{similarity_percentage.round(2)}%:"
            output_content << "-" * 30
            output_content << diff_tree
            output_content << "-" * 30
          end
        end

        output_content << "-" * 40
      end

      def show_mapping(new_concepts, old_concepts, output_content) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/AbcSize, Metrics/MethodLength
        output_content << "Mapping new concepts to old concepts:"
        output_content << "-" * 40

        # find the mapping of new concepts to old concepts
        not_mapped_new_ids = []
        new_concepts.each do |concept|
          mapped_old_concept = find_concept_by_id(old_concepts, concept.id)

          if mapped_old_concept
            output_content << "#{concept.id} | #{mapped_old_concept.id}"
          else
            not_mapped_new_ids << concept.id
          end
        end

        # find the mapping of old concepts to new concepts
        not_mapped_old_ids = []
        old_concepts.each do |concept|
          mapped_new_concepts = find_concept_by_id(new_concepts, concept.data.id)

          if mapped_new_concepts.nil?
            not_mapped_old_ids << concept.data.id
          end
        end

        unless not_mapped_new_ids.empty?
          output_content << "-" * 40
          output_content << "Not mapped new concepts (count: #{not_mapped_new_ids.count}):"
          output_content << "-" * 40
          not_mapped_new_ids.each do |id|
            output_content << id
          end
        end

        unless not_mapped_old_ids.empty?
          output_content << "-" * 40
          output_content << "Not mapped old concepts (count: #{not_mapped_old_ids.count}):"
          output_content << "-" * 40
          not_mapped_old_ids.each do |id|
            output_content << id
          end
        end

        output_content << "-" * 40
      end

      def find_concept_by_id(old_concepts, id)
        old_concepts.find do |concept|
          concept.data.id == id
        end
      end

      def compare_concepts(new_concepts, old_concepts, output_content)
        compare_file_counts(new_concepts, old_concepts, output_content)
        show_mapping(new_concepts, old_concepts, output_content)
        compare_mapped_concepts(new_concepts, old_concepts, output_content)
      end

      def run
        new_concepts = load_concepts(options[:new_concept_path])
        old_concepts = load_concepts(options[:old_concept_path])

        output_content = []
        compare_concepts(new_concepts, old_concepts, output_content)
        output(output_content)
      end
    end
  end
end
