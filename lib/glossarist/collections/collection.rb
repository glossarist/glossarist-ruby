# frozen_string_literal: true

module Glossarist
  module Collections
    class Collection
      include Enumerable

      attr_reader :collection

      alias :size :count

      def initialize(klass:)
        @klass = klass
        @collection = []
      end

      def <<(object)
        @collection << @klass.new(object)
      end

      def each(&block)
        @collection.each(&block)
      end

      def empty?
        @collection.empty?
      end

      def clear!
        @collection = []
      end
    end
  end
end
