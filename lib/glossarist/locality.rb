module Glossarist
  class Locality < Lutaml::Model::Serializable
    # @return [String]
    attribute :type, :string, pattern: %r{
      section|clause|part|paragraph|chapter|page|title|line|
      whole|table|annex|figure|note|list|example|volume|issue|time|anchor|
      locality:[a-zA-Z0-9_]+
    }x

    # @return [String]
    attribute :reference_from, :string

    # @return [String]
    attribute :reference_to, :string

    yaml do
      map :type, to: :type
      map :reference_from, to: :reference_from
      map :reference_to, to: :reference_to
    end
  end
end
