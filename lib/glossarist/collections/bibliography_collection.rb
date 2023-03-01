# frozen_string_literal: true

require "relaton"

module Glossarist
  module Collections
    class BibliographyCollection < Relaton::Db
      def initialize(concepts, global_cache, local_cache)
        super(global_cache, local_cache)
      end

      private

      def populate_bibliographies(concepts)
        concepts.each do |concept|
          concept.default_lang.sources.each do |source|
            next if source.origin.text.nil?

            fetch(source.origin.text)
          end
        end
      end
    end
  end
end
