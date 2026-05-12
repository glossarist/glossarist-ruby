# frozen_string_literal: true

module Glossarist
  module Validation
    module Rules
      class Base
        def code
          nil
        end

        def category
          :general
        end

        def severity
          "error"
        end

        def scope
          :concept
        end

        def applicable?(_context)
          true
        end

        def check(_context)
          []
        end

        private

        def issue(message, location: nil, suggestion: nil, severity: nil,
code: nil)
          ValidationIssue.new(
            severity: severity || self.severity,
            code: code || self.code,
            message: message,
            location: location,
            suggestion: suggestion,
          )
        end
      end
    end
  end
end
