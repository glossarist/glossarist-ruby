module Glossarist
  class CustomLocality < Lutaml::Model::Serializable
    # The name of the custom locality.
    # @return [String]
    attribute :name, :string

    # The value of the custom locality, which can be any string.
    # @return [String]
    attribute :value, :string

    yaml do
      map :name, to: :name
      map :value, to: :value
    end
  end
end
