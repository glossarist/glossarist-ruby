# frozen_string_literal: true

module Glossarist
  class ComparisonResult < Lutaml::Model::Serializable
    attribute :new_count, :integer
    attribute :old_count, :integer
    attribute :matched, :string, collection: true, initialize_empty: true
    attribute :new_only, :string, collection: true, initialize_empty: true
    attribute :old_only, :string, collection: true, initialize_empty: true
    attribute :diffs, ConceptDiff, collection: true, initialize_empty: true

    key_value do
      map :new_count, to: :new_count
      map :old_count, to: :old_count
      map :matched, to: :matched
      map :new_only, to: :new_only
      map :old_only, to: :old_only
      map :diffs, to: :diffs
    end

    def summary
      diff = new_count - old_count
      change = if diff.positive?
                 "+#{diff} new"
               elsif diff.negative?
                 "#{diff.abs} removed"
               else
                 "no change"
               end
      "#{new_count} new, #{old_count} old (#{change}), " \
        "#{matched.length} matched, #{new_only.length} new-only, " \
        "#{old_only.length} old-only"
    end
  end
end
