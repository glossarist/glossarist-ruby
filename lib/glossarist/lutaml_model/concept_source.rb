
module Glossarist
  module Model
    class Concept < Lutaml::Model::Serializable
      attribute :status, :string
      attribute :type, :string
      attribute :origin, Citation
      attribute :modification, :string

      yaml do
        map
      end
    end
  end
end
