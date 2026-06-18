# frozen_string_literal: true

module Glossarist
  # A dataset-level table entity (ISO 10241-1 §6.5 — non-verbal representation).
  #
  # Tables are authored at `datasets/{ds}/tables/{table-id}.yaml` and shared
  # across concepts. The content is stored as structured data (rows/columns)
  # or as a markup string (HTML, Markdown, AsciiDoc). Caption, description,
  # and alt are localized for accessibility.
  class Table < SharedNonVerbalEntity
    attribute :content, :hash
    attribute :format, :string

    key_value do
      map :content, to: :content
      map :format, to: :format
    end
  end
end
