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
    # Referred locality of the document.
    attribute :locality, Locality

    # Link to document.
    # @return [String]
    attribute :link, :string

    # Original ref text before parsing.
    # @return [String]
    # @note This attribute is likely to be removed or reworked in future.
    #   It is arguably not relevant to Glossarist itself.
    attribute :original, :string

    attribute :ref, :string

    attribute :custom_locality, CustomLocality, collection: true

    yaml do
      map :id, to: :id, with: { from: :id_from_yaml, to: :id_to_yaml }
      map :text, to: :text, with: { from: :text_from_yaml, to: :text_to_yaml }
      map :source, to: :source,
                   with: { from: :source_from_yaml, to: :source_to_yaml }
      map :version, to: :version,
                    with: { from: :version_from_yaml, to: :version_to_yaml }
      map :ref, to: :ref, with: { from: :ref_from_yaml, to: :ref_to_yaml }
      map %i[clause locality],
          to: :locality,
          with: { from: :clause_from_yaml, to: :clause_to_yaml }
      map :link, to: :link
      map :original, to: :original
      map %i[custom_locality customLocality], to: :custom_locality
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

    def clause_from_yaml(model, value)
      # accepts old format like
      # clause: "11"
      # or new format like
      # locality: { type: "clause", reference_from: "11", reference_to: "12" }
      locality = Locality.new
      locality.type = value["type"] || "clause"
      locality.reference_from = value["reference_from"] || value
      locality.reference_to = value["reference_to"] if value["reference_to"]
      locality.validate!

      model.locality = locality
    end

    def clause_to_yaml(model, doc) # rubocop:disable Metrics/AbcSize
      if model.locality
        doc["locality"] = {}
        doc["locality"]["type"] = model.locality.type

        if model.locality.reference_from
          doc["locality"]["reference_from"] = model.locality.reference_from
        end

        if model.locality.reference_to
          doc["locality"]["reference_to"] = model.locality.reference_to
        end
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
