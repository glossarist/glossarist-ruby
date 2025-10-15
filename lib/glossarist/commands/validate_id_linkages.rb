module Glossarist
  module Commands
    class ValidateIdLinkages < Base
      def run
        output_content = []
        validate_id_linkages(options[:concept_path], output_content)
        output(output_content)
      end

      def validate_id_linkages(concept_path, output_content) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/AbcSize, Metrics/MethodLength
        output_content << "Validate ID linkages:"
        output_content << "-" * 40

        Dir.glob(concepts_glob(concept_path)) do |filename|
          output_content << "Validating file: #{relative_path(filename)}"

          mixed_hashes = YAML.load_stream(File.read(filename))

          main_concept = find_concept(mixed_hashes)
          if main_concept.nil?
            output_content << "No main concept found."
            next
          end

          missing_cid = []
          main_concept["data"]["localized_concepts"].each_value do |loc_cid|
            localized_concept = find_localized_concept(mixed_hashes, loc_cid)
            unless localized_concept
              missing_cid << loc_cid
            end
          end

          output_content << if missing_cid.empty?
                              "No missing localized concepts found."
                            else
                              "Missing localized concepts with IDs: " \
                                                "#{missing_cid.join(', ')}"
                            end
        end

        output_content << "-" * 40
      end

      def find_localized_concept(concept_hash, localized_concept_id)
        concept_hash.find { |c| c["id"] == localized_concept_id }
      end

      def find_concept(concept_hash)
        concept_hash.find { |c| !c["data"]["localized_concepts"].nil? }
      end

      def concepts_glob(path)
        return path if File.file?(path)

        File.join(path, "*.{yaml,yml}")
      end
    end
  end
end
