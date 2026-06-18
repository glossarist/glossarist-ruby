# frozen_string_literal: true

module Glossarist
  # Dataset-shared non-verbal entity — a NonVerbalEntity with a stable
  # identity. Figure, Table, and Formula inherit from this; NonVerbRep
  # (concept-local, positional) inherits from NonVerbalEntity directly.
  #
  # The +id+ is the stable identifier used for cross-referencing
  # (e.g. +figures/fig_A.23.yaml+ → +id: fig_A.23+). The +identifier+ is
  # the human-readable label (e.g. +"A.23"+) used for display and AsciiDoc
  # xref targets like +<<fig_A.23>>+.
  class SharedNonVerbalEntity < NonVerbalEntity
    attribute :id, :string
    attribute :identifier, :string

    key_value do
      map :id, to: :id
      map :identifier, to: :identifier
    end

    def find_by_id(target_id)
      id == target_id ? self : nil
    end

    def all_ids
      [id].compact
    end
  end
end
