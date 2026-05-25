# frozen_string_literal: true

module Glossarist
  module Validation
    class ValidationIssue < Lutaml::Model::Serializable
      attribute :severity, :string
      attribute :code, :string
      attribute :message, :string
      attribute :location, :string
      attribute :suggestion, :string

      key_value do
        map :severity, to: :severity
        map :code, to: :code
        map :message, to: :message
        map :location, to: :location
        map :suggestion, to: :suggestion
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
        parts << "#{location}: " if location
        parts << message
        parts << "(#{suggestion})" if suggestion
        parts.join(" ")
      end
    end
  end
end
