# frozen_string_literal: true

module Glossarist
  module V1
    class CrossReferences < Lutaml::Model::Serializable
      attribute :ref_prefix_map, :hash, default: -> { {} }
      attribute :urn_standard_map, :hash, default: -> { {} }

      yaml do
        map :crossReferences, with: { from: :xref_from_yaml, to: :xref_to_yaml }
      end

      def self.from_file(path)
        return nil unless path && File.exist?(path)

        from_yaml(File.read(path))
      rescue Psych::SyntaxError, Lutaml::Model::InvalidFormatError
        nil
      end

      def xref_from_yaml(model, value)
        model.ref_prefix_map = value&.dig("refPrefixMap") || {}
        model.urn_standard_map = value&.dig("urnStandardMap") || {}
      end

      def xref_to_yaml(model, doc)
        doc["crossReferences"] = {
          "refPrefixMap" => model.ref_prefix_map,
          "urnStandardMap" => model.urn_standard_map,
        }
      end

      def to_ref_maps
        {
          ref_prefix_map: ref_prefix_map,
          urn_standard_map: urn_standard_map,
        }
      end
    end
  end
end
