# frozen_string_literal: true

module Glossarist
  # Namespace for standalone validators (not Validation::Rule classes).
  # These are opt-in utilities that consumers call explicitly — they
  # are not auto-registered into the Validation::Rules pipeline.
  module Validators
    autoload :NoRawHtml, "glossarist/validators/no_raw_html"
  end
end
