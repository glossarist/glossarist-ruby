# frozen_string_literal: true

module Glossarist
  module Collections
    class LocalizationCollection < Lutaml::Model::Collection
      instances :localized_concepts, LocalizedConcept

      index_by :language_code

      def [](lang_code)
        find_by(:language_code, lang_code.to_s)
      end

      def store(lang_code, localized_concept)
        localized_concept.language_code ||= lang_code.to_s
        push(localized_concept)
        localized_concept
      end

      def keys
        map(&:language_code)
      end

      def values
        to_a
      end

      def each_key(&block)
        keys.each(&block)
      end

      def each_value(&block)
        values.each(&block)
      end
    end
  end
end
