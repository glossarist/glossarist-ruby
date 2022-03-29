# frozen_string_literal: true

module Glossarist
  module Designation
    class GraphicalSymbol < Symbol
      attr_accessor :text
      attr_accessor :image

      def to_h
        super.merge(
          "text" => text,
          "image" => image,
        )
      end
    end
  end
end
