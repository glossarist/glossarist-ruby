module Glossarist
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
      map :id, to: :id, with: { from: :id_from_yaml, to: :id_to_yaml }
      map :text, to: :text, with: { from: :text_from_yaml, to: :text_to_yaml }
      map :source, to: :source,
                   with: { from: :source_from_yaml, to: :source_to_yaml }
      map :version, to: :version,
                    with: { from: :version_from_yaml, to: :version_to_yaml }
      map :ref, to: :ref, with: { from: :ref_from_yaml, to: :ref_to_yaml }

      map :clause, to: :clause
      map :link, to: :link
      map :original, to: :original
    end

    def ref_from_yaml(model, value)
      model.ref = value
    end

    def ref_to_yaml(model, doc)
      doc["ref"] = if model.structured?
                     ref_hash(model)
                   else
                     model.text
                   end
    end

    def id_from_yaml(model, value)
      model.id = value
    end

    def id_to_yaml(_model, _doc)
      # skip, will be handled in ref
    end

    def text_from_yaml(model, value)
      model.text = value
    end

    def text_to_yaml(_model, _doc)
      # skip, will be handled in ref
    end

    def source_from_yaml(model, value)
      model.source = value
    end

    def source_to_yaml(_model, _doc)
      # skip, will be handled in ref
    end

    def version_from_yaml(model, value)
      model.version = value
    end

    def version_to_yaml(_model, _doc)
      # skip, will be handled in ref
    end

    def ref_hash(model = self)
      {
        "source" => model.source,
        "id" => model.id,
        "version" => model.version,
      }.compact
    end

    def ref=(ref)
      if ref.is_a?(Hash)
        @source = ref["source"]
        @id = ref["id"]
        @version = ref["version"]
      else
        @text = ref
      end
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
