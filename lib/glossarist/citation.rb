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

    # Segments that begin the item path of an ISO URN (the "element"
    # segments of ISO 6701-style URNs); everything before the first of
    # these is the cited document's identity.
    URN_ELEMENT_SEGMENTS = %w[tech term doc fig tab sec loc rem].freeze

    attribute :ref, Ref
    attribute :text, :string
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

    def text
      @text || label
    end

    # The cited document's identity URN — the source URN minus its item
    # path. For "urn:iso:std:iso:10303:-2:ed-1:en:tech:ACTIVITY_MIM"
    # this is "urn:iso:std:iso:10303:-2:ed-1:en". Non-URN sources have
    # no document identity.
    def document_urn
      split_urn_source&.first || urn_source
    end

    # The item path inside the cited document — the URN's element
    # segments ("tech:ACTIVITY_MIM:tech:ACTIVITY_MIM"). Nil when the
    # source is not a URN or carries no element segments.
    def item_path
      split_urn_source&.last
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

    private

    def urn_source
      source = ref&.source
      source&.start_with?("urn:") ? source : nil
    end

    def split_urn_source
      source = urn_source
      return nil unless source

      segments = source.split(":")
      idx = segments.index { |s| URN_ELEMENT_SEGMENTS.include?(s) }
      return nil unless idx

      [segments[0...idx].join(":"), segments[idx..].join(":")]
    end
  end
end
