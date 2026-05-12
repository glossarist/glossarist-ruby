# frozen_string_literal: true

module Glossarist
  class ValidationResult
    attr_reader :issues

    def initialize(errors: [], warnings: [], issues: [])
      @issues = []
      errors.each { |e| add_error(e) }
      warnings.each { |w| add_warning(w) }
      issues.each { |i| add_issue(i) }
    end

    def valid?
      @issues.none?(&:error?)
    end

    def errors
      @issues.select(&:error?).map(&:message)
    end

    def warnings
      @issues.select(&:warning?).map(&:message)
    end

    def add_error(message)
      @issues << Validation::ValidationIssue.new(
        severity: "error", message: message,
      )
    end

    def add_warning(message)
      @issues << Validation::ValidationIssue.new(
        severity: "warning", message: message,
      )
    end

    def add_issue(issue)
      @issues << issue
    end

    def merge(other)
      other.issues.each { |i| @issues << i }
      self
    end

    def to_h
      {
        "valid" => valid?,
        "errors" => errors,
        "warnings" => warnings,
      }
    end
  end
end
