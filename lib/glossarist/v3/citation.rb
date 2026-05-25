# frozen_string_literal: true

module Glossarist
  module V3
    class Citation < Glossarist::Citation
      key_value do
        map :ref, to: :ref, with: { from: :ref_from_yaml, to: :ref_to_yaml }
      end

      def ref_from_yaml(model, value)
        case value
        when Hash
          model.ref = Ref.new(value.transform_keys(&:to_sym))
        when String
          model.ref = Ref.new(source: value)
        end
      end

      def ref_to_yaml(model, doc)
        return unless model.ref

        attrs = {}
        attrs["source"] = model.ref.source if model.ref.source
        attrs["id"] = model.ref.id if model.ref.id
        attrs["version"] = model.ref.version if model.ref.version
        doc["ref"] = attrs.empty? ? nil : attrs
      end
    end
  end
end
