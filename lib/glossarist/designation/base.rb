module Glossarist
  module Designation
    class Base < Lutaml::Model::Serializable
      attribute :designation, :string
      attribute :geographical_area, :string
      attribute :normative_status, :string,
                values: Glossarist::GlossaryDefinition::DESIGNATION_BASE_NORMATIVE_STATUSES
      attribute :type, :string

      yaml do
        map :type, to: :type
        map :normative_status, to: :normative_status
        map :geographical_area, to: :geographical_area
        map :designation, to: :designation
      end

      def self.of_yaml(hash, options = {})
        type = hash["type"]

        if type.nil? || /\w/ !~ type
          raise ArgumentError, "designation type is missing"
        end

        if self == Base
          # called on Base class, delegate it to proper subclass
          SERIALIZED_TYPES[type].of_yaml(hash)
        else
          # called on subclass, instantiate object
          unless SERIALIZED_TYPES[self] == type
            raise ArgumentError, "unexpected designation type: #{type}"
          end

          super(hash, options)
        end
      end
    end
  end
end
