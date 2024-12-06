module Glossarist
  module LutamlModel
    class Citation < Lutaml::Model::Serializable
      # Unstructured (plain text) reference.
      # @return [String]
      attribute :text, :string

      # Source in structured reference.
      # @return [String]
      attribute :source, :string

      # Document ID in structured reference.
      # @return [String]
      attribute :id, :string

      # Document version in structured reference.
      # @return [String]
      attribute :version, :string

      # @return [String]
      # Referred clause of the document.
      attribute :clause, :string

      # Link to document.
      # @return [String]
      attribute :link, :string

      # Original ref text before parsing.
      # @return [String]
      # @note This attribute is likely to be removed or reworked in future.
      #   It is arguably not relevant to Glossarist itself.
      attribute :original, :string

      attribute :ref, :string

      yaml do
        map :text, to: :text
        map :clause, to: :clause
        map :link, to: :link
        map :original, to: :original

        map :id, to: :id, with: { from: :id_from_hash, to: :id_to_hash }
        map :source, to: :source, with: { from: :source_from_hash, to: :source_to_hash }
        map :version, to: :version, with: { from: :version_from_hash, to: :version_to_hash }
        map :ref, to: :ref, with: { from: :ref_from_hash, to: :ref_to_hash }
      end

      def ref_from_hash(model, value)
        if value.is_a?(Hash)
          model.source = value["source"]
          model.id = value["id"]
          model.version = value["version"]
          model.ref = ref_hash(model)
        else
          model.text = value
          model.ref = value
        end
      end

      def ref_to_hash(model, doc)
        doc["ref"] = if model.structured?
                       ref_hash(model)
                     else
                       model.text
                     end
      end

      def id_from_hash(_model, _value)
        # skip, will be handled in ref
      end

      def id_to_hash(_model, _doc)
        # skip, will be handled in ref
      end

      def source_from_hash(_model, _value)
        # skip, will be handled in ref
      end

      def source_to_hash(_model, _doc)
        # skip, will be handled in ref
      end

      def version_from_hash(_model, _value)
        # skip, will be handled in ref
      end

      def version_to_hash(_model, _doc)
        # skip, will be handled in ref
      end


      def ref_hash(model)
        {
          "source" => model.source,
          "id" => model.id,
          "version" => model.version
        }.compact
      end

      def plain?
        (source && id && version).nil?
      end

      # Whether it is a structured ref.
      # @return [Boolean]
      def structured?
        !plain?
      end
    end
  end
end
