# frozen_string_literal: true

module Glossarist
  module Collections
    class DetailedDefinitionCollection < TypedCollection
      instances :definitions, DetailedDefinition

      private

      def coerce_other(item)
        case item
        when String then DetailedDefinition.new(content: item)
        else item
        end
      end
    end
  end
end
