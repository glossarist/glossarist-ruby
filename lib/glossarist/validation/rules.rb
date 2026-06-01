# frozen_string_literal: true

module Glossarist
  module Validation
    module Rules
      autoload :Base,           "glossarist/validation/rules/base"
      autoload :Registry,       "glossarist/validation/rules/registry"
      autoload :DatasetContext,  "glossarist/validation/rules/dataset_context"
      autoload :GcrContext,      "glossarist/validation/rules/gcr_context"
      autoload :ConceptContext,  "glossarist/validation/rules/concept_context"

      RULES_DIR = File.join(__dir__, "rules")

      # Eagerly load all rule files so they self-register via Base.inherited.
      # Adding a new rule file requires zero changes here — just drop it in.
      Dir.glob(File.join(RULES_DIR, "*_rule.rb")).each do |path|
        require path
      end
    end
  end
end
