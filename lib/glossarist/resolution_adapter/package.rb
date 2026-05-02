# frozen_string_literal: true

module Glossarist
  class ResolutionAdapter
    class Package < ResolutionAdapter
      attr_reader :uri_prefix, :local_adapter

      def initialize(concepts, uri_prefix:)
        super()
        @uri_prefix = uri_prefix
        @local_adapter = Local.new(concepts)
      end

      def resolve(reference)
        return nil unless reference.ref_type == "urn"
        return nil unless reference.source == uri_prefix

        @local_adapter.resolve_by_id(reference.concept_id)
      end
    end
  end
end
