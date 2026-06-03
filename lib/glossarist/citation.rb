# frozen_string_literal: true

module Glossarist
  class Citation < Lutaml::Model::Serializable
    class Ref < Lutaml::Model::Serializable
      attribute :source, :string
      attribute :id, :string
      attribute :version, :string

      key_value do
        map :source, to: :source
        map :id, to: :id
        map :version, to: :version
      end
    end

    attribute :ref, Ref
    attribute :locality, Locality
    attribute :link, :string
    attribute :original, :string
    attribute :custom_locality, CustomLocality, collection: true

    key_value do
      map :ref, to: :ref
      map %i[clause locality],
          to: :locality,
          with: { from: :locality_from_yaml, to: :locality_to_yaml }
      map :link, to: :link
      map :original, to: :original
      map %i[custom_locality customLocality], to: :custom_locality
    end

    def label
      parts = [ref&.source, ref&.id].compact
      parts.empty? ? nil : parts.join(" ")
    end

    def locality_from_yaml(model, value)
      locality = Locality.new

      if value.is_a?(Hash)
        locality.type = value["type"] || "clause"
        locality.reference_from = value["reference_from"] || value
        locality.reference_to = value["reference_to"] if value["reference_to"]
      else
        locality.type = "clause"
        locality.reference_from = value
      end
      locality.validate!

      model.locality = locality
    end

    def locality_to_yaml(model, doc)
      return unless model.locality

      doc["locality"] = {}
      doc["locality"]["type"] = model.locality.type
      if model.locality.reference_from
        doc["locality"]["reference_from"] =
          model.locality.reference_from
      end
      if model.locality.reference_to
        doc["locality"]["reference_to"] =
          model.locality.reference_to
      end
    end
  end
end
