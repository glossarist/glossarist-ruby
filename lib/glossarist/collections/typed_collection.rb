# frozen_string_literal: true

module Glossarist
  module Collections
    class TypedCollection < Lutaml::Model::Collection
      def <<(item)
        push(coerce(item))
      end

      private

      def coerce(item)
        return item if item.is_a?(self.class.instance_type)

        case item
        when Hash then self.class.instance_type.new(item)
        else coerce_other(item)
        end
      end

      def coerce_other(item)
        item
      end
    end
  end
end
