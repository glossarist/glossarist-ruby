module Glossarist
  module Collections
    class ReferenceCollection
      URN_REFERENCE_REGEX = /{{(urn:[^,}]*),?([^,}]*),?([^}]*)?}}/.freeze
      REFERENCE_REGEX = /(?:&lt;|<){2}((?!:&gt;:&gt;).*?)(?:&gt;|>){2}/.freeze

      def initialize(concepts)
        @reference_map = {}

        concepts.each do |concept|
          add_references_for_concept(concept)
        end
      end

      private

      def add_references_for_concept
        return if text.nil?

        text.scan(URN_REFERENCE_REGEX) do |reference|
          urn = Regexp.last_match[1]

          if !urn || urn.empty?
            reference
          else
            @reference_map[reference] ||= {
              urn: urn,
              term_referenced: Regexp.last_match[2],
              term_to_show: Regexp.last_match[3],
            }
          end
        end
      end
    end
  end
end
