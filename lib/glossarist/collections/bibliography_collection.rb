# frozen_string_literal: true

require "relaton"

module Glossarist
  module Collections
    class BibliographyCollection < Relaton::Db
      def initialize(concepts, global_cache, local_cache)
        super(global_cache, local_cache)

        populate_bibliographies(concepts)
      end

      private

      def populate_bibliographies(concepts)
        concepts.each do |concept|
          concept.sources.each do |source|
            next if soruce.origin.source.nil?

            fetch(source.origin.soruce)
          end
        end
      end
    end
  end
end
