# frozen_string_literal: true

module Glossarist
  module Validation
    class ValidationIssue
      attr_reader :severity, :code, :message, :location, :suggestion

      def initialize(severity:, message:, code: nil, location: nil,
suggestion: nil)
        @severity = severity
        @code = code
        @message = message
        @location = location
        @suggestion = suggestion
      end

      def error?
        severity == "error"
      end

      def warning?
        severity == "warning"
      end

      def info?
        severity == "info"
      end

      def to_s
        parts = ["[#{severity.upcase}]"]
        parts << "[#{code}]" if code
        parts << (location ? "#{location}: " : "")
        parts << message
        parts << " (#{suggestion})" if suggestion
        parts.join(" ")
      end
    end
  end
end
