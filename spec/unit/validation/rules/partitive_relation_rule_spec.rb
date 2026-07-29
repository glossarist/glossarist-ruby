# frozen_string_literal: true

require "spec_helper"

# TODO: PartitiveRelationRule needs to be updated for per-file relation
# storage (see docs/design/relations-as-files.md in concept-model repo).
# The rule currently validates bundled `partitive_relations` arrays on
# ManagedConcept — that wire format is removed. Pending until rewrite.
RSpec.describe Glossarist::Validation::Rules::PartitiveRelationRule do
  pending "rewrite for per-file relation storage (TODO.general-rels/05)" do
    skip "rule needs rewrite for per-file relations"
  end
end
