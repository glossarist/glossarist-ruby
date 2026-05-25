# frozen_string_literal: true

module Glossarist
  class ValidationResult < Lutaml::Model::Serializable
    attribute :issues, Validation::ValidationIssue, collection: true,
                                                    initialize_empty: true

    key_value do
      map :issues, to: :issues
    end

    def valid?
      issues.none?(&:error?)
    end

    def errors
      issues.select(&:error?).map(&:to_s)
    end

    def warnings
      issues.select(&:warning?).map(&:to_s)
    end

    def add_error(message)
      issues << Validation::ValidationIssue.new(
        severity: "error", message: message,
      )
    end

    def add_warning(message)
      issues << Validation::ValidationIssue.new(
        severity: "warning", message: message,
      )
    end

    def add_issue(issue)
      issues << issue
    end

    def merge(other)
      other.issues.each { |i| issues << i }
      self
    end
  end
end
