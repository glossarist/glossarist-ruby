module Glossarist
  module LutamlModel
    class Symbol < Lutaml::Model::Serializable
      attribute :international, :string
      attribute :base, Base
      attribute :type, :string, values: Glossarist::Designation::SERIALIZED_TYPES[self.class]

      yaml do
        map :international, to: :international
        map :base, to: :base
        map :type, to: :type
      end
    end
  end
end
