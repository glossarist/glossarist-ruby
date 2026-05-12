# frozen_string_literal: true

require "lutaml/model"

module Glossarist
  module Validation
    autoload :ValidationIssue,   "glossarist/validation/validation_issue"
    autoload :Rules,             "glossarist/validation/rules"
    autoload :BibliographyIndex, "glossarist/validation/bibliography_index"
    autoload :AssetIndex,        "glossarist/validation/asset_index"
  end
end
