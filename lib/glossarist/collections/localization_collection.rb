# frozen_string_literal: true

module Glossarist
  module Collections
    class LocalizationCollection < Lutaml::Model::Collection
      instances :localized_concepts, LocalizedConcept

      index_by :language_code

      alias :length :size

      def [](lang_code)
        find_by(:language_code, lang_code.to_s)
      end

      def store(lang_code, localized_concept)
        localized_concept.language_code ||= lang_code.to_s
        # One localization per language: storing the same language again
        # replaces it, so a concept attached twice is not duplicated.
        position = to_a.index do |l10n|
          l10n.language_code == localized_concept.language_code
        end
        position ? collection[position] = localized_concept : push(localized_concept)
        build_index_caches!
        localized_concept
      end

      def keys
        map(&:language_code)
      end

      def values
        to_a
      end

      def each_key(&)
        keys.each(&)
      end

      def each_value(&)
        values.each(&)
      end
    end
  end
end
