# frozen_string_literal: true

module Glossarist
  module Collections
    class DesignationCollection < Collection
      def initialize
        super(klass: Designation::Base)
      end

      def <<(object)
        @collection << @klass.from_h(object)
      end
    end
  end
end
