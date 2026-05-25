# frozen_string_literal: true

module Glossarist
  module V2
    class Citation < Glossarist::Citation
      attribute :text, :string

      key_value do
        map :ref, to: :text, with: { from: :ref_from_yaml, to: :ref_to_yaml }
        map %i[clause locality],
            to: :locality,
            with: { from: :locality_from_yaml, to: :locality_to_yaml }
        map :link, to: :link
        map :original, to: :original
        map %i[custom_locality customLocality], to: :custom_locality
      end

      def label
        text
      end

      def ref_from_yaml(model, value)
        model.text = case value
                     when Hash
                       value["source"] || value[:source]
                     when String
                       value
                     end
      end

      def ref_to_yaml(model, doc)
        doc["ref"] = model.text if model.text
      end
    end
  end
end
