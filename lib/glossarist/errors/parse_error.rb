# frozen_string_literal: true

module Glossarist
  module Errors
    class ParseError < Base
      attr_accessor :line, :filename, :message

      def initialize(filename:, line: nil, message: nil)
        @filename = filename
        @line = line
        @message = message

        super(to_s)
      end

      def to_s
        parts = ["Unable to parse file: #{filename}"]
        parts << "error on line: #{line}" if line
        parts << message if message
        parts.join(", ")
      end
    end
  end
end
