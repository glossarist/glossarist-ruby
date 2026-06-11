# frozen_string_literal: true

module Glossarist
  module Errors
    class LoadError < Base
      attr_accessor :path, :reason

      def initialize(path:, reason: nil)
        @path = path
        @reason = reason

        super(to_s)
      end

      def to_s
        parts = ["Unable to load: #{path}"]
        parts << reason if reason
        parts.join(" — ")
      end
    end
  end
end
