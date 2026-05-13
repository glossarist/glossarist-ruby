module Glossarist
  module Designation
    class Base < Lutaml::Model::Serializable
      attribute :designation, :string
      attribute :geographical_area, :string
      attribute :normative_status, :string,
                values: Glossarist::GlossaryDefinition::DESIGNATION_BASE_NORMATIVE_STATUSES
      attribute :type, :string
      attribute :language, :string
      attribute :script, :string
      attribute :system, :string
      attribute :international, :boolean
      attribute :absent, :boolean
      attribute :pronunciation, Pronunciation, collection: true

      key_value do
        map :type, to: :type
        map %i[normative_status normativeStatus], to: :normative_status
        map %i[geographical_area geographicalArea], to: :geographical_area
        map :designation, to: :designation
        map :language, to: :language
        map :script, to: :script
        map :system, to: :system
        map :international, to: :international
        map :absent, to: :absent
        map :pronunciation, to: :pronunciation
      end

      def self.of_yaml(hash, options = {})
        type = hash["type"]

        if type.nil? || /\w/ !~ type
          type = infer_designation_type(hash)
          hash["type"] = type
        end

        if self == Base
          SERIALIZED_TYPES[type].of_yaml(hash)
        else
          unless SERIALIZED_TYPES[self] == type
            raise ArgumentError, "unexpected designation type: #{type}"
          end

          super
        end
      end

      def self.infer_designation_type(hash)
        if hash["abbreviation_type"]
          "abbreviation"
        elsif hash["international"]
          "symbol"
        else
          "expression"
        end
      end
    end
  end
end
