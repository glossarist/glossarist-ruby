# frozen_string_literal: true

module Glossarist
  module V3
    # Multiplicity — ISO 704:2022 partitive multiplicity (derived view).
    #
    # ISO 704:2022 multiplicity is the cross product of two orthogonal
    # dimensions (PartitivePresence × PartitiveCount). The 5 valid
    # combinations map to the 5 ISO 704 names:
    #
    #   required × exactly_one  → compulsory
    #   optional × exactly_one  → optional
    #   required × multiple     → compulsory_multiple
    #   optional × multiple     → optional_multiple
    #   required × at_least_one → compulsory_at_least_one
    #
    # (optional × at_least_one is REDUNDANT with optional × multiple —
    # "may exist, ≥1 if it does" = "may exist in any number" — and is
    # explicitly rejected at construction with a clear error message.)
    #
    # This module is the SSOT for the (presence, count) → ISO name
    # mapping. Both MULTIPLICITY constants and MULTIPLICITY_VALUES are
    # derived from this single table; no duplicate string literals.
    module Multiplicity
      NAME_BY_PAIR = {
        %w[required exactly_one] => "compulsory",
        %w[optional exactly_one] => "optional",
        %w[required multiple] => "compulsory_multiple",
        %w[optional multiple] => "optional_multiple",
        %w[required at_least_one] => "compulsory_at_least_one",
      }.freeze

      # Precomputed reverse map: ISO name → (presence, count) pair.
      # Avoids NAME_BY_PAIR.find for O(1) reverse lookup. Mirrors the
      # glossarist-js PAIR_BY_NAME so the JS and Ruby MECE derivation
      # stay in lockstep.
      PAIR_BY_NAME = NAME_BY_PAIR.each_with_object({}) do |(pair, name), h|
        h[name] = pair
      end.freeze

      MULTIPLICITY = NAME_BY_PAIR.values.to_h do |name|
        [name.upcase.to_sym, name]
      end.freeze

      MULTIPLICITY_VALUES = NAME_BY_PAIR.values.freeze
      DEFAULT_MULTIPLICITY = MULTIPLICITY[:COMPULSORY]

      def self.multiplicity_from_pair(presence, count)
        name = NAME_BY_PAIR[[presence, count]]
        raise invalid_combination_error(presence, count) if name.nil?

        name
      end

      def self.pair_from_multiplicity(name)
        pair = PAIR_BY_NAME[name]
        raise ArgumentError, "Unknown multiplicity: #{name.inspect}" if pair.nil?

        { presence: pair[0], count: pair[1] }
      end

      def self.valid_multiplicity?(name)
        PAIR_BY_NAME.key?(name)
      end

      def self.invalid_combination_error(presence, count)
        ArgumentError.new(
          "Invalid multiplicity combination: " \
          "presence=#{presence}, count=#{count}. " \
          "(optional + at_least_one collapses to " \
          "optional + multiple — use count=multiple.)",
        )
      end
    end
  end
end
