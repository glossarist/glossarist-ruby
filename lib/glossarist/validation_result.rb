# frozen_string_literal: true

module Glossarist
  class ValidationResult
    attr_reader :errors, :warnings

    def initialize(errors: [], warnings: [])
      @errors = errors
      @warnings = warnings
    end

    def valid?
      @errors.empty?
    end

    def add_error(message)
      @errors << message
    end

    def add_warning(message)
      @warnings << message
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
