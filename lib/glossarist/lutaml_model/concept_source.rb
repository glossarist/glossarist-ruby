module Glossarist
  module LutamlModel
    class ConceptSource < Lutaml::Model::Serializable
      attribute :status, :string, values: Glossarist::GlossaryDefinition::CONCEPT_SOURCE_STATUSES
      attribute :type, :string, values: Glossarist::GlossaryDefinition::CONCEPT_SOURCE_TYPES
      attribute :origin, Citation
      attribute :modification, :string

      yaml do
        map :origin, to: :origin
        map :status, to: :status
        map :type, to: :type
        map :modification, to: :modification
      end

      def initialize(attributes = {})
        origin_attrs = {}

        citation_attributes = if attributes.key?("origin") || attributes.key?(:origin)
                                attributes.delete("origin") || attributes.delete(:origin)
                              else
                                slice_keys(attributes, ref_param_names)
                              end

        origin_attrs["origin"] = Citation.of_yaml(citation_attributes) unless citation_attributes.empty?

        remaining_attributes = attributes.dup
        ref_param_names.each { |k| remaining_attributes.delete(k) }

        super(remaining_attributes.merge(origin_attrs))
      end

      def ref_param_names
        %w[
          ref
          text
          source
          id
          version
          clause
          link
          original
        ]
      end

      def slice_keys(hash, keys)
        result = {}
        keys.each do |key|
          result[key] = hash[key] if hash.key?(key)
        end
        result
      end
    end
  end
end
